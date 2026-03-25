import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import { UserService, UserInfo, ApiResponse, DuesStats, DuesPayment, LoginLog, UpdateInfo } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { AvatarComponent } from '../components/AvatarComponent';
import { emitter } from '@kit.BasicServicesKit';

// 全局设计常量
const PRIMARY_COLOR: string = '#D32F2F';
const BG_GRAY: string = '#F5F7FA';
const CARD_BG: string = '#FFFFFF';
const TEXT_PRIMARY: string = '#2D3436';
const TEXT_SECONDARY: string = '#636E72';
const TEXT_GRAY: string = '#B2BEC3';
const SUCCESS_COLOR: string = '#00B894';

@Component
export struct ProfilePage {
  @State user: UserInfo | null = null;
  @State isLoading: boolean = false;
  @State duesStats: DuesStats | null = null;
  @State isLoadingDues: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadUserInfo();
    await this.loadDuesStats();
    emitter.on("refreshProfile", async (): Promise<void> => {
      console.info("✅ 从个人信息编辑页返回，刷新个人信息");
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

  // 业务逻辑方法
  async loadDuesStats(): Promise<void> {
    this.isLoadingDues = true;
    try {
      const userService: UserService = new UserService();
      const response: ApiResponse<DuesStats> = await userService.getDuesStats();
      if (response.code === 200 && response.data) {
        this.duesStats = response.data;
      }
    } catch (error) {
      console.error('加载党费统计失败:', error);
      promptAction.showToast({ message: '加载党费统计失败', duration: 2000 });
    } finally {
      this.isLoadingDues = false;
    }
  }

  async loadUserInfo(): Promise<void> {
    this.isLoading = true;
    try {
      const cachedUser: UserInfo | null = StorageService.getItem<UserInfo>('user');
      if (cachedUser) {
        this.user = cachedUser;
      }
      const response: ApiResponse<UserInfo> = await new UserService().getCurrentUser();
      if (response.code === 200 && response.data) {
        this.user = response.data;
        await StorageService.setItem('user', response.data);
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

  async navigateToPersonalInfo(): Promise<void> {
    try {
      const userService: UserService = new UserService();
      const response: ApiResponse<UserInfo> = await userService.getProfile();
      if (response.code === 200 && response.data) {
        router.pushUrl({ url: 'pages/PersonalInfoEditPage' });
      }
    } catch (error) {
      console.error('获取个人信息失败:', error);
      promptAction.showToast({ message: '获取个人信息失败', duration: 2000 });
    }
  }

  async navigateToPasswordChange(): Promise<void> {
    try {
      router.pushUrl({ url: 'pages/PasswordChangePage' });
    } catch (error) {
      console.error('导航失败:', error);
      promptAction.showToast({ message: '导航失败', duration: 2000 });
    }
  }

  async navigateToLoginLogs(): Promise<void> {
    try {
      router.pushUrl({ url: 'pages/LoginLogsPage' });
    } catch (error) {
      console.error('导航失败:', error);
      promptAction.showToast({ message: '导航失败', duration: 2000 });
    }
  }

  async navigateToDuesPayment(): Promise<void> {
    try {
      if (this.duesStats) {
        router.pushUrl({ url: 'pages/DuesPaymentPage' });
      }
    } catch (error) {
      console.error('导航失败:', error);
      promptAction.showToast({ message: '导航失败', duration: 2000 });
    }
  }

  async clearCache(): Promise<void> {
    try {
      const userService: UserService = new UserService();
      const response: ApiResponse<boolean> = await userService.clearCache();
      if (response.code === 200 && response.data) {
        promptAction.showToast({ message: '缓存已清理', duration: 2000 });
      }
    } catch (error) {
      console.error('清理缓存失败:', error);
      promptAction.showToast({ message: '清理缓存失败', duration: 2000 });
    }
  }

  async checkForUpdates(): Promise<void> {
    try {
      const userService: UserService = new UserService();
      const response: ApiResponse<UpdateInfo> = await userService.checkUpdate();
      if (response.code === 200 && response.data) {
        promptAction.showToast({
          message: response.data.isLatest ? '当前已是最新版本' : '有新版本可用',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('检查更新失败:', error);
      promptAction.showToast({ message: '检查更新失败', duration: 2000 });
    }
  }

  // 通用列表项
  @Builder
  MenuItem(title: string, targetPage: string): void {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor(TEXT_GRAY)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .onClick((): void => {
      if (targetPage) {
        router.pushUrl({ url: targetPage });
      }
    })
  }

  // 通用列表项（自定义点击）
  @Builder
  MenuItemCustom(title: string, callback: () => void): void {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor(TEXT_GRAY)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .onClick(callback)
  }

  build(): void {
    Scroll() {
      Column() {
        // 1. 顶部渐变头部
        Column() {
          Stack() {
            if (this.user) {
              AvatarComponent({
                user: { avatar: this.user.avatar, name: this.user.name },
                avatarSize: 88
              })
            } else {
              Text('党')
                .width(88)
                .height(88)
                .borderRadius(44)
                .backgroundColor('#FFFFFF')
                .fontColor(PRIMARY_COLOR)
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center)
            }
          }
          .width(96)
          .height(96)
          .shadow({ radius: 12, color: 'rgba(211, 47, 47, 0.2)', offsetY: 6 })
          .margin({ bottom: 16 })

          Text(this.user?.name || '党员同志')
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 6 })

          Row() {
            Text(this.user?.role === 'admin' ? '系统管理员' : this.user?.role === 'branch_admin' ? '支部管理员' : '普通党员')
              .fontSize(12)
              .fontColor(PRIMARY_COLOR)
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          }
          .backgroundColor('#FFFFFF')
          .borderRadius(100)
        }
        .width('100%')
        .padding({ top: 48, bottom: 32 })
        .linearGradient({ angle: 135, colors: [['#C62828', 0], ['#E53935', 1]] })

        // 2. 党费卡片
        Column() {
          Row() {
            Text('党费概览')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(TEXT_PRIMARY)
            Blank()
            Text('立即缴纳 >')
              .fontSize(12)
              .fontColor(PRIMARY_COLOR)
              .onClick((): void => { this.navigateToDuesPayment(); })
          }
          .width('100%')
          .margin({ bottom: 20 })

          Row() {
            Column() {
              Text('待缴金额')
                .fontSize(12)
                .fontColor(TEXT_SECONDARY)
                .margin({ bottom: 6 })
              Text(`¥${this.duesStats?.pendingAmount || 0}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(PRIMARY_COLOR)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column()
              .width(1)
              .height(40)
              .backgroundColor(BG_GRAY)

            Column() {
              Text('已缴金额')
                .fontSize(12)
                .fontColor(TEXT_SECONDARY)
                .margin({ bottom: 6 })
              Text(`¥${this.duesStats?.paidAmount || 0}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(SUCCESS_COLOR)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
        }
        .width('100%')
        .padding(20)
        .backgroundColor(CARD_BG)
        .borderRadius(16)
        .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.06)', offsetY: 4 })
        .margin({ left: 16, right: 16, top: -20, bottom: 16 })

        // 3. 核心服务
        Column() {
          Text('核心服务')
            .fontSize(12)
            .fontColor(TEXT_GRAY)
            .margin({ bottom: 8, left: 4 })
          Column() {
            this.MenuItemCustom('个人信息', (): void => { this.navigateToPersonalInfo(); })
            Divider().color(BG_GRAY)
            this.MenuItemCustom('党费缴纳', (): void => { this.navigateToDuesPayment(); })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor(CARD_BG)
          .borderRadius(14)
          .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
        }
        .width('100%')
        .margin({ left: 16, right: 16, bottom: 16 })

        // 4. 账号安全
        Column() {
          Text('账号安全')
            .fontSize(12)
            .fontColor(TEXT_GRAY)
            .margin({ bottom: 8, left: 4 })
          Column() {
            this.MenuItem('密码修改', 'pages/PasswordChangePage')
            Divider().color(BG_GRAY)
            this.MenuItem('登录日志', 'pages/LoginLogsPage')
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor(CARD_BG)
          .borderRadius(14)
          .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
        }
        .width('100%')
        .margin({ left: 16, right: 16, bottom: 16 })

        // 5. 系统设置
        Column() {
          Text('系统设置')
            .fontSize(12)
            .fontColor(TEXT_GRAY)
            .margin({ bottom: 8, left: 4 })
          Column() {
            this.MenuItemCustom('消息提醒', (): void => {
              promptAction.showToast({ message: '消息设置功能开发中', duration: 2000 });
            })
            Divider().color(BG_GRAY)
            this.MenuItemCustom('清理缓存', (): void => { this.clearCache(); })
            Divider().color(BG_GRAY)
            this.MenuItemCustom('版本更新', (): void => { this.checkForUpdates(); })
            Divider().color(BG_GRAY)
            this.MenuItemCustom('关于我们', (): void => {
              promptAction.showToast({ message: '关于我们功能开发中', duration: 2000 });
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor(CARD_BG)
          .borderRadius(14)
          .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
        }
        .width('100%')
        .margin({ left: 16, right: 16, bottom: 16 })

        // 6. 管理功能
        if (this.user?.role === 'admin' || this.user?.role === 'branch_admin') {
          Column() {
            Text('管理后台')
              .fontSize(12)
              .fontColor(TEXT_GRAY)
              .margin({ bottom: 8, left: 4 })
            Column() {
              this.MenuItemCustom('用户管理', (): void => {
                promptAction.showToast({ message: '用户管理功能开发中', duration: 2000 });
              })
              Divider().color(BG_GRAY)
              this.MenuItemCustom('数据统计', (): void => {
                promptAction.showToast({ message: '数据统计功能开发中', duration: 2000 });
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .backgroundColor(CARD_BG)
            .borderRadius(14)
            .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
          }
          .width('100%')
          .margin({ left: 16, right: 16, bottom: 16 })
        }

        // 7. 退出登录
        Button('退出登录')
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor(CARD_BG)
          .borderRadius(14)
          .margin({ left: 16, right: 16, top: 8, bottom: 40 })
          .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
          .onClick((): void => { this.logout(); })

        Text('版本 1.0.0')
          .fontSize(12)
          .fontColor(TEXT_GRAY)
          .margin({ bottom: 30 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_GRAY)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}