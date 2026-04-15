import { Policy, PolicyService } from '../models/PolicyModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

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
      promptAction.showToast({ message: '加载收藏失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async toggleFavorite(id: string): Promise<void> {
    try {
      const response = await this.policyService.toggleFavorite(id);
      if (response.code === 200) {
        const isFavorite = response.data === true;
        promptAction.showToast({ message: isFavorite ? '已收藏' : '已取消收藏', duration: 2000 });
        if (!isFavorite) {
          setTimeout((): void => { this.loadFavorites(); }, 300);
        }
      }
    } catch (error) {
      console.error('操作失败:', error);
      promptAction.showToast({ message: '操作失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      // 沉浸式渐变 Header - 模仿 ActivityPage
      Stack({ alignContent: Alignment.BottomStart }) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 155,
            colors: [['#D83A34', 0.0], ['#B51F2E', 0.56], ['#8E1824', 1.0]]
          });

        Column()
          .width('100%')
          .height(4)
          .backgroundColor('#E6C98C')
          .opacity(0.9)
          .position({ x: 0, y: 0 });

        Column()
          .width(168)
          .height(168)
          .borderRadius(84)
          .backgroundColor('#FFFFFF')
          .opacity(0.07)
          .position({ x: 254, y: -52 });

        Column()
          .width(94)
          .height(94)
          .borderRadius(47)
          .backgroundColor('#F2D9A6')
          .opacity(0.12)
          .position({ x: 318, y: 26 });

        Column() {
          // 顶部导航栏 - 返回按钮与标题同行
          Row() {
            Button() {
              Text('‹')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF');
            }
            .width(48)
            .height(48)
            .margin({ bottom: 6 })
            .backgroundColor(Color.Transparent)
            .onClick(() => router.back());

            Text('我的收藏')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .margin({ right: 48 });
          }
          .width('100%')
          .height(48)
          .margin({top:10})

          // 副标题区
          Row() {
            Text(`${this.policies.length} 条收藏`)
              .fontSize(12)
              .fontColor('#8C5D13')
              .fontWeight(FontWeight.Medium)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#FFF4DE')
              .border({ width: 1, color: '#F0D29A' })
              .borderRadius(12)
              .margin({ right: 8 });

          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 4 });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 16 });
      }
      .width('100%')
      .height(140);

      // 内容区域
      if (this.isLoading) {
        Column() {
          Column() {
            LoadingProgress()
              .width(42)
              .height(42)
              .color('#B51F2E');
            Text('内容加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 14 });
          }
          .padding({ top: 28, bottom: 28 })
          .width(180)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .border({ width: 1, color: '#EFE7DB' })
          .alignItems(HorizontalAlign.Center);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F7F4EF');
      } else if (this.policies.length === 0) {
        this.buildEmptyState();
      } else {
        this.buildFavoriteList();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }

  @Builder
  buildEmptyState() {
    Column() {
      // 装饰圆环
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(120)
          .height(120)
          .borderRadius(60)
          .backgroundColor('#FFF8F5');

        Column()
          .width(100)
          .height(100)
          .borderRadius(50)
          .border({ width: 3, color: '#E8D5B5', style: BorderStyle.Dashed });

        Image($rawfile('收藏文件.png'))
          .width(48)
          .height(48);
      }
      .margin({ bottom: 24 });

      Text('暂无收藏')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F1F1F')
        .margin({ bottom: 8 });

      Text('点击收藏图标，将感兴趣的政策保存到这里')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ bottom: 32 });

      Button() {
        Row() {
          Text('去浏览政策')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF');
        }
      }
      .width(160)
      .height(48)
      .linearGradient({
        angle: 90,
        colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
      })
      .borderRadius(24)
      .shadow({ radius: 10, color: '#B51F2E40', offsetX: 0, offsetY: 4 })
      .onClick(() => router.back());
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F7F4EF');
  }

  @Builder
  buildFavoriteList() {
    List() {
      // 列表标题
      ListItem() {
        Row() {
          Row() {
            Row()
              .width(3)
              .height(14)
              .borderRadius(2)
              .backgroundColor('#B51F2E')
              .margin({ right: 8 });
            Text(`收藏列表 · ${this.policies.length} 条`)
              .fontSize(13)
              .fontColor('#666666');
          };

          Blank();


        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 });
      };

      ForEach(this.policies, (policy: Policy) => {
        ListItem() {
          this.PolicyCard(policy);
        }
        .margin({ left: 16, right: 16, top: 10 });
      });

      // 底部留白
      ListItem() {
        Row().height(30);
      };
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor('#F7F4EF');
  }

  @Builder
  PolicyCard(policy: Policy) {
    Column() {
      // 封面图
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(policy.imageUrl)
          .width('100%')
          .height(160)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 14, topRight: 14 });

        Text(policy.type)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#B51F2E')
          .borderRadius({ topRight: 14, bottomLeft: 10 });
      }
      .width('100%');

      // 内容区
      Column() {
        Text(policy.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: 10 });

        Row() {
          Row() {
            Image($rawfile('时间.png'))
              .width(14)
              .height(14)
              .opacity(0.6)
              .margin({ right: 6 });

            Text(policy.publishDate)
              .fontSize(13)
              .fontColor('#999999');
          };

          Blank();

          // 取消收藏按钮
          Button() {
            Row() {
              Image($rawfile('已收藏.png'))
                .width(14)
                .height(14)
                .margin({ right: 4 });
              Text('取消收藏')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#C9A45C');
            }
          }
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#FFFAF5')
          .border({ width: 1, color: '#E8D5B5' })
          .borderRadius(16)
          .onClick((): void => {
            this.toggleFavorite(policy.id);
          });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);
      }
      .width('100%')
      .padding(14);
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 6, color: '#00000008', offsetX: 0, offsetY: 2 })
    .onClick(() => router.pushUrl({ url: 'pages/PolicyDetailPage', params: { policyId: policy.id } }));
  }
}
