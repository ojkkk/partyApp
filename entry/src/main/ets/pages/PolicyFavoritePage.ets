import { Policy, PolicyService } from '../models/PolicyModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct PolicyFavoritePage {
  private policyService: PolicyService = new PolicyService();
  @State policies: Policy[] = [];
  @State isLoading: boolean = false;
  @State user: UserInfo | null = null;

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadFavorites();
  }

  async loadFavorites() {
    this.isLoading = true;
    try {
      const response = await this.policyService.getFavorites();
      if (response.code === 200 && response.data) {
        this.policies = response.data;
      }
    } catch (error) {
      console.error('加载收藏失败:', error);
      promptAction.showToast({
        message: '加载收藏失败',
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
        await this.loadFavorites();
      }
    } catch (error) {
      console.error('操作失败:', error);
      promptAction.showToast({
        message: '操作失败',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('返回.png'))
          .width(24)
          .height(24)
          .margin({ left: 16, right: 16 })
          .onClick(() => {
            router.back();
          })
        Text('我的收藏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: '#EEEEEE' })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.policies.length === 0) {
        Column() {
          Text('暂无收藏')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
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
                  Row() {
                    Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=favorite%20icon%20red&image_size=square')
                      .width(20)
                      .height(20)
                      .margin({ right: 16 })
                      .onClick(() => {
                        this.toggleFavorite(policy.id);
                      })
                    Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=share%20icon&image_size=square')
                      .width(20)
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