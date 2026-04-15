import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import { UserService, UserInfo, ApiResponse, DuesStats } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { AvatarComponent } from '../components/AvatarComponent';
import { emitter } from '@kit.BasicServicesKit';

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

// 功能菜单项
interface MenuItemData {
  icon: Resource;    // 图片资源
  title: string;
  route?: string;
  action?: () => void;
  badge?: string;
  size?: number;
}

@Component
export struct ProfilePage {
  @State user: UserInfo | null = null;
  @State duesStats: DuesStats | null = null;
  @State isLoading: boolean = false;

  // 第一排功能（4个）- 路由会根据用户角色动态设置
  @State firstRowItems: MenuItemData[] = [
    { icon: $rawfile('学习统计.png'), title: '学习统计', route: 'pages/StudyStatsPage' },
    { icon: $rawfile('我的收藏.png'), title: '我的收藏', route: 'pages/MyFavoritesPage' },
    { icon: $rawfile('党费缴纳.png'), title: '党费缴纳', route: 'pages/DuesPaymentPage' },
    { icon: $rawfile('日志管理.png'), title: '登录日志', route: 'pages/LoginLogsPage' },
  ];

  // 第二排功能（4个）
  private secondRowItems: MenuItemData[] = [
    { icon: $rawfile('个人信息.png'), title: '个人信息', route: 'pages/PersonalInfoEditPage' },
    { icon: $rawfile('密码修改.png'), title: '密码修改', route: 'pages/PasswordChangePage' },
    { icon: $rawfile('消息提醒.png'), title: '消息提醒', action: (): void => promptAction.showToast({ message: '功能开发中', duration: 2000 }) },
    { icon: $rawfile('关于我们.png'), title: '关于我们', action: (): void => promptAction.showToast({ message: '功能开发中', duration: 2000 }) },
  ];

  async aboutToAppear(): Promise<void> {
    await this.loadUserInfo();
    await this.loadDuesStats();
    emitter.on("refreshProfile", async (): Promise<void> => {
      await this.loadUserInfo();
      await this.loadDuesStats();
    });
  }

  aboutToDisappear(): void {
    emitter.off("refreshProfile");
  }

  async onPageShow(): Promise<void> {
    await this.loadUserInfo();
    await this.loadDuesStats();
  }

  async loadDuesStats(): Promise<void> {
    try {
      const userService: UserService = new UserService();
      const response: ApiResponse<DuesStats> = await userService.getDuesStats();
      if (response.code === 200 && response.data) {
        this.duesStats = response.data;
      }
    } catch (error) {
      console.error('加载党费统计失败:', error);
    }
  }

  // 根据用户角色更新学习统计的跳转路由
  updateStudyStatsRoute(role: string): void {
    if (role === 'branch_admin') {
      // 支书 -> 支部学习统计页面
      this.firstRowItems = [
        { icon: $rawfile('学习统计.png'), title: '学习统计', route: 'pages/BranchStatsPage' },
        { icon: $rawfile('我的收藏.png'), title: '我的收藏', route: 'pages/MyFavoritesPage' },
        { icon: $rawfile('党费缴纳.png'), title: '党费缴纳', route: 'pages/DuesPaymentPage' },
        { icon: $rawfile('日志管理.png'), title: '登录日志', route: 'pages/LoginLogsPage' },
      ];
    } else {
      // 其他用户 -> 个人学习统计页面
      this.firstRowItems = [
        { icon: $rawfile('学习统计.png'), title: '学习统计', route: 'pages/StudyStatsPage' },
        { icon: $rawfile('我的收藏.png'), title: '我的收藏', route: 'pages/MyFavoritesPage' },
        { icon: $rawfile('党费缴纳.png'), title: '党费缴纳', route: 'pages/DuesPaymentPage' },
        { icon: $rawfile('日志管理.png'), title: '登录日志', route: 'pages/LoginLogsPage' },
      ];
    }
  }

  async loadUserInfo(): Promise<void> {
    this.isLoading = true;
    try {
      const cachedUser: UserInfo | null = StorageService.getItem<UserInfo>('user');
      if (cachedUser) {
        this.user = cachedUser;
        // 根据用户角色设置学习统计路由
        this.updateStudyStatsRoute(cachedUser.role);
      }
      const response: ApiResponse<UserInfo> = await new UserService().getCurrentUser();
      if (response.code === 200 && response.data) {
        this.user = response.data;
        await StorageService.setItem('user', response.data);
        // 根据用户角色设置学习统计路由
        this.updateStudyStatsRoute(response.data.role);
      }
    } catch (error) {
      console.error('获取用户信息失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async logout(): Promise<void> {
    await StorageService.removeItem('user');
    await StorageService.removeItem('token');
    promptAction.showToast({ message: '已退出登录', duration: 2000 });
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  async clearCache(): Promise<void> {
    try {
      const userService: UserService = new UserService();
      const response: ApiResponse<boolean> = await userService.clearCache();
      if (response.code === 200 && response.data) {
        promptAction.showToast({ message: '缓存已清理', duration: 2000 });
      }
    } catch (error) {
      promptAction.showToast({ message: '清理缓存失败', duration: 2000 });
    }
  }

  // 网格功能项
  @Builder
  GridItem(item: MenuItemData): void {
    Column() {
      Image(item.icon)
        .width(36)
        .height(36)
        .margin({ bottom: 10 });
      Text(item.title)
        .fontSize(13)
        .fontColor('#1F1F1F');
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (item.route) {
        router.pushUrl({ url: item.route });
      } else if (item.action) {
        item.action();
      }
    });
  }

  // 列表功能项
  @Builder
  ListItem(icon: Resource, title: string, route?: string, action?: () => void): void {
    Row() {
      Image(icon)
        .width(22)
        .height(22)
        .margin({ right: 14 });
      Text(title)
        .fontSize(15)
        .fontColor('#1F1F1F');
      Blank();
      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC');
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 15, bottom: 15 })
    .onClick(() => {
      if (route) {
        router.pushUrl({ url: route });
      } else if (action) {
        action();
      }
    });
  }

  build(): void {
    Column() {
      // ==================== 顶部背景区域 ====================
      Stack() {
        // 背景图
        Column() {}.width('100%').height('100%')
          .backgroundImage($rawfile('长城-粒子.jpg'))
          .backgroundImageSize({ width: '100%', height: '100%' });

        // 渐变遮罩
        Column() {}.width('100%').height('100%')
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['rgba(0,0,0,0.1)', 0], ['rgba(181,31,46,0.7)', 0.7], ['rgba(181,31,46,0.95)', 1]]
          });

        // 用户信息区
        Column() {
          // 头像
          Stack() {
            if (this.user) {
              AvatarComponent({ user: { avatar: this.user.avatar, name: this.user.name }, avatarSize: 72 });
            } else {
              Text('党').width(72).height(72).borderRadius(36).backgroundColor('#FFFFFF')
                .fontColor('#B51F2E').fontSize(32).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center);
            }
          }
          .width(76).height(76).borderRadius(38).border({ width: 3, color: '#C9A45C' })
            .shadow({ radius: 16, color: 'rgba(0,0,0,0.3)', offsetY: 6 })
            .margin({ bottom: 12 });

          // 姓名
          Text(this.user?.name || '党员同志')
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 });

          // 角色和党龄
          Row({ space: 10 }) {
            Row() {
              Text(this.user?.role === 'admin' ? '系统管理员' : this.user?.role === 'branch_admin' ? '支部管理员' : '普通党员')
                .fontSize(11)
                .fontColor('#B51F2E')
                .fontWeight(FontWeight.Medium);
            }
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12);

            Text('党龄 3 年')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.85)');
          }
        }
        .padding({ top: 50, bottom: 40 })
        .width('100%');
      }
      .width('100%')
      .height(240);

      // ==================== 党费统计卡片（与背景重叠） ====================
      Row({ space: 0 }) {
        // 待缴
        Column() {
          Text('¥' + (this.duesStats?.pendingAmount || 0))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#B51F2E')
            .margin({ bottom: 6 });
          Text('待缴金额')
            .fontSize(12)
            .fontColor('#666666');
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .padding({ top: 20, bottom: 20 })
        .onClick(() => router.pushUrl({ url: 'pages/DuesPaymentPage' }));

        // 分割线
        Column()
          .width(1)
          .height(40)
          .backgroundColor('#EFE7DB');

        // 已缴
        Column() {
          Text('¥' + (this.duesStats?.paidAmount || 0))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E7D32')
            .margin({ bottom: 6 });
          Text('已缴金额')
            .fontSize(12)
            .fontColor('#666666');
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .padding({ top: 20, bottom: 20 })
        .onClick(() => router.pushUrl({ url: 'pages/DuesPaymentPage' }));

        // 分割线

      }
      .width('100%')
      .margin({ left: 16, right: 16, top: -30 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 });

      // ==================== 功能网格区 ====================
      Scroll() {
        Column({ space: 12 }) {
          // 第一排功能（4列）
          Grid() {
            ForEach(this.firstRowItems, (item: MenuItemData) => {
              GridItem() {
                this.GridItem(item);
              }
            }, (item: MenuItemData) => item.title);
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .columnsGap(0)
          .rowsGap(0)
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 16 });

          // 第二排功能（4列）
          Grid() {
            ForEach(this.secondRowItems, (item: MenuItemData) => {
              GridItem() {
                this.GridItem(item);
              }
            }, (item: MenuItemData) => item.title);
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .columnsGap(0)
          .rowsGap(0)
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12);

          // 更多设置列表
          Column() {
            Text('更多设置').fontSize(13).fontColor('#999999').margin({ bottom: 8, left: 4 });
            Column() {
              this.ListItem($rawfile('清理缓存.png'), '清理缓存', undefined, (): void => { this.clearCache(); });
              Divider().color('#EFE7DB').margin({ left: 52 });
              this.ListItem($rawfile('版本更新.png'), '版本更新', undefined, (): void => promptAction.showToast({ message: '当前已是最新版本', duration: 2000 }));
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(12);
          }
          .width('100%');

          // 退出登录按钮
          Text('退出登录')
            .width('100%')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .padding({ top: 16, bottom: 16 })
            .backgroundColor('#B51F2E')
            .borderRadius(12)
            .margin({ top: 8 })
            .onClick(() => this.logout());

          // 底部版本
          Text('党建管理系统 v1.0.0')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 20, bottom: 30 });
        }
        .width('100%')
        .padding({ left: 16, right: 16 });
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F7F4EF')
      .scrollBar(BarState.Off);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }
}