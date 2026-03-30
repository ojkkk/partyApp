import { Policy, PolicyService } from '../models/PolicyModel';
import { UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct PolicyPage {
  private tabsController: TabsController = new TabsController();
  @State currentIndex: number = 0;
  private readonly TAB_ITEM_WIDTH: number = 94;
  private tabTitles: string[] = ['新闻动态', '政策法规', '重要讲话', '先进典型'];

  private policyService: PolicyService = new PolicyService();
  @State policiesList: Policy[][] = [[], [], [], []];
  @State isLoading: boolean = false;
  @State user: UserInfo | null = null;
  @State isFavoriteBtnPressed: boolean = false;
  @State isAddBtnPressed: boolean = false;

  async aboutToAppear(): Promise<void> {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadPolicies(0);
  }

  canManage(): boolean {
    return this.user?.role === 'admin' || this.user?.role === 'branch_admin';
  }

  // 修复：禁用数组展开运算符，改用 Array.from 复制数组
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

        // 关键修复：替换 ... 展开语法
        const newLists: Policy[][] = Array.from(this.policiesList);
        newLists[index] = list;
        this.policiesList = newLists;
      }
    } catch (error) {
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  changeTab(index: number): void {
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.currentIndex = index;
    });
    this.tabsController.changeIndex(index);
    if (this.policiesList[index].length === 0) {
      this.loadPolicies(index);
    }
  }

  async toggleFavorite(id: string): Promise<void> {
    try {
      const res = await this.policyService.toggleFavorite(id);
      if (res.code === 200) {
        // 关键修复：替换 ... 展开语法
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
      // 顶部标题栏
      Row() {
        Text('政策宣传')
          .fontSize(22)
          .fontWeight(FontWeight.Bold);
        Blank();

        Column() {
          Image($rawfile('收藏文件.png'))
            .width(30)
            .height(24)
            .colorFilter(this.isFavoriteBtnPressed ? [0.9,0,0,0,0] : []);
        }
        .onTouch((e: TouchEvent) => this.isFavoriteBtnPressed = e.type === TouchType.Down)
        .onClick(() => router.pushUrl({ url: 'pages/PolicyFavoritePage' }))
        .margin({ right: 16 });

        if (this.canManage()) {
          Column() {
            Image($rawfile('新建项目.png'))
              .width(32)
              .height(32)
              .objectFit(ImageFit.Contain)
              .colorFilter(this.isAddBtnPressed ? [0.9,0,0,0,0] : []);
          }
          .onTouch((e: TouchEvent) => this.isAddBtnPressed = e.type === TouchType.Down)
          .onClick(() => router.pushUrl({ url: 'pages/PolicyEditPage' }));
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .backgroundColor(Color.White);

      // 自定义标签栏 + 平滑滑动指示器
      // 自定义标签栏 + 平滑滑动指示器
      Stack({ alignContent: Alignment.BottomStart }) {
        // ✅ 修正：去掉多余的属性调用，保持结构清晰
        Scroll() {
          Row() {
            ForEach(this.tabTitles, (title: string, idx: number) => {
              Text(title)
                .width(this.TAB_ITEM_WIDTH)
                .fontSize(16)
                .fontColor(this.currentIndex === idx ? '#D32F2F' : '#666666')
                .textAlign(TextAlign.Center)
                .padding({ top: 12, bottom:12 ,left:12,right:12})
                .onClick(() => this.changeTab(idx));
            });
          }
          .width('100%') // 确保 Row 占满宽度

        }
        .scrollable(ScrollDirection.Horizontal) // ✅ 属性紧跟在 } 后面，不要换行
        .backgroundColor(Color.White)
        .edgeEffect(EdgeEffect.None) // 去掉滚动时的边缘闪光效果，更美观



        // 红色平滑指示器
        Stack()
          .width(40)
          .height(2)
          .backgroundColor('#D32F2F')
          .borderRadius(1)
          .translate({ x: this.TAB_ITEM_WIDTH * this.currentIndex + (this.TAB_ITEM_WIDTH - 40) / 2 })
          .margin({ top:2,bottom:8});
      }
      .width('100%')


      // Tabs 内容区域
      Tabs({ controller: this.tabsController }) {
        ForEach(this.tabTitles, (title: string, idx: number) => {
          TabContent() {
            if (this.isLoading && idx === this.currentIndex) {
              Column() {
                LoadingProgress().width(50).height(50);
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center);
            } else {
              List() {
                ForEach(this.policiesList[idx], (policy: Policy) => {
                  ListItem() {
                    Column() {
                      Image(policy.imageUrl)
                        .width('100%')
                        .height(160)
                        .borderRadius({ topLeft: 12, topRight: 12 });
                      Text(policy.title)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .margin({ top: 12, left: 16, right: 16 });

                      Row() {
                        Text(policy.publishDate)
                          .fontSize(12)
                          .fontColor('#999999')
                          .margin({ left: 8 });
                        Blank();

                        if (this.canManage()) {
                          Button('编辑')
                            .width(60)
                            .height(28)
                            .backgroundColor('#D32F2F')
                            .margin({ right: 8 })
                            .onClick(() => router.pushUrl({ url: 'pages/PolicyEditPage', params: { policyId: policy.id } }));
                          Button('删除')
                            .width(60)
                            .height(28)
                            .backgroundColor('#FF3B30')
                            .onClick(() => this.deletePolicy(policy.id));
                        } else {
                          Image(policy.isFavorite ? $rawfile('已收藏.png') : $rawfile('未收藏.png'))
                            .width(20)
                            .height(20)
                            .margin({ right: 12 })
                            .onClick(() => this.toggleFavorite(policy.id));
                          Image($rawfile('分享(政策).png'))
                            .width(22)
                            .height(22);
                        }
                      }
                      .padding({ left: 16, right: 16, bottom: 16 });
                    }
                    .width('97%')
                    .backgroundColor(Color.White)
                    .margin({ left: '1.5%', right: '1.5%', bottom: 8 })
                    .borderRadius(12)
                    .onClick(() => router.pushUrl({ url: 'pages/PolicyDetailPage', params: { policyId: policy.id } }));
                  }
                });
              }
              .width('100%')
              .height('100%')

              .backgroundColor('#F5F5F5');

            }
          }
        });
      }
      .onChange((idx: number) => this.changeTab(idx))
      .scrollable(true)
      // ✅ 关键修复：删除报错的 barMode 属性（API20 不支持）
      .layoutWeight(1)
      .width('100%')
      .barHeight(0);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}