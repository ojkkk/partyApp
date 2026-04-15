import { Policy, PolicyService } from '../models/PolicyModel';
import { StudyResource, StudyService } from '../models/StudyModel';
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
export struct MyFavoritesPage {
  private policyService: PolicyService = new PolicyService();
  private studyService: StudyService = new StudyService();

  @State policies: Policy[] = [];
  @State studyResources: StudyResource[] = [];
  @State isLoading: boolean = true;
  @State currentTab: number = 0;
  @State policyLoading: boolean = true;
  @State studyLoading: boolean = true;

  private tabTitles: string[] = ['政策新闻', '学习资源'];
  private swiperController: SwiperController = new SwiperController();

  async aboutToAppear() {
    await this.loadAllFavorites();
  }

  async loadAllFavorites() {
    this.isLoading = true;
    this.policyLoading = true;
    this.studyLoading = true;

    await Promise.all([
      this.loadPolicyFavorites(),
      this.loadStudyFavorites()
    ]);

    this.isLoading = false;
  }

  async loadPolicyFavorites() {
    try {
      const response = await this.policyService.getFavorites();
      if (response.code === 200 && response.data) {
        this.policies = response.data;
      }
    } catch (error) {
      console.error('加载政策收藏失败:', error);
    } finally {
      this.policyLoading = false;
    }
  }

  async loadStudyFavorites() {
    try {
      const response = await this.studyService.getFavorites();
      if (response.code === 200 && response.data) {
        this.studyResources = response.data;
      }
    } catch (error) {
      console.error('加载学习资源收藏失败:', error);
    } finally {
      this.studyLoading = false;
    }
  }

  async togglePolicyFavorite(id: string): Promise<void> {
    try {
      const response = await this.policyService.toggleFavorite(id);
      if (response.code === 200) {
        const isFavorite = response.data === true;
        promptAction.showToast({ message: isFavorite ? '已收藏' : '已取消收藏', duration: 2000 });
        if (!isFavorite) {
          setTimeout((): void => { this.loadPolicyFavorites(); }, 300);
        }
      }
    } catch (error) {
      console.error('操作失败:', error);
      promptAction.showToast({ message: '操作失败', duration: 2000 });
    }
  }

  async toggleStudyFavorite(id: string): Promise<void> {
    try {
      const response = await this.studyService.toggleFavorite(id);
      if (response.code === 200) {
        const isFavorite = response.data === true;
        promptAction.showToast({ message: isFavorite ? '已收藏' : '已取消收藏', duration: 2000 });
        if (!isFavorite) {
          setTimeout((): void => { this.loadStudyFavorites(); }, 300);
        }
      }
    } catch (error) {
      console.error('操作失败:', error);
      promptAction.showToast({ message: '操作失败', duration: 2000 });
    }
  }

  changeTab(index: number): void {
    this.swiperController.changeIndex(index);
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.currentTab = index;
    });
  }

  getTotalCount(): number {
    return this.policies.length + this.studyResources.length;
  }

  build() {
    Column() {
      // 沉浸式渐变 Header
      this.buildHeader();

      // Tab 切换栏 - 左右两栏占据整行
      this.buildTabBar();

      // 内容区域 - Swiper左右翻页
      if (this.isLoading) {
        this.buildLoadingState();
      } else {
        Swiper(this.swiperController) {
          // 政策新闻 Tab
          Column() {
            this.buildPolicyContent();
          }
          .width('100%')
          .height('100%');

          // 学习资源 Tab
          Column() {
            this.buildStudyContent();
          }
          .width('100%')
          .height('100%');
        }
        .width('100%')
        .flexGrow(1)
        .index(this.currentTab)
        .onChange((index: number) => {
          this.currentTab = index;
        })
        .indicator(false)
        .loop(false);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }

  @Builder
  buildHeader() {
    Stack({ alignContent: Alignment.BottomStart }) {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 155,
          colors: [['#D83A34', 0.0], ['#B51F2E', 0.56], ['#8E1824', 1.0]]
        });

      // 顶部金色线条
      Column()
        .width('100%')
        .height(3)
        .backgroundColor('#E6C98C')
        .opacity(0.9);

      // 装饰圆形
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
        // 顶部导航栏 - 标题居中
        Row() {
          Row() {
            Button() {
              Text('‹')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              .margin({bottom :7})
            }
            .width(48)
            .height(48)
            .backgroundColor(Color.Transparent)
            .onClick(() => router.back());
          }
          .width(48).height('100%');

          Text('我的收藏')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .layoutWeight(1);

          Row().width(48).height('100%');
        }
        .width('100%')
        .height(48)
        .margin({ top: 4 });

        // 统计信息

      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 16 });
    }
    .width('100%')
    .height(60);
  }

  @Builder
  buildTabBar() {
    Row() {
      ForEach(this.tabTitles, (tab: string, idx: number) => {
        Column() {
          Text(tab)
            .fontSize(15)
            .fontWeight(this.currentTab === idx ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.currentTab === idx ? '#B51F2E' : '#666666');

          Text(idx === 0 ? `${this.policies.length}` : `${this.studyResources.length}`)
            .fontSize(11)
            .fontColor(this.currentTab === idx ? '#B51F2E' : '#999999')
            .opacity(0.8)
            .margin({ top: 2 });

          // 底部指示器
          Row()
            .width(this.currentTab === idx ? 36 : 0)
            .height(3)
            .borderRadius(3)
            .backgroundColor('#B51F2E')
            .animation({ duration: 250, curve: Curve.EaseInOut })
            .margin({ top: 6 });
        }
        .padding({ top: 12, bottom: 12 })
        .layoutWeight(1)
        .backgroundColor(this.currentTab === idx ? '#FFF8F3' : '#FFFFFF')
        .onClick(() => this.changeTab(idx));
      });
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .border({ width: 0, color: '#EFE7DB' });
  }

  @Builder
  buildLoadingState() {
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
      .padding({ top: 40, bottom: 40 })
      .width(180)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .border({ width: 1, color: '#EFE7DB' })
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  buildPolicyContent() {
    if (this.policyLoading) {
      this.buildLoadingState();
    } else if (this.policies.length === 0) {
      this.buildEmptyState('policy');
    } else {
      List() {
        ForEach(this.policies, (policy: Policy) => {
          ListItem() {
            this.PolicyCard(policy);
          }
          .margin({ left: 16, right: 16, top: 10 });
        });

        ListItem() {
          Row().height(30);
        };
      }
      .width('100%')
      .flexGrow(1)
      .scrollBar(BarState.Off);
    }
  }

  @Builder
  buildStudyContent() {
    if (this.studyLoading) {
      this.buildLoadingState();
    } else if (this.studyResources.length === 0) {
      this.buildEmptyState('study');
    } else {
      List() {
        ForEach(this.studyResources, (resource: StudyResource) => {
          ListItem() {
            this.StudyCard(resource);
          }
          .margin({ left: 16, right: 16, top: 10 });
        });

        ListItem() {
          Row().height(30);
        };
      }
      .width('100%')
      .flexGrow(1)
      .scrollBar(BarState.Off);
    }
  }

  @Builder
  buildEmptyState(type: string) {
    Column() {
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

        Image($rawfile('我的收藏.png'))
          .width(48)
          .height(48)
          .opacity(0.6);
      }
      .margin({ bottom: 24 });

      Text('暂无收藏')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F1F1F')
        .margin({ bottom: 8 });

      Text(type === 'policy' ? '点击收藏图标，将感兴趣的政策保存到这里' : '点击收藏图标，将感兴趣的学习资源保存到这里')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ bottom: 32 });

      Button() {
        Text('去浏览')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF');
      }
      .width(140)
      .height(44)
      .linearGradient({
        angle: 90,
        colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
      })
      .borderRadius(22)
      .shadow({ radius: 10, color: '#B51F2E40', offsetX: 0, offsetY: 4 })
      .onClick(() => router.back());
    }
    .width('100%')
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  PolicyCard(policy: Policy) {
    Column() {
      // 封面图
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(policy.imageUrl)
          .width('100%')
          .height(150)
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
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: 10 });

        Row() {
          Row() {
            Image($rawfile('时间.png'))
              .width(13)
              .height(13)
              .opacity(0.6)
              .margin({ right: 5 });
            Text(policy.publishDate)
              .fontSize(12)
              .fontColor('#999999');
          };

          Blank();

          // 取消收藏按钮
          Button() {
            Row() {
              Image($rawfile('已收藏.png'))
                .width(13)
                .height(13)
                .margin({ right: 4 });
              Text('取消')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#C9A45C');
            }
          }
          .height(30)
          .padding({ left: 10, right: 10 })
          .backgroundColor('#FFFAF5')
          .border({ width: 1, color: '#E8D5B5' })
          .borderRadius(15)
          .onClick((): void => {
            this.togglePolicyFavorite(policy.id);
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

  @Builder
  StudyCard(resource: StudyResource) {
    Column() {
      Row() {
        // 左侧封面图
        Stack({ alignContent: Alignment.BottomStart }) {
          Image(resource.imageUrl)
            .width(100)
            .height(80)
            .objectFit(ImageFit.Cover)
            .borderRadius(12);

          // 类型标签
          Text(resource.type)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 6, right: 6, top: 3, bottom: 3 })
            .backgroundColor('#D83A34')
            .borderRadius(6)
            .margin({ left: 6, bottom: 6 });
        }
        .width(100)
        .height(80);

        // 右侧内容
        Column() {
          Text(resource.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ bottom: 8 });

          Row() {
            Row() {
              Image($rawfile('时间.png'))
                .width(12)
                .height(12)
                .opacity(0.6)
                .margin({ right: 4 });
              Text(resource.duration + '分钟')
                .fontSize(12)
                .fontColor('#999999');
            };

            Blank();

            // 取消收藏按钮
            Button() {
              Row() {
                Image($rawfile('已收藏.png'))
                  .width(13)
                  .height(13)
                  .margin({ right: 4 });
                Text('取消')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#C9A45C');
              }
            }
            .height(28)
            .padding({ left: 8, right: 8 })
            .backgroundColor('#FFFAF5')
            .border({ width: 1, color: '#E8D5B5' })
            .borderRadius(14)
            .onClick((): void => {
              this.toggleStudyFavorite(resource.id);
            });
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);
        }
        .layoutWeight(1)
        .height(80)
        .padding({ left: 14 })
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 6, color: '#00000008', offsetX: 0, offsetY: 2 })
    .onClick(() => router.pushUrl({ url: 'pages/StudyDetailPage', params: { resourceId: resource.id } }));
  }
}
