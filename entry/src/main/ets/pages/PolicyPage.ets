import { Policy, PolicyService } from '../models/PolicyModel';
import { UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

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

@Entry
@Component
export struct PolicyPage {
  @State currentIndex: number = 0;
  @State scrollOffset: number = 0;
  private readonly TAB_ITEM_WIDTH: number = 94;
  private tabTitles: string[] = ['新闻动态', '政策法规', '重要讲话', '先进典型'];
  private swiperController: SwiperController = new SwiperController();

  private policyService: PolicyService = new PolicyService();
  @State policiesList: Policy[][] = [[], [], [], []];
  @State isLoading: boolean = false;
  @State user: UserInfo | null = null;
  @State isRefreshing: boolean = false;
  @State totalCount: number = 0;

  // 删除确认对话框控制器
  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDeleteDialog({
      onConfirm: () => {}
    }),
    isModal: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  async aboutToAppear(): Promise<void> {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadPolicies(0);
    this.updateTotalCount();
    // 监听发布/编辑事件，从编辑页返回时刷新
    emitter.on("refreshPolicies", async () => {
      console.info("✅ 从编辑页返回，刷新政策列表");
      await this.loadPolicies(0);
    });
  }

  aboutToDisappear(): void {
    emitter.off("refreshPolicies");
  }

  canManage(): boolean {
    return this.user?.role === 'admin' || this.user?.role === 'branch_admin';
  }

  getRoleLabel(): string {
    if (this.canManage()) {
      return '当前身份：内容管理者';
    }
    return '当前身份：政策浏览者';
  }

  updateTotalCount(): void {
    let count = 0;
    for (let i = 0; i < this.policiesList.length; i++) {
      count += this.policiesList[i].length;
    }
    this.totalCount = count;
  }

  async loadPolicies(index: number): Promise<void> {
    this.isLoading = true;
    const type: string = this.tabTitles[index];
    try {
      const response = await this.policyService.getPolicies(type);
      if (response.code === 200 && response.data) {
        const favoritesResponse = await this.policyService.getFavorites();
        const favIds: Set<string> = new Set<string>();
        if (favoritesResponse.code === 200 && favoritesResponse.data) {
          favoritesResponse.data.forEach((p: Policy) => favIds.add(p.id));
        }

        const list: Policy[] = [];
        response.data.forEach((p: Policy) => {
          const item: Policy = p;
          item.isFavorite = favIds.has(p.id);
          list.push(item);
        });

        const newLists: Policy[][] = Array.from(this.policiesList);
        newLists[index] = list;
        this.policiesList = newLists;
        this.updateTotalCount();
      }
    } catch (error) {
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  changeTab(index: number): void {
    this.swiperController.changeIndex(index);
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.currentIndex = index;
      this.scrollOffset = this.TAB_ITEM_WIDTH * index;
    });
    if (this.policiesList[index].length === 0) {
      this.loadPolicies(index);
    }
  }

  async toggleFavorite(id: string): Promise<void> {
    try {
      const res = await this.policyService.toggleFavorite(id);
      if (res.code === 200) {
        const currentList: Policy[] = Array.from(this.policiesList[this.currentIndex]);
        const idx: number = currentList.findIndex((p: Policy) => p.id === id);
        if (idx > -1) {
          currentList[idx].isFavorite = res.data;
          this.policiesList[this.currentIndex] = currentList;
        }
        promptAction.showToast({ message: res.data ? '已收藏' : '已取消收藏', duration: 2000 });
      }
    } catch (e) {
      promptAction.showToast({ message: '操作失败', duration: 2000 });
    }
  }

  async deletePolicy(id: string): Promise<void> {
    try {
      const res = await this.policyService.deletePolicy(id);
      if (res.code === 200) {
        this.loadPolicies(this.currentIndex);
        promptAction.showToast({ message: '删除成功', duration: 2000 });
      }
    } catch (e) {
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      // 沉浸式渐变 Header - 四角布局
      Stack({ alignContent: Alignment.TopStart }) {
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

        // 左上角：标题（大字）
        Column() {
          Text('政策宣传')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .letterSpacing(1);

          Text('学习贯彻党的方针政策')
            .fontSize(12)
            .fontColor('#FFFFFF70')
            .margin({ top: 4 });
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, top: 20 });

        // 右下角：操作按钮
        Row() {
          // 收藏按钮
          Button() {
            Row() {
              Image($rawfile('收藏文件.png'))
                .width(14)
                .height(14)
                .margin({ right: 3 });
              Text('收藏')
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor('#A3202D');
            }
          }
          .height(28)
          .padding({ left: 10, right: 10 })
          .backgroundColor('#FFF8F1')
          .border({ width: 1, color: '#F0D7A5' })
          .borderRadius(6)
          .shadow({ radius: 6, color: '#00000015', offsetX: 0, offsetY: 3 })
          .margin({ right: 6 })
          .onClick(() => router.pushUrl({ url: 'pages/PolicyFavoritePage' }));

          // 发布按钮（仅管理员）
          if (this.canManage()) {
            Button() {
              Row() {
                Text('＋')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#A3202D')
                  .margin({ right: 3 });
                Text('发布')
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#A3202D');
              }
            }
            .height(28)
            .padding({ left: 10, right: 10 })
            .backgroundColor('#FFF8F1')
            .border({ width: 1, color: '#F0D7A5' })
            .borderRadius(6)
            .shadow({ radius: 6, color: '#00000015', offsetX: 0, offsetY: 3 })
            .onClick(() => router.pushUrl({ url: 'pages/PolicyEditPage' }));
          }
        }
        .padding({ right: 16, bottom: 12 })
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: '100%', y: '100%' });

        // 左下角：统计信息
        Row() {
          Text(`共 ${this.totalCount} 项内容`)
            .fontSize(11)
            .fontColor('#8C5D13')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#FFF4DE')
            .border({ width: 1, color: '#F0D29A' })
            .borderRadius(10)
        }
        .padding({ left: 16, bottom: 12 })
        .position({ x: 0, y: '100%' })
        .markAnchor({ x: 0, y: '100%' });
      }
      .width('100%')
      .height(150);

      // Tab 切换栏 - 模仿 ActivityPage 风格，字体缩小
      Row() {
        ForEach(this.tabTitles, (tab: string, idx: number) => {
          Column() {
            Text(tab)
              .fontSize(14)
              .fontWeight(this.currentIndex === idx ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.currentIndex === idx ? '#B51F2E' : '#7A7A7A')
              .padding({ left: 12, right: 12, top: 10, bottom: 8 });

            Row()
              .width(this.currentIndex === idx ? 28 : 0)
              .height(3)
              .borderRadius(3)
              .backgroundColor('#B51F2E')
              .animation({ duration: 250, curve: Curve.EaseInOut });
          }
          .padding({ bottom: 6 })
          .layoutWeight(1)
          .backgroundColor(this.currentIndex === idx ? '#FFF8F3' : '#FFFFFF')
          .borderRadius(10)
          .onClick(() => this.changeTab(idx));
        });
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 0 })
      .backgroundColor('#F7F4EF')
      .justifyContent(FlexAlign.SpaceBetween);

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
      } else {
        Refresh({
          refreshing: this.isRefreshing,
          offset: 100,
          friction: 100
        }) {
          Swiper(this.swiperController) {
            ForEach(this.tabTitles, (title: string, idx: number) => {
              Column() {
                this.buildPolicyList(idx);
              }
              .width('100%')
              .height('100%');
            });
          }
          .index(this.currentIndex)
          .indicator(false)
          .loop(false)
          .onContentDidScroll((selectedIndex, index, position) => {
            this.scrollOffset = (index - position) * this.TAB_ITEM_WIDTH;
          })
          .onChange((index: number) => {
            this.changeTab(index);
          })
          .width('100%');
        }
        .onRefreshing(async () => {
          this.isRefreshing = true;
          await this.loadPolicies(this.currentIndex);
          this.isRefreshing = false;
        })
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F7F4EF');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }

  @Builder
  buildPolicyList(idx: number) {
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
            Text(`${this.tabTitles[idx]} · ${this.policiesList[idx].length} 条`)
              .fontSize(13)
              .fontColor('#666666');
          };

          Blank();


        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 });
      };

      ForEach(this.policiesList[idx], (policy: Policy) => {
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
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor('#F7F4EF');
  }

  @Builder
  PolicyCard(policy: Policy) {
    Column() {
      // 封面图区域
      Stack({ alignContent: Alignment.TopStart }) {
        Image(policy.imageUrl)
          .width('100%')
          .height(180)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 16, topRight: 16 });

        Column()
          .width('100%')
          .height(180)
          .linearGradient({
            angle: 180,
            colors: [['#00000000', 0.0], ['#00000015', 0.6], ['#00000030', 1.0]]
          })
          .borderRadius({ topLeft: 16, topRight: 16 });

        Row() {
          Text(policy.type)
            .fontSize(11)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#B51F2E')
            .borderRadius({ topLeft: 16, bottomRight: 10 });

          Blank();

          if (policy.isFavorite) {
            Row() {
              Image($rawfile('已收藏.png'))
                .width(14)
                .height(14)
                .margin({ right: 4 });
              Text('已收藏')
                .fontSize(11)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium);
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .borderRadius(10);
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12 });
      }
      .width('100%')
      .height(180);

      // 内容区
      Column() {
        Row() {
          Column()
            .width(4)
            .height(22)
            .borderRadius(2)
            .linearGradient({
              angle: 180,
              colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
            })
            .margin({ right: 10 });

          Text(policy.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1);
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 });

        Column() {
          this.InfoRow($rawfile('时间.png'), '发布时间', policy.publishDate);
          Divider().color('#F3EBDD').strokeWidth(1).margin({ top: 10, bottom: 10 });
          if (policy.publisher) {
            this.InfoRow($rawfile('发布人.png'), '发布人', policy.publisher);
            Divider().color('#F3EBDD').strokeWidth(1).margin({ top: 10, bottom: 10 });
          }
          this.InfoRow($rawfile('阅读量.png'), '阅读量',
            (policy.viewCount !== undefined ? policy.viewCount : 0) + '次');
          if (policy.summary) {
            Divider().color('#F3EBDD').strokeWidth(1).margin({ top: 10, bottom: 10 });
            Row() {
              Row() {
                Image($rawfile('摘要.png'))
                  .width(14)
                  .height(14)
                  .opacity(0.58);
              }
              .width(28)
              .height(28)
              .borderRadius(14)
              .backgroundColor('#F7F4EF')
              .justifyContent(FlexAlign.Center)
              .margin({ right: 10 });

              Text('摘要')
                .fontSize(13)
                .fontColor('#888888')
                .margin({ right: 6 });

              Text(policy.summary!)
                .fontSize(13)
                .fontColor('#555555')
                .layoutWeight(1)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
            .width('100%');
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#FFFCF8')
        .borderRadius(12)
        .border({ width: 1, color: '#F3EBDD' })
        .margin({ bottom: 10 });

        // 标签区
        if (policy.tags) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(policy.tags!.split(','), (tag: string) => {
              Text(tag.trim())
                .fontSize(11)
                .fontColor('#B51F2E')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor('#FFF0F0')
                .borderRadius(4)
                .margin({ right: 6, bottom: 6 });
            });
          }
          .width('100%')
          .margin({ bottom: 14 });
        }

        Row() {
          Blank();

          if (this.canManage()) {
            Button() {
              Row() {
                Image($rawfile('编辑普通.png'))
                  .width(14)
                  .height(14)
                  .opacity(0.85)
                  .margin({ right: 6 });
                Text('编辑')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#B51F2E');
              }
            }
            .height(36)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFF1F1')
            .border({ width: 1, color: '#E3B3B3' })
            .borderRadius(10)
            .margin({ right: 10 })
            .onClick((): void => {
              router.pushUrl({ url: 'pages/PolicyEditPage', params: { policyId: policy.id } });
            });

            Button() {
              Row() {
                Image($rawfile('删除.png'))
                  .width(14)
                  .height(14)
                  .opacity(0.78)
                  .margin({ right: 6 });
                Text('删除')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#B51F2E');
              }
            }
            .height(36)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFF1F1')
            .border({ width: 1, color: '#E3B3B3' })
            .borderRadius(10)
            .onClick((): void => {
              promptAction.showDialog({
                title: '确认删除',
                message: '确定要删除这篇政策文件吗？此操作不可撤销。',
                buttons: [
                  { text: '删除', color: '#B51F2E' },
                  { text: '取消', color: '#999999' }
                ]
              }).then((value) => {
                if (value.index === 0) {
                  this.deletePolicy(policy.id);
                }
              });
            });
          } else {
            Button() {
              Row() {
                Image(policy.isFavorite ? $rawfile('已收藏.png') : $rawfile('未收藏.png'))
                  .width(16)
                  .height(16)
                  .margin({ right: 6 });
                Text(policy.isFavorite ? '已收藏' : '收藏')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(policy.isFavorite ? '#C9A45C' : '#666666');
              }
            }
            .height(36)
            .padding({ left: 16, right: 16 })
            .backgroundColor(policy.isFavorite ? '#FFFAF5' : '#F7F4EF')
            .border({ width: 1, color: policy.isFavorite ? '#E8D5B5' : '#E6DFD5' })
            .borderRadius(10)
            .margin({ right: 10 })
            .onClick((): void => {
              this.toggleFavorite(policy.id);
            });

            Button() {
              Row() {
                Image($rawfile('分享(政策).png'))
                  .width(14)
                  .height(14)
                  .opacity(0.85)
                  .margin({ right: 6 });
                Text('分享')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#B51F2E');
              }
            }
            .height(36)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFF8F5')
            .border({ width: 1, color: '#D8B36A' })
            .borderRadius(10);
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 16, bottomRight: 16 });
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#EFE7DB' })
    .clip(true)
    .shadow({ radius: 10, color: '#00000010', offsetX: 0, offsetY: 4 })
    .onClick(() => router.pushUrl({ url: 'pages/PolicyDetailPage', params: { policyId: policy.id } }));
  }

  @Builder
  InfoRow(icon: Resource, label: string, value: string, highlight: boolean = false) {
    Row() {
      Row() {
        Image(icon)
          .width(14)
          .height(14)
          .opacity(highlight ? 0.9 : 0.58);
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(highlight ? '#FFF1F1' : '#F7F4EF')
      .justifyContent(FlexAlign.Center)
      .margin({ right: 10 });

      Text(label)
        .fontSize(13)
        .fontColor('#888888')
        .margin({ right: 6 });

      Text(value)
        .fontSize(13)
        .fontColor(highlight ? '#B51F2E' : '#555555')
        .fontWeight(highlight ? FontWeight.Medium : FontWeight.Regular)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1);
    }
    .width('100%');
  }
}
