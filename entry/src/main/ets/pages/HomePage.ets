import { UserInfo, UserService } from '../models/UserModel';
import { Policy, PolicyService } from '../models/PolicyModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { StudyResource, StudyService } from '../models/StudyModel';
import { Activity, ActivityService } from '../models/ActivityModel';
import { ChatService } from '../models/ChatModel';
import { emitter } from '@kit.BasicServicesKit';
import { AvatarComponent } from '../components/AvatarComponent';

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

const NAV_BAR_HEIGHT: number = 64;

interface SearchResults {
  policies: Policy[];
  studies: StudyResource[];
  activities: Activity[];
  users: UserInfo[];
}

interface ExpandedSections {
  policies: boolean;
  studies: boolean;
  activities: boolean;
  users: boolean;
}

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
  @State expandedSections: ExpandedSections = {
    policies: true,
    studies: true,
    activities: true,
    users: true
  };

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

  // ── 生命周期 ───────────────────────────────────────────

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadLatestPolicies();
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

  async onPageShow() {
    console.info('HomePage: 页面显示，刷新未读消息数');
    await this.loadUnreadCount();
  }

  aboutToDisappear() {
    emitter.off("refreshUnread");
    emitter.off("refreshBranchUnread");
  }

  // ── 数据加载 ───────────────────────────────────────────

  async loadUnreadCount() {
    try {
      const count = await this.chatService.getUnreadCount();
      this.unreadCount = count;
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
      promptAction.showToast({ message: '加载最新动态失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  // ── 搜索 ───────────────────────────────────────────────

  async search() {
    const keyword = this.searchText.trim();
    if (!keyword) return;

    this.isSearching = true;
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.showSearchResults = true;
    });

    try {
      const responses = await Promise.all([
        this.policyService.getPolicies(),
        this.studyService.getResources(),
        this.activityService.getActivities(),
        this.userService.getBranchMembers()
      ]);

      const results: SearchResults = {
        policies: responses[0].code === 200 && responses[0].data
          ? responses[0].data.filter((p: Policy) => p.title.includes(keyword) || p.content.includes(keyword))
          : [],
        studies: responses[1].code === 200 && responses[1].data
          ? responses[1].data.filter((s: StudyResource) => s.title.includes(keyword) || s.content.includes(keyword))
          : [],
        activities: responses[2].code === 200 && responses[2].data
          ? responses[2].data.filter((a: Activity) => a.title.includes(keyword) || a.content.includes(keyword))
          : [],
        users: responses[3].code === 200 && responses[3].data
          ? responses[3].data.filter((u: UserInfo) => u.name.includes(keyword) || u.branch.includes(keyword))
          : []
      };
      this.searchResults = results;
    } catch (error) {
      console.error('搜索失败:', error);
      promptAction.showToast({ message: '搜索失败', duration: 2000 });
    } finally {
      this.isSearching = false;
    }
  }

  clearSearch() {
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.showSearchResults = false;
    });
    this.searchText = '';
  }

  // ── 权限判断 ───────────────────────────────────────────

  isAdmin(): boolean {
    return this.user?.role === 'admin';
  }

  isBranchAdmin(): boolean {
    return this.user?.role === 'branch_admin';
  }

  canManage(): boolean {
    return this.isAdmin() || this.isBranchAdmin();
  }

  // ── 未读数气泡 ─────────────────────────────────────────

  @Builder
  UnreadBadge(count: number) {
    if (count > 0 && count < 10) {
      Text(count.toString())
        .fontSize(10)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#D83A34')
        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
        .borderRadius(10)
    } else if (count >= 10) {
      Circle()
        .width(8)
        .height(8)
        .fill('#D83A34')
        .border({ width: 1.5, color: '#FFFFFF' })
    }
  }

  // ── 搜索结果卡片 ───────────────────────────────────────

  @Builder
  ResultCard(imgUrl: string, title: string, desc: string, onClick: () => void) {
    Row() {
      Image(imgUrl)
        .width(68)
        .height(68)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#EFE7DB')

      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Blank()

        Text(desc.length > 45 ? desc.substring(0, 45) + '...' : desc)
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .onClick(onClick)
  }

  // ── 用户卡片 ───────────────────────────────────────────

  @Builder
  UserCard(user: UserInfo) {
    Row() {
      AvatarComponent({
        user: { avatar: user.avatar, name: user.name },
        avatarSize: 56
      })

      Column() {
        Text(user.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
        Text(user.branch)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 3 })
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#C9A45C')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/UserDetailPage',
        params: { userId: user.id, userName: user.name, userAvatar: user.avatar || '' }
      });
    })
  }

  // ── 功能菜单项 ─────────────────────────────────────────

  @Builder
  MenuItem(title: string, iconUrl: Resource, onClick: () => void) {
    Column() {
      // 图标区域 - 占满上半部分
      Row() {
        Image(iconUrl)
          .width(44)
          .height(44)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FDF9F3')
      .borderRadius({ topLeft: 16, topRight: 16 })

      // 文字区域 - 底部固定
      Row() {
        Text(title)
          .fontSize(14)
          .fontColor('#1F1F1F')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(40)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 16, bottomRight: 16 })
      .border({ width: { top: 1 }, color: { top: '#F0E6D3' } })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 6, color: '#00000006', offsetX: 0, offsetY: 3 })
    .onClick(onClick)
  }

  // ── 搜索结果页 ─────────────────────────────────────────

  @Builder
  SearchResultsView() {
    Scroll() {
      Column() {
        // 搜索结果标题栏
        Row() {
          Column() {
            Text(`"${this.searchText}"`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 2 })
            Text('搜索结果')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F1F1F')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Row() {
            Text('清除')
              .fontSize(14)
              .fontColor('#B51F2E')
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#FFF1F1')
          .borderRadius(16)
          .onClick(() => this.clearSearch())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        if (this.isSearching) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color('#B51F2E')
            Text('正在搜索...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 10 })
          }
          .width('100%')
          .padding({ top: 40 })
          .justifyContent(FlexAlign.Center)
        } else {
          // 政策类
          if (this.searchResults.policies.length > 0) {
            Row() {
              Text().width(3).height(14).borderRadius(2).backgroundColor('#B51F2E')
              Text(`政策宣传（${this.searchResults.policies.length}）`).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 8 })
              Blank()
              Row() {
                Text(this.expandedSections.policies ? '收起' : '展开').fontSize(13).fontColor('#999999')
                Text('▼').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#C9A45C').margin({ left: 4, top: this.expandedSections.policies ? 0 : -4 })
                  .rotate({ angle: this.expandedSections.policies ? 0 : 90 })
                  .margin({top:0.8})
                  .animation({ duration: 300, curve: Curve.EaseInOut })
              }
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })
            .onClick(() => {
              animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
                this.expandedSections.policies = !this.expandedSections.policies;
              });
            })
            if (this.expandedSections.policies) {
              ForEach(this.searchResults.policies, (policy: Policy) => {
                Column() {
                  this.ResultCard(
                    policy.imageUrl,
                    policy.title,
                    policy.content,
                    () => router.pushUrl({ url: 'pages/PolicyDetailPage', params: { policyId: policy.id } })
                  )
                }
                .margin({ left: 16, right: 16, bottom: 8 })
              })
            }
          }

          // 学习资源类
          if (this.searchResults.studies.length > 0) {
            Row() {
              Text().width(3).height(14).borderRadius(2).backgroundColor('#B51F2E')
              Text(`学习园地（${this.searchResults.studies.length}）`).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 8 })
              Blank()
              Row() {
                Text(this.expandedSections.studies ? '收起' : '展开').fontSize(13).fontColor('#999999')
                Text('▼').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#C9A45C').margin({ left: 4, top: this.expandedSections.studies ? 0 : -4 })
                  .rotate({ angle: this.expandedSections.studies ? 0 : 90 })
                  .margin({top:0.8})
                  .animation({ duration: 300, curve: Curve.EaseInOut })
              }
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })
            .onClick(() => {
              animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
                this.expandedSections.studies = !this.expandedSections.studies;
              });
            })
            if (this.expandedSections.studies) {
              ForEach(this.searchResults.studies, (study: StudyResource) => {
                Column() {
                  this.ResultCard(
                    study.imageUrl,
                    study.title,
                    study.content,
                    () => router.pushUrl({ url: 'pages/StudyDetailPage', params: { resourceId: study.id } })
                  )
                }
                .margin({ left: 16, right: 16, bottom: 8 })
              })
            }
          }

          // 活动类
          if (this.searchResults.activities.length > 0) {
            Row() {
              Text().width(3).height(14).borderRadius(2).backgroundColor('#B51F2E')
              Text(`活动管理（${this.searchResults.activities.length}）`).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 8 })
              Blank()
              Row() {
                Text(this.expandedSections.activities ? '收起' : '展开').fontSize(13).fontColor('#999999')
                Text('▼').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#C9A45C').margin({ left: 4, top: this.expandedSections.activities ? 0 : -4 })
                  .rotate({ angle: this.expandedSections.activities ? 0 : 90})
                  .margin({top:0.8})
                  .animation({ duration: 300, curve: Curve.EaseInOut })
              }
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })
            .onClick(() => {
              animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
                this.expandedSections.activities = !this.expandedSections.activities;
              });
            })
            if (this.expandedSections.activities) {
              ForEach(this.searchResults.activities, (activity: Activity) => {
                Column() {
                  this.ResultCard(
                    activity.imageUrl,
                    activity.title,
                    activity.content,
                    () => router.pushUrl({ url: 'pages/ActivityDetailPage', params: { activityId: activity.id } })
                  )
                }
                .margin({ left: 16, right: 16, bottom: 8 })
              })
            }
          }

          // 用户类
          if (this.searchResults.users.length > 0) {
            Row() {
              Text().width(3).height(14).borderRadius(2).backgroundColor('#B51F2E')
              Text(`党员通讯录（${this.searchResults.users.length}）`).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 8 })
              Blank()
              Row() {
                Text(this.expandedSections.users ? '收起' : '展开').fontSize(13).fontColor('#999999')
                Text('▼').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#C9A45C').margin({ left: 4, top: this.expandedSections.users ? 0 : -4 })
                  .rotate({ angle: this.expandedSections.users ? 0 : 90 })
                  .margin({top:0.8})
                  .animation({ duration: 300, curve: Curve.EaseInOut })
              }
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })
            .onClick(() => {
              animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
                this.expandedSections.users = !this.expandedSections.users;
              });
            })
            if (this.expandedSections.users) {
              ForEach(this.searchResults.users, (user: UserInfo) => {
                Column() {
                  this.UserCard(user)
                }
                .margin({ left: 16, right: 16, bottom: 10 })
              })
            }
          }

          // 无结果空状态
          if (this.searchResults.policies.length === 0 &&
            this.searchResults.studies.length === 0 &&
            this.searchResults.activities.length === 0 &&
            this.searchResults.users.length === 0) {
            Column() {
              Text('未找到相关内容')
                .fontSize(16)
                .fontColor('#666666')
                .fontWeight(FontWeight.Medium)
              Text('换个关键词试试吧')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding({ top: 60 })
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Center)
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: NAV_BAR_HEIGHT + 15 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor('#F7F4EF')
    .align(Alignment.TopStart)
  }

  // ── 首页主内容 ─────────────────────────────────────────

  @Builder
  HomeContentView() {
    Scroll() {
      Column() {
        // ── 轮播图 ──────────────────────────────────────
        Swiper() {
          ForEach(this.bannerImages, (imageUrl: string) => {
            Image(imageUrl)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
          })
        }
        .width('100%')
        .height(180)
        .autoPlay(true)
        .interval(3000)
        .indicator(true)
        .indicatorStyle({
          selectedColor: '#B51F2E',
          color: 'rgba(181,31,46,0.3)',
          size: 8
        })
        .onChange((index: number) => {
          this.currentBannerIndex = index;
        })
        .borderRadius(16)
        .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })

        // ── 欢迎语区域（渐变卡片）────────────────────────
        if (this.user) {
          Row() {
            // 左侧装饰
            Column() {
              Text()
                .width(4)
                .height(40)
                .borderRadius(2)
                .backgroundColor('#C9A45C')
            }
            .margin({ right: 14 })

            Column() {
              Text(this.isAdmin() ? '系统管理员' : this.isBranchAdmin() ? '支部管理员' : '党员同志')
                .fontSize(13)
                .fontColor('#A67C2E')
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 4 })
              Text('欢迎回来')
                .fontSize(18)
                .fontColor('#1F1F1F')
                .fontWeight(FontWeight.Bold)
              Text('不忘初心 牢记使命')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 6 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // 右侧装饰图标区域
            Column() {
              Text('党')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
            .width(48)
            .height(48)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#B51F2E')
            .borderRadius(12)
          }
          .width('100%')
          .padding(18)
          .margin({ top: 16 })
          .borderRadius(16)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#EFE7DB' })
          .shadow({ radius: 6, color: '#00000008', offsetX: 0, offsetY: 3 })
        }

        // ── 功能菜单 ─────────────────────────────────────
        Column() {
          // 分区标题
          Row() {
            Text()
              .width(3)
              .height(16)
              .borderRadius(2)
              .backgroundColor('#B51F2E')

            Text('快捷功能')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F1F1F')
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ bottom: 12 })

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

                if (this.branchUnreadCount > 0) {
                  Column() {
                    this.UnreadBadge(this.branchUnreadCount)
                  }
                  .position({ x: '72%', y: '6%' })
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
          .width('100%')
          .height(200)
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
        }
        .margin({ top: 20 })

        // ── 最新动态标题 ─────────────────────────────────
        Row() {
          Text()
            .width(3)
            .height(18)
            .borderRadius(2)
            .backgroundColor('#B51F2E')

          Text('最新动态')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
            .margin({ left: 8 })

          Blank()

          Row() {
            Text('查看全部')
              .fontSize(13)
              .fontColor('#666666')
            Text('›')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#C9A45C')
              .margin({ left: 2 })
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/PolicyPage' });
          })
        }
        .width('100%')
        .margin({ top: 24, bottom: 12 })

        // ── 最新动态列表 ────────────────────────────────
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color('#B51F2E')
          }
          .width('100%')
          .height(160)
          .justifyContent(FlexAlign.Center)
        } else {
          ForEach(this.policies, (policy: Policy) => {
            Row() {
              // 左侧红色装饰条（固定高度与图片对齐）
              Column() {
                Text()
                  .width(3)
                  .height(60)
                  .borderRadius(2)
                  .backgroundColor('#B51F2E')
              }
              .margin({ right: 10 })
              .justifyContent(FlexAlign.Center)

              Image(policy.imageUrl)
                .width(84)
                .height(60)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)
                .backgroundColor('#EFE7DB')
                .flexShrink(0)
                .margin({ right: 12 })

              Column() {
                Text(policy.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1F1F1F')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')

                Blank()

                Row() {
                  Text(policy.type)
                    .fontSize(11)
                    .fontColor('#B51F2E')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .backgroundColor('#FFF1F1')
                    .borderRadius(4)
                  Text(policy.publishDate)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ left: 10 })
                }
                .margin({ top: 4 })
                .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 10, right: 12, top: 10, bottom: 10 })
            .margin({ bottom: 8 })
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#EFE7DB' })
            .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 2 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/PolicyDetailPage', params: { policyId: policy.id } });
            })
          })
        }
      }
      .padding({ left: 14, right: 14, bottom: NAV_BAR_HEIGHT + 15 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor('#F7F4EF')
  }

  // ── 主 build ────────────────────────────────────────────

  build() {
    Column() {
      // ── 顶部搜索栏 ─────────────────────────────────────
      Row() {
        // 搜索框
        Row() {
          Image($rawfile("搜索.png"))
            .width(18)
            .height(18)
            .margin({ left: 14 })
            .opacity(0.5)
          TextInput({
            placeholder: '搜索政策、学习、活动、党员',
            text: this.searchText
          })
            .layoutWeight(1)
            .height('100%')
            .backgroundColor(Color.Transparent)
            .padding({ left: 8, right: 14 })
            .fontSize(14)
            .fontColor('#1F1F1F')
            .placeholderColor('#999999')
            .caretColor('#B51F2E')
            .onChange((value: string) => {
              this.searchText = value;
            })
            .onSubmit(() => {
              this.search();
            })
        }
        .layoutWeight(1)
        .flexShrink(1)
        .height(44)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#EFE7DB' })
        .margin({ right: 10 })

        // 消息按钮
        Stack() {
          Row() {
            Image($rawfile("邮件.png"))
              .width(22)
              .height(22)
              .objectFit(ImageFit.Contain)
          }
          .width(44)
          .height(44)
          .flexShrink(0)
          .backgroundColor('#FFFFFF')
          .borderRadius(22)
          .border({ width: 1, color: '#EFE7DB' })
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ChatListPage' });
          })

          if (this.unreadCount > 0) {
            Column() {
              this.UnreadBadge(this.unreadCount)
            }
            .position({ x: 28, y: 0 })
          }
        }
      }
      .width('100%')
      .height(68)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor('#F7F4EF')
      .zIndex(1)

      // ── 内容区 ─────────────────────────────────────────
      if (this.showSearchResults) {
        this.SearchResultsView()
      } else {
        this.HomeContentView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF')
  }
}
