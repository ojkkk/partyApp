import { Policy, PolicyService, PolicyComment } from "../models/PolicyModel";
import { ApiResponse, UserInfo } from "../models/UserModel";
import { StorageService } from '../services/StorageService';
import router from "@ohos.router";
import promptAction from "@ohos.promptAction";
import { AvatarComponent } from '../components/AvatarComponent';


class RouterParams {
  policyId: string;

  constructor(policyId: string) {
    this.policyId = policyId;
  }
}

@Entry
@Component
struct PolicyDetailPage {
  private policyService: PolicyService = new PolicyService();
  @State policy: Policy | null = null;
  private policyId: string = "";
  @State isLoading: boolean = false;
  @State user: UserInfo | null = null;
  @State isFavorite: boolean = false;
  @State scrollOffset: number = 0;
  @State comments: PolicyComment[] = [];
  @State commentContent: string = "";

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params["policyId"]) {
      this.policyId = params["policyId"];
      await this.loadPolicyDetail();
    }
  }

  canManage(): boolean {
    return this.user?.role === 'admin' || this.user?.role === 'branch_admin';
  }

  async loadPolicyDetail() {
    this.isLoading = true;
    try {
      const response: ApiResponse<Policy> = await this.policyService.getPolicyDetail(this.policyId);
      if (response.code === 200 && response.data) {
        this.policy = response.data;
        await this.loadComments();
        // 检查当前政策是否在收藏列表中
        const favoritesResponse = await this.policyService.getFavorites();
        if (favoritesResponse.code === 200 && favoritesResponse.data) {
          this.isFavorite = favoritesResponse.data.some(policy => policy.id === this.policyId);
        }
      }
    } catch (error) {
      console.error("加载政策详情失败:", error);
      promptAction.showToast({
        message: "加载失败",
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async loadComments() {
    try {
      const response: ApiResponse<PolicyComment[]> = await this.policyService.getComments(this.policyId);
      if (response.code === 200 && response.data) {
        console.log('评论数据:', response.data);
        // 检查每个评论是否有userAvatar字段
        response.data.forEach((comment, index) => {
          console.log(`评论${index}的userAvatar:`, comment.userAvatar);
        });
        this.comments = response.data;
      }
    } catch (error) {
      console.error("加载评论失败:", error);
    }
  }

  async addComment() {
    if (!this.commentContent.trim()) {
      promptAction.showToast({
        message: "请输入评论内容",
        duration: 2000
      });
      return;
    }

    try {
      const response: ApiResponse<PolicyComment> = await this.policyService.addComment(this.policyId, this.commentContent);
      if (response.code === 200 && response.data) {
        this.comments.unshift(response.data);
        this.commentContent = "";
        promptAction.showToast({
          message: "评论成功",
          duration: 2000
        });
      }
    } catch (error) {
      console.error("添加评论失败:", error);
      promptAction.showToast({
        message: "评论失败",
        duration: 2000
      });
    }
  }

  async toggleFavorite() {
    try {
      const response = await this.policyService.toggleFavorite(this.policyId);
      if (response.code === 200) {
        this.isFavorite = response.data || false;
        promptAction.showToast({
          message: this.isFavorite ? "已收藏" : "已取消收藏",
          duration: 2000
        });
      }
    } catch (error) {
      console.error("收藏失败:", error);
      promptAction.showToast({
        message: "操作失败",
        duration: 2000
      });
    }
  }

  async deletePolicy() {
    try {
      const response = await this.policyService.deletePolicy(this.policyId);
      if (response.code === 200) {
        promptAction.showToast({
          message: '删除成功',
          duration: 2000
        });
        router.back();
      } else {
        promptAction.showToast({
          message: response.message || '删除失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('删除失败:', error);
      promptAction.showToast({
        message: '删除失败',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.policy) {
        Column() {
          Text("加载失败")
            .fontSize(16)
            .fontColor("#666666")
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          Image($rawfile('返回.png'))
            .width(24)
            .height(24)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              router.back();
            })
          Text("政策详情")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          if (this.canManage()) {
            Button('编辑')
              .fontSize(14)
              .height(32)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#D32F2F')
              .margin({ right: 8 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/PolicyEditPage',
                  params: { policyId: this.policyId }
                });
              })
            Button('删除')
              .fontSize(14)
              .height(32)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#FF3B30')
              .onClick(() => {
                this.deletePolicy();
              })
          }
        }
        .width("100%")
        .height(56)
        .alignItems(VerticalAlign.Center)
        .backgroundColor("#FFFFFF")
        .borderWidth({ bottom: 1 })
        .borderColor({ bottom: "#EEEEEE" })

        Scroll() {
          Column() {
            Image(this.policy.imageUrl)
              .width("100%")
              .height(280)
              .objectFit(ImageFit.Cover)

            Column() {
              Text(this.policy.title)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 24, left: 16, right: 16, bottom: 16 })
                .lineHeight(32)

              Row() {
                Text(this.policy.type)
                  .fontSize(11)
                  .fontColor('#FFFFFF')
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                  .borderRadius(4)
                  .backgroundColor('#D32F2F')
                  .margin({ right: 10 })
                Text(this.policy.publishDate)
                  .fontSize(13)
                  .fontColor("#999999")
                Blank()
                
              }
              .width('100%')
              .margin({ left: 24, right: 16, bottom: 20 })

              Divider()
                .color('#F0F0F0')
                .margin({ left: 16, right: 16, bottom: 20 })

              Text(this.policy.content)
                .fontSize(17)
                .lineHeight(30)
                .margin({ left: 16, right: 16, bottom: 32 })
                .fontColor('#222222')

              if (this.policy.videoUrl) {
                Column() {
                  Text('相关视频')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .width('100%')
                    .margin({ bottom: 12 })
                  Video({
                    src: this.policy.videoUrl,
                    currentProgressRate: 1.0,
                    previewUri: this.policy.imageUrl
                  })
                    .width('100%')
                    .height(220)
                    .objectFit(ImageFit.Cover)
                    .controls(true)
                    .autoPlay(false)
                    .muted(false)
                    .borderRadius(12)
                }
                .width('100%')
                .margin({ left: 16, right: 16, bottom: 40 })
              }

              Column() {
                Text('声明：本文内容仅供学习参考，不构成任何建议。')
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#F8F8F8')
              .borderRadius(8)
              .margin({ left: 16, right: 16, bottom: 20 })

              // 评论部分
              Column() {
                Text('评论')
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
                  .margin({ bottom: 16 })

                if (this.comments.length === 0) {
                  Text('暂无评论')
                    .fontSize(14)
                    .fontColor('#999999')
                    .margin({ bottom: 16 })
                } else {
                  ForEach(this.comments, (comment: PolicyComment) => {
                    Column() {
                      Row() {
                        AvatarComponent({
                          user: {
                            avatar: comment.userAvatar || '',
                            name: comment.userName
                          },
                          avatarSize: 36
                        })
                          .margin({ right: 12 })
                        Column() {
                          Row() {
                            Text(comment.userName)
                              .fontSize(14)
                              .fontWeight(500)
                            Text(comment.userBranch)
                              .fontSize(12)
                              .fontColor('#999999')
                              .margin({ left: 8 })
                          }
                          .margin({ bottom: 4 })
                          Text(comment.content)
                            .fontSize(14)
                            .lineHeight(20)
                            .fontColor('#333333')
                          Text(comment.createdAt.replace('T', ' '))
                            .fontSize(12)
                            .fontColor('#999999')
                            .margin({ top: 4 })
                        }
                        .layoutWeight(1)
                      }
                      .width('100%')
                      .margin({ bottom: 16 })
                      Divider()
                        .color('#F0F0F0')
                        .margin({ bottom: 16 })
                    }
                    .width('100%')
                  })
                }


              }
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 40 })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius({ topLeft: 20, topRight: 20 })
            .margin({ top: -20 })
          }
        }
        .layoutWeight(1)
        .backgroundColor("#F2F2F2")
        .edgeEffect(EdgeEffect.Spring)

          Row() {
            TextInput({
              text: this.commentContent,
              placeholder: '写下你的评论...'
            })
            .layoutWeight(1)
            .height(36)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#F5F5F5')
            .borderRadius(18)
            .margin({ right: 16 })
            .onChange((value: string) => {
              this.commentContent = value;
            })
            .onSubmit(() => {
              this.addComment();
            })

            Column() {
              Image(this.isFavorite ? $rawfile('已收藏.png') : $rawfile('未收藏.png'))
                .width(22)
                .height(22)
                .margin({bottom:1})
              Text(this.isFavorite ? '已收藏' : '收藏')
                .fontSize(11)
                .fontColor(this.isFavorite ? '#D32F2F' : '#666666')
                .margin({ top: 2 })
            }
            .width(50) // 【关键修改】固定宽度，防止抖动
            .justifyContent(FlexAlign.Center) // 内容居中
            .onClick(() => {
              this.toggleFavorite();
            })

            Column() {
              Image($rawfile('分享(政策).png'))
                .width(22)
                .height(22)
                .margin({bottom:1})
              Text('分享')
                .fontSize(11)
                .fontColor('#666666')
                .margin({ top: 2 })
            }
            .width(50) // 【关键修改】固定宽度
            .justifyContent(FlexAlign.Center) // 内容居中

          }
          .width("100%")
          .height(60)
          .padding({ left: 16, right: 16 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .backgroundColor("#FFFFFF")
          .borderWidth({ top: 1 })
          .borderColor({ top: "#EAEAEA" })
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: -2 })
      }
    }
    .width("100%")
    .height("100%")
  }
}
