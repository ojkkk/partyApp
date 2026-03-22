import { Policy, PolicyService } from '../models/PolicyModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct PolicyPage {
  @State selectedTab: string = '新闻动态';
  private tabs = ['新闻动态', '政策法规', '重要讲话', '先进典型'];
  private policyService: PolicyService = new PolicyService();
  @State policies: Policy[] = [];
  @State isLoading: boolean = false;
  @State user: UserInfo | null = null;

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadPolicies();
  }

  canManage(): boolean {
    return this.user?.role === 'admin' || this.user?.role === 'branch_admin';
  }


  async loadPolicies() {
    this.isLoading = true;
    try {
      const response = await this.policyService.getPolicies(this.selectedTab);
      if (response.code === 200 && response.data) {
        this.policies = response.data;
      }
    } catch (error) {
      console.error('加载政策失败:', error);
      promptAction.showToast({
        message: '加载政策失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async toggleFavorite(id: string) {
    try {
      const response = await this.policyService.toggleFavorite(id);
      if (response.code === 200) {
        promptAction.showToast({
          message: response.data ? '已收藏' : '已取消收藏',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('收藏失败:', error);
      promptAction.showToast({
        message: '操作失败',
        duration: 2000
      });
    }
  }

  async deletePolicy(id: string) {
    try {
      const response = await this.policyService.deletePolicy(id);
      if (response.code === 200) {
        promptAction.showToast({
          message: '删除成功',
          duration: 2000
        });
        await this.loadPolicies();
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
      Row() {
        Text('政策宣传')
          .fontSize(22)
          .fontWeight(700)
        Blank()
        Button('我的收藏')
          .fontSize(14)
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#D32F2F')
          .margin({ right: 8 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/PolicyFavoritePage'
            });
          })
        if (this.canManage()) {
          Button('新建')
            .fontSize(14)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#D32F2F')
            .onClick(() => {
              router.pushUrl({
                url: 'pages/PolicyEditPage'
              });
            })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Row() {
          ForEach(this.tabs, (tab: string) => {
            Text(tab)
              .fontSize(16)
              .fontColor(this.selectedTab === tab ? '#D32F2F' : '#666666')
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
              .borderWidth({ bottom: 2 })
              .borderColor({ bottom: this.selectedTab === tab ? '#D32F2F' : 'transparent' })
              .onClick(async () => {
                this.selectedTab = tab;
                await this.loadPolicies();
              })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }          .width('100%')          .height('100%')          .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.policies, (policy: Policy) => {
            ListItem() {
              Column() {
                Image(policy.imageUrl)
                  .width('100%')
                  .height(160)
                Text(policy.title)
                  .fontSize(16)
                  .fontWeight(500)
                  .margin({ top: 12, left: 16, right: 16 })
                Row() {
                  Text(policy.publishDate)
                    .fontSize(12)
                    .fontColor('#999999')
                  Blank()
                  if (this.canManage()) {
                    Button('编辑')
                      .fontSize(12)
                      .height(28)
                      .padding({ left: 12, right: 12 })
                      .backgroundColor("#D32F2F")
                      .margin({ right: 8 })
                      .onClick(() => {
                        router.pushUrl({
                          url: 'pages/PolicyEditPage',
                          params: { policyId: policy.id }
                        });
                      })
                    Button('删除')
                      .fontSize(12)
                      .height(28)
                      .padding({ left: 12, right: 12 })
                      .backgroundColor('#FF3B30')
                      .onClick(() => {
                        this.deletePolicy(policy.id);
                      })
                  } else {
                    Row() {
                      Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=favorite%20icon%20gray&image_size=square')
                        .width(20)
                        .height(20)
                        .margin({ right: 16 })
                        .onClick(() => {
                          this.toggleFavorite(policy.id);
                        })
                      Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=share%20icon&image_size=square')
                        .width(20)
                        .height(20)
                    }
                  }
                }
                .width('100%')
                .margin({ top: 8, left: 16, right: 16, bottom: 16 })
              }
              .width('100%')
              .backgroundColor('#FFFFFF')
              .margin({ bottom: 12 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/PolicyDetailPage',
                  params: { policyId: policy.id }
                });
              })
            }
          })
        }
        .width('100%')
        .backgroundColor('#F5F5F5')
        .padding({ top: 12 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
