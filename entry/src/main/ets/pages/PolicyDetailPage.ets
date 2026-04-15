import { Policy, PolicyService, PolicyComment } from "../models/PolicyModel";
import { ApiResponse, UserInfo } from "../models/UserModel";
import { StorageService } from '../services/StorageService';
import router from "@ohos.router";
import promptAction from "@ohos.promptAction";
import { emitter } from '@kit.BasicServicesKit';
import { AvatarComponent } from '../components/AvatarComponent';


// 删除确认对话框
@CustomDialog
struct ConfirmDeleteDialog {
  controller: CustomDialogController;
  title: string = '确认删除';
  message: string = '确定要删除该项吗？此操作不可撤销。';
  onConfirm?: () => void;

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F1F1F')
        .margin({ bottom: 12 });

      Text(this.message)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 24 });

      Row() {
        Button('取消')
          .width(100)
          .height(40)
          .fontSize(15)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
          });

        Button('确定删除')
          .width(100)
          .height(40)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor('#B51F2E')
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
            if (this.onConfirm) {
              this.onConfirm();
            }
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 设计规范（庄重红金正式风）
//  主色        #B51F2E  绛红
//  强调色      #D83A34  亮红
//  金色        #C9A45C  暖金
//  深金        #A67C2E  深金
//  背景        #F7F4EF  米白底
//  卡片背景    #FFFFFF  纯白
//  文字主色    #1F1F1F  深灰黑
//  文字副色    #666666  中灰
//  文字弱色    #999999  浅灰
//  分割线      #EFE7DB  暖灰金
// ─────────────────────────────────────────────────────────────────────────────

// 内容段类型（图文混排）
interface ContentSegment {
  type: 'text' | 'image';
  value: string;
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
  @State comments: PolicyComment[] = [];
  @State commentContent: string = "";
  @State contentSegments: ContentSegment[] = [];

  // 删除确认对话框控制器
  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDeleteDialog({
      onConfirm: () => {}
    }),
    isModal: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

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
        this.contentSegments = this.parseContent(this.policy.content);
        await this.loadComments();
        const favoritesResponse = await this.policyService.getFavorites();
        if (favoritesResponse.code === 200 && favoritesResponse.data) {
          this.isFavorite = favoritesResponse.data.some(policy => policy.id === this.policyId);
        }
      }
    } catch (error) {
      console.error("加载政策详情失败:", error);
      promptAction.showToast({ message: "加载失败", duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  // 解析图文混排内容
  parseContent(raw: string): ContentSegment[] {
    const segments: ContentSegment[] = [];
    const imgRegex = /\[IMG:(.*?)\]/g;
    let lastIndex = 0;
    let match: RegExpExecArray | null = imgRegex.exec(raw);
    while (match !== null) {
      if (match.index > lastIndex) {
        const textPart = raw.substring(lastIndex, match.index);
        if (textPart.length > 0) {
          // 段首半角空格换全角，保留缩进格式
          const formatted = textPart.replace(/^(\s+)/, (_: string, spaces: string): string =>
            spaces.replace(/ /g, '\u3000'));
          segments.push({ type: 'text', value: formatted });
        }
      }
      segments.push({ type: 'image', value: match[1] });
      lastIndex = match.index + match[0].length;
      match = imgRegex.exec(raw);
    }
    if (lastIndex < raw.length) {
      const tail = raw.substring(lastIndex);
      if (tail.length > 0) {
        segments.push({ type: 'text', value: tail });
      }
    }
    return segments;
  }

  async loadComments() {
    try {
      const response: ApiResponse<PolicyComment[]> = await this.policyService.getComments(this.policyId);
      if (response.code === 200 && response.data) {
        this.comments = response.data;
      }
    } catch (error) {
      console.error("加载评论失败:", error);
    }
  }

  async addComment() {
    const content = this.commentContent.trim();
    if (!content) {
      promptAction.showToast({ message: "请输入评论内容", duration: 2000 });
      return;
    }

    try {
      const response: ApiResponse<PolicyComment> = await this.policyService.addComment(this.policyId, content);
      if (response.code === 200 && response.data) {
        this.comments.unshift(response.data);
        this.commentContent = "";
        promptAction.showToast({ message: "评论成功", duration: 2000 });
      }
    } catch (error) {
      console.error("添加评论失败:", error);
      promptAction.showToast({ message: "评论失败", duration: 2000 });
    }
  }

  async toggleFavorite() {
    try {
      const response = await this.policyService.toggleFavorite(this.policyId);
      if (response.code === 200) {
        this.isFavorite = response.data || false;
        promptAction.showToast({ message: this.isFavorite ? "已收藏" : "已取消收藏", duration: 2000 });
      }
    } catch (error) {
      console.error("收藏失败:", error);
      promptAction.showToast({ message: "操作失败", duration: 2000 });
    }
  }

  async deletePolicy() {
    try {
      const response = await this.policyService.deletePolicy(this.policyId);
      if (response.code === 200) {
        promptAction.showToast({ message: '删除成功', duration: 2000 });
        emitter.emit("refreshPolicies", null);
        router.back();
      } else {
        promptAction.showToast({ message: response.message || '删除失败', duration: 2000 });
      }
    } catch (error) {
      console.error('删除失败:', error);
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      if (this.isLoading) {
        this.buildLoadingState();
      } else if (!this.policy) {
        this.buildErrorState();
      } else {
        this.buildContent();
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor('#F7F4EF');
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#B51F2E');
      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 });
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildErrorState() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(100)
          .height(100)
          .borderRadius(50)
          .backgroundColor('#FFF1F1');
        Text('!')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor('#B51F2E');
      }
      .margin({ bottom: 16 });

      Text("加载失败")
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
        .margin({ bottom: 8 });

      Text("请检查网络后重试")
        .fontSize(13)
        .fontColor('#999999')
        .margin({ bottom: 24 });

      Button('重新加载')
        .width(140)
        .height(44)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor('#B51F2E')
        .borderRadius(22)
        .onClick(() => this.loadPolicyDetail());
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildContent() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.buildHeader();

        Scroll() {
          Column() {
            // 封面大图区域
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(this.policy!.imageUrl)
                .width("100%")
                .height(260)
                .objectFit(ImageFit.Contain);

              // 渐变遮罩
              Column()
                .width('100%')
                .height(260)
                .linearGradient({
                  angle: 180,
                  colors: [['#00000000', 0.0], ['#00000020', 0.5], ['#00000050', 1.0]]
                });

              // 类型标签
              Row() {
                Text(this.policy!.type)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor('#B51F2E')
                  .borderRadius({ topRight: 12, bottomLeft: 12 });
              }
              .width('100%')
              .padding({ left: 16, bottom: 16 });
            }
            .width('100%')
            .height(260);

            // 内容卡片
            Column() {
              // 标题区
              Column() {
                Row() {
                  Column()
                    .width(4)
                    .height(28)
                    .borderRadius(2)
                    .linearGradient({
                      angle: 180,
                      colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
                    })
                    .margin({ right: 12 });

                  Text(this.policy!.title)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1F1F1F')
                    .lineHeight(30)
                    .layoutWeight(1);
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .margin({ bottom: 16 });

                // 元信息行：发布时间 + 发布人 + 阅读量
                Row() {
                  this.InfoTag($rawfile('时间.png'), this.policy!.publishDate);

                  if (this.policy!.publisher) {
                    this.InfoTag($rawfile('发布人.png'), this.policy!.publisher);
                  }

                  this.InfoTag($rawfile('阅读量.png'),
                    this.policy!.viewCount !== undefined && this.policy!.viewCount > 0
                      ? `${this.policy!.viewCount}次阅读`
                      : '暂无阅读');
                }
                .width('100%');

                // 操作按钮行（独立一行，右对齐）


              }
              .width('100%')
              .padding({ bottom: 16 });

              // 摘要区
              if (this.policy!.summary) {
                Column() {
                  Row() {
                    Image($rawfile('摘要.png'))
                      .width(13)
                      .height(13)
                      .margin({ right: 6 });
                    Text('摘要')
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#A67C2E');
                    Blank();
                  }
                  .width('100%')
                  .margin({ bottom: 8 });

                  Text(this.policy!.summary!)
                    .fontSize(13)
                    .lineHeight(22)
                    .fontColor('#666666')
                    .width('100%');
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#F7F4EF')
                .borderRadius(10)
                .margin({ bottom: 12 });
              }

              // 标签区
              if (this.policy!.tags) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.policy!.tags!.split(','), (tag: string) => {
                    Text(tag.trim())
                      .fontSize(12)
                      .fontColor('#B51F2E')
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .backgroundColor('#FFF0F0')
                      .borderRadius(4)
                      .border({ width: 1, color: '#E8C4C4' })
                      .margin({ right: 6, bottom: 6 });
                  });
                }
                .width('100%')
                .margin({ bottom: 16 });
              }

              Divider()
                .color('#F0EBE3')
                .margin({ bottom: 20 });

              // 正文内容（图文混排）
              Column() {


                ForEach(this.contentSegments, (seg: ContentSegment, idx: number): void => {
if (seg.type === 'image') {
                    Image(seg.value)
                      .width('100%')
                      .objectFit(ImageFit.Contain)
                      .borderRadius(10)
                      .margin({ bottom: 14 });
                  } else {
                    Text(seg.value)
                      .fontSize(15)
                      .lineHeight(26)
                      .fontColor('#333333')
                      .width('100%')
                      .margin({ bottom: 14 });
                  }
                });
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFCF8')
              .borderRadius(12)
              .border({ width: 1, color: '#F3EBDD' })
              .margin({ bottom: 20 });

              // 视频
              if (this.policy!.videoUrl) {
                Column() {
                  Row() {
                    Row() {
                      Row()
                        .width(4)
                        .height(16)
                        .borderRadius(2)
                        .backgroundColor('#C9A45C')
                        .margin({ right: 8 });

                      Text('相关视频')
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#1F1F1F');
                    }
                    .layoutWeight(1);

                    Row() {
                      Image($rawfile('视频.png'))
                        .width(16)
                        .height(16)
                        .margin({ right: 4 });

                    }
                  }
                  .width('100%')
                  .margin({ bottom: 12 });

                  Video({
                    src: this.policy!.videoUrl,
                    previewUri: this.policy!.imageUrl
                  })
                    .width('100%')
                    .height(200)
                    .objectFit(ImageFit.Cover)
                    .controls(true)
                    .autoPlay(false)
                    .borderRadius(12);
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .border({ width: 1, color: '#EFE7DB' })
                .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
                .margin({ bottom: 20 });
              }

              // 免责声明
              Column() {
                Row() {
                  Image($rawfile('统计.png'))
                    .width(14)
                    .height(14)
                    .margin({ right: 6 });

                  Text('声明：本文内容仅供学习参考，不构成任何建议。')
                    .fontSize(12)
                    .fontColor('#999999');
                }
                .width('100%')
                .justifyContent(FlexAlign.Center);
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#F7F4EF')
              .borderRadius(8)
              .margin({ bottom: 24 });

              // 评论区域
              this.buildCommentsSection();

              // 底部留白
              Row().height(100);
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius({ topLeft: 20, topRight: 20 })
            .margin({ top: -20 });
          }
          .width('100%');
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }
      .width('100%')
      .height('100%');

      // 底部操作栏
      this.buildBottomBar();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  InfoTag(icon: Resource, text: string) {
    Row() {
      Image(icon)
        .width(14)
        .height(14)
        .margin({ right: 6 });

      Text(text)
        .fontSize(13)
        .fontColor('#666666');
    }
    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
    .backgroundColor('#F7F4EF')
    .borderRadius(8);
  }

  @Builder
  buildHeader() {
    Stack({ alignContent: Alignment.Bottom }) {
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#B51F2E', 0], ['#D83A34', 1]]
        });

      // 顶部导航栏 - 返回按钮与标题同行且对齐
      Row() {
        Button() {
          Text('‹')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF');
        }
        .width(48)
        .height(48)
        .margin({bottom:6})
        .backgroundColor(Color.Transparent)
        .onClick(() => {
              emitter.emit("refreshPolicies", null);
              router.back();
            });

        Text('详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 48 });
      }
      .width('100%')
      .height(56)
      .padding({ top: 8 });

      Row()
        .width('100%')
        .height(1)
        .backgroundColor('rgba(201, 164, 92, 0.4)');
    }
    .width('100%')
    .height(56);
  }

  @Builder
  buildCommentsSection() {
    Column() {
      Row() {
        Row() {
          Row()
            .width(4)
            .height(16)
            .borderRadius(2)
            .backgroundColor('#B51F2E')
            .margin({ right: 8 });

          Text('评论互动')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F');
        }
        .layoutWeight(1);

        Text(`${this.comments.length} 条评论`)
          .fontSize(13)
          .fontColor('#999999');
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 });

      if (this.comments.length === 0) {
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(80)
              .height(80)
              .borderRadius(40)
              .backgroundColor('#F7F4EF');

            Image($rawfile('评论.png'))
              .width(36)
              .height(36);
          }
          .margin({ bottom: 12 });

          Text('暂无评论')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
            .margin({ bottom: 6 });

          Text('成为第一个评论的人吧')
            .fontSize(13)
            .fontColor('#999999');
        }
        .width('100%')
        .padding({ top: 32, bottom: 32 });
      } else {
        Column() {
          ForEach(this.comments, (comment: PolicyComment, index: number) => {
            this.CommentItem(comment);

            if (index < this.comments.length - 1) {
              Divider()
                .color('#F0EBE3')
                .margin({ left: 52, top: 12, bottom: 12 });
            }
          });
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFCF8')
        .borderRadius(12)
        .border({ width: 1, color: '#F3EBDD' });
      }
    }
    .width('100%');
  }

  @Builder
  CommentItem(comment: PolicyComment) {
    Row() {
      AvatarComponent({
        user: {
          avatar: comment.userAvatar || '',
          name: comment.userName
        },
        avatarSize: 40
      });

      Column() {
        Row() {
          Text(comment.userName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F1F1F');

          if (comment.userBranch) {
            Text(comment.userBranch)
              .fontSize(11)
              .fontColor('#999999')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#F7F4EF')
              .borderRadius(4)
              .margin({ left: 8 });
          }

          Blank();

          Text(comment.createdAt.replace('T', ' ').substring(0, 16))
            .fontSize(11)
            .fontColor('#BBBBBB');
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 8 });

        Text(comment.content)
          .fontSize(14)
          .lineHeight(22)
          .fontColor('#444444')
          .width('100%');
      }
      .layoutWeight(1)
      .margin({ left: 12 });
    }
    .width('100%')
    .alignItems(VerticalAlign.Top);
  }

  @Builder
  buildBottomBar() {
    Row() {
      // 评论输入 - 使用 onSubmit 在输入法点击完成时发送
      Row() {
        Image($rawfile('评论.png'))
          .width(18)
          .height(18)
          .margin({ right: 8 });

        TextInput({
          text: $$this.commentContent,
          placeholder: '写下你的评论...'
        })
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .backgroundColor('transparent')
          .enterKeyType(EnterKeyType.Send)
          .onSubmit(() => {
            this.addComment();
          });
      }
      .layoutWeight(1)
      .height(48)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#F7F4EF')
      .borderRadius(24)
      .margin({ right: 12 });

      // 收藏按钮
      Column() {
        Image(this.isFavorite ? $rawfile('已收藏.png') : $rawfile('未收藏.png'))
          .width(24)
          .height(24)
          .margin({ bottom: 2 });

        Text(this.isFavorite ? '已收藏' : '收藏')
          .fontSize(11)
          .fontColor(this.isFavorite ? '#C9A45C' : '#666666');
      }
      .width(48)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.toggleFavorite());
    }
    .width("100%")
    .height(72)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderWidth({ top: 1 })
    .borderColor({ top: '#F0EBE3' })
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: -2 });
  }
}
