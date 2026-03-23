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
        // 为每个政策设置初始收藏状态为true
        const policiesWithFavorite: Policy[] = [];
        for (let i = 0; i < response.data.length; i++) {
          const policy = response.data[i];
          policy.isFavorite = true;
          policiesWithFavorite.push(policy);
        }
        this.policies = policiesWithFavorite;
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
      console.log('收藏响应:', response);
      if (response.code === 200) {
        // 确保response.data是布尔值
        const isFavorite = response.data === true;
        console.log('新的收藏状态:', isFavorite);
        
        // 更新本地收藏状态
        const newPolicies: Policy[] = [];
        for (let i = 0; i < this.policies.length; i++) {
          const policy = this.policies[i];
          if (policy.id === id) {
            // 创建新对象并设置收藏状态
            const updatedPolicy: Policy = {
              id: policy.id,
              title: policy.title,
              content: policy.content,
              type: policy.type,
              publishDate: policy.publishDate,
              imageUrl: policy.imageUrl,
              videoUrl: policy.videoUrl,
              viewCount: policy.viewCount,
              createdBy: policy.createdBy,
              createdAt: policy.createdAt,
              updatedAt: policy.updatedAt,
              isFavorite: isFavorite
            };
            newPolicies.push(updatedPolicy);
          } else {
            newPolicies.push(policy);
          }
        }
        
        console.log('更新前的policies:', this.policies);
        console.log('更新后的policies:', newPolicies);
        
        // 重新赋值触发UI更新
        this.policies = newPolicies;
        
        promptAction.showToast({
          message: isFavorite ? '已收藏' : '已取消收藏',
          duration: 2000
        });
        
        // 如果取消收藏，从列表中移除
        if (!isFavorite) {
          setTimeout(() => {
            this.loadFavorites();
          }, 500);
        }
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
                  .borderRadius({topLeft:12,topRight:12})
                Text(policy.title)
                  .fontSize(16)
                  .fontWeight(500)
                  .margin({ top: 12, left: 16, right: 16 })
                Row() {
                  Text(policy.publishDate)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({left:8})
                  Blank()
                  Row() {
                    Image(policy.isFavorite ? $rawfile('已收藏.png') : $rawfile('未收藏.png'))
                      .width(20)
                      .height(20)
                      .margin({ right: 12 })
                      .onClick(() => {
                        this.toggleFavorite(policy.id);
                      })
                    Image($rawfile('分享(政策).png'))
                      .width(22)
                      .height(22)
                      .margin({top:2.5,right:12})
                  }
                }
                .width('100%')
                .margin({ top: 8, left: 16, right: 16, bottom: 16 })
              }
              .width('97%')
              .backgroundColor('#FFFFFF')
              .margin({ left: '1.5%', right: '1.5%', bottom: 8 })
              .borderRadius(12)
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