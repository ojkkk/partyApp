import { UserInfo, UserService } from '../models/UserModel';
import { Policy, PolicyService } from '../models/PolicyModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { StudyResource, StudyService } from '../models/StudyModel';
import { Activity, ActivityService } from '../models/ActivityModel';
import { ChatService } from '../models/ChatModel';
import { emitter } from '@kit.BasicServicesKit'; // 加这行
import { AvatarComponent } from '../components/AvatarComponent';

// 显式声明接口，符合ArkTS严格类型规范
interface SearchResults {
  policies: Policy[];
  studies: StudyResource[];
  activities: Activity[];
  users: UserInfo[];
}

// 党建风格红色系配色方案
const PRIMARY_COLOR: string = '#C8102E';
const BG_COLOR: string = '#FFF5F5';
const CARD_BG: string = '#FFFFFF';
const TEXT_MAIN: string = '#1A1A1A';
const TEXT_SECOND: string = '#5A5A5A';
const TEXT_GRAY: string = '#8E8E93';
const CARD_SHADOW: string = '#20C8102E'; // 红色调阴影
const SECTION_BG: string = '#FFEBEE'; // 浅红色背景
const ACCENT_RED: string = '#E53935'; // 强调红色
// 定义底部导航栏高度
const NAV_BAR_HEIGHT: number = 64;
@Entry
@Component
export struct HomePage {
  @State user: UserInfo | null = null;
  @State policies: Policy[] = [];
  @State isLoading: boolean = false;
  @State searchText: string = '';
  @State showSearchResults: boolean = false;
  @State isSearching: boolean = false;
  @State searchResults: SearchResults = {
    policies: [],
    studies: [],
    activities: [],
    users: []
  };
  @State unreadCount: number = 0;
  @State branchUnreadCount: number = 0;
  @State currentBannerIndex: number = 0;

  // 轮播图数据 - 增加圆角和阴影
  private bannerImages: Resource[] = [
    $rawfile("roll001.jpg"),
    $rawfile("roll002.jpg"),
    $rawfile("roll003.jpg")
  ];

  private policyService: PolicyService = new PolicyService();
  private studyService: StudyService = new StudyService();
  private activityService: ActivityService = new ActivityService();
  private userService: UserService = new UserService();
  private chatService: ChatService = new ChatService();

  // 页面首次创建时调用
  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadLatestPolicies();
    // 首次也加载一次未读数
    await this.loadUnreadCount();
    emitter.on("refreshUnread", async () => {
      console.info("✅ 从聊天页返回，刷新未读数");
      await this.loadUnreadCount();
    });
    emitter.on("refreshBranchUnread", async () => {
      console.info("✅ 从支部管理页返回，刷新未读数");
      await this.loadUnreadCount();
    });
  }

  // 核心修复：每次页面显示时都会调用（包括从ChatListPage返回）
  async onPageShow() {
    console.info('HomePage: 页面显示，刷新未读消息数');
    await this.loadUnreadCount();
  }


  aboutToDisappear() {

      emitter.off("refreshUnread");
      emitter.off("refreshBranchUnread");

  }
  async loadUnreadCount() {
    try {
      console.info('HomePage: 开始请求未读数...');
      const count = await this.chatService.getUnreadCount();
      console.info('HomePage: 后端返回未读数:', count);
      // 赋值给 @State 变量，触发UI刷新
      this.unreadCount = count;

      // 获取支部未读消息数
      const branchCountResponse = await this.userService.getUnreadMessageCount();
      if (branchCountResponse.code === 200 && branchCountResponse.data !== undefined) {
        this.branchUnreadCount = branchCountResponse.data;
      }
    } catch (error) {
      console.error('HomePage: 加载未读消息数失败:', error);
    }
  }

  async loadLatestPolicies() {
    this.isLoading = true;
    try {
      const response = await this.policyService.getPolicies();
      if (response.code === 200 && response.data) {
        this.policies = response.data.slice(0, 10);
      }
    } catch (error) {
      console.error('加载最新动态失败:', error);
      promptAction.showToast({
        message: '加载最新动态失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async search() {
    const keyword = this.searchText.trim();
    if (!keyword) return;

    this.isSearching = true;
    this.showSearchResults = true;

    try {
      const responses = await Promise.all([
        this.policyService.getPolicies(),
        this.studyService.getResources(),
        this.activityService.getActivities(),
        this.userService.getBranchMembers()
      ]);

      const policyResponse = responses[0];
      const studyResponse = responses[1];
      const activityResponse = responses[2];
      const userResponse = responses[3];

      const results: SearchResults = {
        policies: policyResponse.code === 200 && policyResponse.data
          ? policyResponse.data.filter((p: Policy) => p.title.includes(keyword) || p.content.includes(keyword))
          : [],
        studies: studyResponse.code === 200 && studyResponse.data
          ? studyResponse.data.filter((s: StudyResource) => s.title.includes(keyword) || s.content.includes(keyword))
          : [],
        activities: activityResponse.code === 200 && activityResponse.data
          ? activityResponse.data.filter((a: Activity) => a.title.includes(keyword) || a.content.includes(keyword))
          : [],
        users: userResponse.code === 200 && userResponse.data
          ? userResponse.data.filter((u: UserInfo) => u.name.includes(keyword) || u.branch.includes(keyword))
          : []
      };
      this.searchResults = results;
    } catch (error) {
      console.error('搜索失败:', error);
      promptAction.showToast({
        message: '搜索失败',
        duration: 2000
      });
    } finally {
      this.isSearching = false;
    }
  }

  clearSearch() {
    this.searchText = '';
    this.showSearchResults = false;
  }

  isAdmin(): boolean {
    return this.user?.role === 'admin';
  }

  isBranchAdmin(): boolean {
    return this.user?.role === 'branch_admin';
  }

  canManage(): boolean {
    return this.isAdmin() || this.isBranchAdmin();
  }

  // 搜索结果分类标题组件
  @Builder
  SectionTitle(title: string) {
    Row() {
      Rect()
        .width(4)
        .height(16)
        .fill(PRIMARY_COLOR)
        .borderRadius(2)
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_MAIN)
        .margin({ left: 8 })
      Blank()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  // 通用搜索结果卡片
  @Builder
  ResultCard(imgUrl: string, title: string, desc: string, onClick: () => void) {
    Row() {
      Image(imgUrl)
        .width(70)
        .height(70)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#F0F0F0')

      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_MAIN)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Blank()

        Text(desc.length > 45 ? desc.substring(0, 45) + '...' : desc)
          .fontSize(13)
          .fontColor(TEXT_SECOND)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(CARD_BG)
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 1
    })
    .onClick(onClick)
  }

  // 用户搜索结果卡片组件
  @Builder
  UserCard(user: UserInfo) {
    Row() {
      AvatarComponent({
        user: {
          avatar: user.avatar,
          name: user.name
        },
        avatarSize: 60
      })

      Column() {
        Text(user.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_MAIN)
        Text(user.branch)
          .fontSize(14)
          .fontColor(TEXT_SECOND)
          .margin({ top: 4 })
      }
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)

      Blank()

      Text('>')
        .fontSize(16)
        .fontColor(TEXT_GRAY)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(12)
    .shadow({
      radius: 6,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/UserDetailPage',
        params: { userId: user.id, userName: user.name, userAvatar: user.avatar || '' }
      });
    })
  }

  // 首页功能菜单组件
  // 首页功能菜单组件 - 优化设计
  @Builder
  MenuItem(title: string, iconUrl: Resource, onClick: () => void) {
    Column() {
      Image(iconUrl)
        .width(60)
        .height(60)
        .margin({ bottom: 10 })
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontSize(15)
        .fontColor(TEXT_MAIN)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({
      radius: 12,
      color: CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      // 添加点击动画效果
      animateTo({ duration: 100 }, () => {
        // 点击后恢复原状
      })
      onClick();
    })
  }

  build() {
    Column() {
      // ===================== 顶部固定搜索栏 =====================
      Row() {
        // 搜索框 - 增加阴影和过渡效果
        Row() {
          Image($rawfile("搜索.png"))
            .width(20)
            .height(20)
            .margin({ left: 16 })
            .opacity(0.7)
          TextInput({
            placeholder: '搜索政策、学习、活动、党员',
            text: this.searchText
          })
            .layoutWeight(1)
            .height('100%')
            .backgroundColor(Color.Transparent)
            .padding({ left: 8, right: 16 })
            .fontSize(15)
            .fontColor(TEXT_MAIN)
            .placeholderColor(TEXT_GRAY)
            .caretColor(PRIMARY_COLOR)
            .onChange((value: string) => {
              this.searchText = value;
            })
            .onSubmit(() => {
              this.search();
            })
        }
        .layoutWeight(1)
        .flexShrink(1)
        .height(46)
        .backgroundColor(CARD_BG)
        .borderRadius(24)
        .margin({ right: 12 })
        .shadow({
          radius: 8,
          color: CARD_SHADOW,
          offsetX: 0,
          offsetY: 2
        })
        .transition({ type: TransitionType.All, scale: { x: 0.98, y: 0.98 }, opacity: 0.9 })

        // 消息按钮区域
        Stack() {
          Button() {
            Image($rawfile("邮件.png"))
              .width(24)
              .height(24)
          }
          .width(48)
          .height(48)
          .flexShrink(0)
          .backgroundColor(Color.White)
          .borderRadius(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ChatListPage' });
          })
          .shadow({
            radius: 4,
            color: CARD_SHADOW,
            offsetX: 0,
            offsetY: 2
          })

          // 未读消息标记 - 优化视觉效果
          if (this.unreadCount > 0) {
            if (this.unreadCount < 10) {
              Text(this.unreadCount.toString())
                .fontSize(12)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .backgroundColor('#FF3B30')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(12)
                .position({ x: 32, y: 2 })
            } else {
              Circle()
                .width(10)
                .height(10)
                .fill('#FF3B30')
                .border({ width: 2, color: Color.White })
                .position({ x: 32, y: 4 })
            }
          }
        }
      }
      .width('100%')
      .height(72)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(Color.White)
      .shadow({
        radius: 6,
        color: CARD_SHADOW,
        offsetX: 0,
        offsetY: 4
      })
      .zIndex(1)


      // ===================== 内容主体区 =====================
      if (this.showSearchResults) {
        // --------------------- 核心修复：搜索结果页，移除不兼容API ---------------------
        Scroll() {
          Column() {
            // 1. 搜索结果标题栏，紧贴顶部
            Row() {
              Text('搜索结果')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
              Blank()
              Button('清除')
                .fontSize(15)
                .fontColor(PRIMARY_COLOR)
                .backgroundColor(Color.Transparent)
                .onClick(() => this.clearSearch())
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })

            // 2. 加载状态
            if (this.isSearching) {
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color(PRIMARY_COLOR)
                Text('正在搜索相关内容...')
                  .fontSize(14)
                  .fontColor(TEXT_GRAY)
                  .margin({ top: 12 })
              }
              .width('100%')
              .padding({ top: 10 })
            } else {
              // 3. 搜索结果列表，紧贴标题
              // 政策类
              if (this.searchResults.policies.length > 0) {
                this.SectionTitle('政策宣传')
                ForEach(this.searchResults.policies, (policy: Policy) => {
                  Column() {
                    this.ResultCard(
                      policy.imageUrl,
                      policy.title,
                      policy.content,
                      () => router.pushUrl({ url: 'pages/PolicyDetailPage', params: { policyId: policy.id } })
                    )
                  }
                  .margin({ left: 16, right: 16, bottom: 10 })
                })
              }

              // 学习资源类
              if (this.searchResults.studies.length > 0) {
                this.SectionTitle('学习园地')
                ForEach(this.searchResults.studies, (study: StudyResource) => {
                  Column() {
                    this.ResultCard(
                      study.imageUrl,
                      study.title,
                      study.content,
                      () => router.pushUrl({ url: 'pages/StudyDetailPage', params: { resourceId: study.id } })
                    )
                  }
                  .margin({ left: 16, right: 16, bottom: 10 })
                })
              }

              // 活动类
              if (this.searchResults.activities.length > 0) {
                this.SectionTitle('活动管理')
                ForEach(this.searchResults.activities, (activity: Activity) => {
                  Column() {
                    this.ResultCard(
                      activity.imageUrl,
                      activity.title,
                      activity.content,
                      () => router.pushUrl({ url: 'pages/ActivityDetailPage', params: { activityId: activity.id } })
                    )
                  }
                  .margin({ left: 16, right: 16, bottom: 10 })
                })
              }

              // 用户类
              if (this.searchResults.users.length > 0) {
                this.SectionTitle('党员通讯录')
                ForEach(this.searchResults.users, (user: UserInfo) => {
                  Column() {
                    this.UserCard(user)
                  }
                  .margin({ left: 16, right: 16, bottom: 12 })
                })
              }

              // 无结果空状态
              if (this.searchResults.policies.length === 0 &&
                this.searchResults.studies.length === 0 &&
                this.searchResults.activities.length === 0 &&
                this.searchResults.users.length === 0) {
                Column() {
                  Text('🔍')
                    .fontSize(48)
                    .margin({ bottom: 16 })
                  Text('未找到相关内容')
                    .fontSize(16)
                    .fontColor(TEXT_SECOND)
                  Text('换个关键词试试吧')
                    .fontSize(14)
                    .fontColor(TEXT_GRAY)
                    .margin({ top: 4 })
                }
                .width('100%')
                .padding({ top: 20 })
                .justifyContent(FlexAlign.Start)
              }
            }
          }
          // 核心修复：移除不兼容的API，Column宽度设为100%，高度自适应
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          // 仅保留底部安全距离
          .padding({ bottom: NAV_BAR_HEIGHT + 15 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(BG_COLOR)
        .align(Alignment.TopStart)
      } else {
        // --------------------- 首页主内容 ---------------------
        Scroll() {
          Column() {
            // 轮播图组件
            Swiper()
            {
              ForEach(this.bannerImages, (imageUrl: string) => {
                Image(imageUrl)
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Cover)
              })
            }
              .width('100%')
              .height(200)

              .autoPlay(true)
              .interval(3000)
              .indicator(true)
              .indicatorStyle({
                selectedColor: '#FFFFFF',
                color: 'rgba(255, 255, 255, 0.5)',
                size: 8
              })
              .onChange((index: number) => {
                this.currentBannerIndex = index;
              })
              .borderRadius({ topLeft:20,topRight:20,bottomLeft: 20, bottomRight: 20 })


            // 欢迎语区域 - 优化设计
            if (this.user) {
              Row() {
                // 竖线（Column实现，无任何语法报错）
                Column()
                  .width(6)
                  .height(36)
                  .backgroundColor(PRIMARY_COLOR)
                  .margin({ right: 10 })
                  // 🔥 修复报错：替换为 ItemAlign.Center（ArkTS 官方正确枚举）
                  .alignSelf(ItemAlign.Center)

                // 文字区域（左对齐）
                Column() {
                  Text(this.isAdmin() ? '欢迎，系统管理员' : this.isBranchAdmin() ? '欢迎，支部管理员' : '欢迎，党员同志')
                    .fontSize(16)
                    .fontColor(TEXT_MAIN)
                    .fontWeight(FontWeight.Medium)
                  Text('不忘初心 牢记使命')
                    .fontSize(13)
                    .fontColor(PRIMARY_COLOR)
                    .opacity(0.9)
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start) // 文字左对齐
              }
              // 🎯 以下所有卡片样式 100% 原样保留，无任何修改
              .width('93%')
              .margin({ top: 20 })
              .padding(20)
              .borderRadius(16)
              .backgroundColor(Color.White)
              .shadow({
                radius: 8,
                color: CARD_SHADOW,
                offsetX: 0,
                offsetY: 4
              })
            }

            // 功能菜单 - 优化布局和视觉效果
            Grid() {
              GridItem() {
                this.MenuItem(
                  '党费缴纳',
                  $rawfile("党费管理.png"),
                  () => router.pushUrl({ url: 'pages/DuesPaymentPage' })
                )
              }

              GridItem() {
                this.MenuItem(
                  '通讯录',
                  $rawfile("通讯录.png"),
                  () => router.pushUrl({ url: 'pages/AddressBookPage' })
                )
              }

              GridItem() {
                Stack() {
                  this.MenuItem(
                    '支部管理',
                    $rawfile("我的支部.png"),
                    () => router.pushUrl({ url: 'pages/BranchManagementPage' })
                  )

                  // 支部未读消息标记 - 优化视觉效果
                  if (this.branchUnreadCount > 0) {
                    if (this.branchUnreadCount < 10) {
                      Text(this.branchUnreadCount.toString())
                        .fontSize(12)
                        .fontColor('#FFFFFF')
                        .fontWeight(FontWeight.Bold)
                        .backgroundColor('#FF3B30')
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .borderRadius(12)
                        .position({ x: '80%', y: '10%' })
                    } else {
                      Circle()
                        .width(10)
                        .height(10)
                        .fill('#FF3B30')
                        .border({ width: 2, color: Color.White })
                        .position({ x: '85%', y: '15%' })
                    }
                  }
                }
              }

              if (this.canManage()) {
                GridItem() {
                  this.MenuItem(
                    '人员管理',
                    $rawfile("人员管理.png"),
                    () => router.pushUrl({ url: 'pages/PersonnelManagementPage' })
                  )
                }
              }
            }
            .width('93%')
            .height(260)
            .columnsTemplate('1fr 1fr')
            .rowsTemplate('1fr 1fr')
            .columnsGap(20)
            .rowsGap(20)
            .margin({ top: 20 })

            // 最新动态标题 - 增加装饰元素
            Row() {
              Column() {
                Blank()
                Rect()
                  .width(24)
                  .height(3)
                  .fill(PRIMARY_COLOR)
                  .borderRadius(2)
                  .margin({ bottom: 8 })
                Blank()
              }
              .height(20)

              Text('最新动态')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
                .margin({ left: 8 })

              Blank()

              Text('更多')
                .fontSize(14)
                .fontColor(PRIMARY_COLOR)
                .onClick(() => {
                  // 跳转到更多动态页面
                })
            }
            .width('93%')
            .margin({ top: 30, bottom: 12 })

            // 最新动态列表 - 优化卡片设计
            if (this.isLoading) {
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color(PRIMARY_COLOR)
              }
              .width('100%')
              .height(200)
              .justifyContent(FlexAlign.Center)
            } else {
              Column() {
                ForEach(this.policies, (policy: Policy) => {
                  Row() {
                    Image(policy.imageUrl)
                      .width(100)
                      .height(70)
                      .borderRadius(8)
                      .objectFit(ImageFit.Cover)
                      .backgroundColor('#F0F0F0')
                      .margin({ right: 15 })
                    Column() {
                      Text(policy.title)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                      Blank()
                      Row() {
                        Text('政策')
                          .fontSize(12)
                          .fontColor(PRIMARY_COLOR)
                          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          .backgroundColor('#FFEBEE')
                          .borderRadius(4)
                        Text(policy.publishDate)
                          .fontSize(12)
                          .fontColor(TEXT_GRAY)
                          .margin({ left: 10 })
                      }
                      .margin({ top: 8 })
                      .width('100%')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding(15)
                  .margin({ bottom: 12 })
                  .borderRadius(16)
                  .backgroundColor(Color.White)
                  .shadow({
                    radius: 8,
                    color: CARD_SHADOW,
                    offsetX: 0,
                    offsetY: 2
                  })
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/PolicyDetailPage', params: { policyId: policy.id } });
                  })
                })
              }
              .width('93%')
            }
          }
          .padding({ bottom: NAV_BAR_HEIGHT + 15 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(BG_COLOR)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
  }
}