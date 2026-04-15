import router from '@ohos.router';
import { UserService, ApiResponse, User } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { AvatarComponent } from '../components/AvatarComponent';

@Entry
@Component
export struct UserDetailPage {
  @State user: User | null = null;
  @State isLoading: boolean = false;
  private userService: UserService = new UserService();
  private userId: string = '';

  // ===================== 颜色配置 - 庄重红金正式风 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';      // 绛红
  private readonly COLOR_PRIMARY_LIGHT = '#D83A34'; // 亮红
  private readonly COLOR_GOLD = '#C9A45C';         // 暖金
  private readonly COLOR_GOLD_DARK = '#A67C2E';    // 深金
  private readonly COLOR_BG = '#F7F4EF';           // 米白背景
  private readonly COLOR_CARD = '#FFFFFF';         // 卡片白
  private readonly COLOR_TEXT_PRIMARY = '#1F1F1F'; // 主文字
  private readonly COLOR_TEXT_SECONDARY = '#666666'; // 次要文字
  private readonly COLOR_TEXT_TERTIARY = '#999999';  // 辅助文字
  private readonly COLOR_BORDER = '#EFE7DB';       // 金色边框
  private readonly COLOR_DIVIDER = '#F0EBE3';      // 分割线

  async aboutToAppear() {
    const params: Record<string, string> | undefined = router.getParams() as Record<string, string> | undefined;
    if (params && params.userId) {
      this.userId = params.userId;
      await this.loadUserInfo();
    } else {
      promptAction.showToast({
        message: '用户ID不存在',
        duration: 2000
      });
      router.back();
    }
  }

  async loadUserInfo() {
    this.isLoading = true;
    try {
      const response = await this.userService.getUserById(this.userId);
      if (response.code === 200 && response.data) {
        this.user = response.data;
      }
    } catch (error) {
      console.error('加载用户信息失败:', error);
      promptAction.showToast({
        message: '加载用户信息失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  // ===================== 信息项构建器 =====================
  @Builder
  InfoItem(label: string, value: string) {
    Row() {
      // 左侧标签带红色装饰点
      Row() {
        Row()
          .width(6)
          .height(6)
          .backgroundColor(this.COLOR_PRIMARY)
          .borderRadius(3)
          .margin({ right: 8 });

        Text(label)
          .fontSize(14)
          .fontColor(this.COLOR_TEXT_SECONDARY);
      }

      Text(value || '无')
        .fontSize(15)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium);
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 16, bottom: 16 });
  }

  build() {
    Column() {
      // 顶部导航栏 - 绛红渐变背景
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [['#B51F2E', 0], ['#D83A34', 1]]
          });

        Row() {
          // 返回按钮
          Row() {
            Text('‹')
              .fontSize(32)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Regular)
              .onClick(() => router.back())
            .margin({bottom:6})
          }
          .width(56)
          .height('100%')
          .justifyContent(FlexAlign.Center);

          Text('个人信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .textAlign(TextAlign.Center);

          Row()
            .width(56)
            .height('100%');
        }
        .width('100%')
        .height(56)
        .padding({ top: 8 });

        Row()
          .width('100%')
          .height(1)
          .backgroundColor('rgba(201, 164, 92, 0.4)');
      }
      .width('100%')
      .height(56);

      // 用户信息
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.COLOR_PRIMARY);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.COLOR_BG);
      } else if (this.user) {
        Scroll() {
          Column() {
            // 头像区域 - 卡片化
            Column() {
              AvatarComponent({
                user: {
                  avatar: this.user.avatar,
                  name: this.user.name
                },
                avatarSize: 100
              })
                .margin({ bottom: 16 });

              // 姓名
              Text(this.user.name)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.COLOR_TEXT_PRIMARY)
                .margin({ bottom: 8 });

              // 角色标签 - 绛红背景
              Row() {
                Text(this.user.role === 'admin' ? '系统管理员' : this.user.role === 'branch_admin' ? '支部管理员' : '党员同志')
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 12, right: 12, top: 4, bottom: 4 });
              }
              .backgroundColor(this.COLOR_PRIMARY)
              .borderRadius(12);
            }
            .width('92%')
            .padding(24)
            .margin({ top: 16 })
            .backgroundColor(this.COLOR_CARD)
            .borderRadius(16)
            .border({ width: 1, color: this.COLOR_BORDER })
            .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 });

            // 详细信息卡片
            Column() {
              // 卡片标题
              Row() {
                Row()
                  .width(3)
                  .height(16)
                  .backgroundColor(this.COLOR_PRIMARY)
                  .borderRadius(1.5)
                  .margin({ right: 8 });

                Text('基本信息')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.COLOR_PRIMARY);
              }
              .width('100%')
              .margin({ bottom: 8 });

              Divider()
                .height(0.5)
                .color(this.COLOR_DIVIDER);

              // 信息项
              this.InfoItem('党员编号', this.user.partyId || '无');

              Divider()
                .height(0.5)
                .color(this.COLOR_DIVIDER);

              this.InfoItem('所在支部', this.user.branch || '无');

              Divider()
                .height(0.5)
                .color(this.COLOR_DIVIDER);

              this.InfoItem('手机号', this.user.phone || '无');

              Divider()
                .height(0.5)
                .color(this.COLOR_DIVIDER);

              this.InfoItem('邮箱', this.user.email || '无');

              Divider()
                .height(0.5)
                .color(this.COLOR_DIVIDER);

              this.InfoItem('入党日期', this.user.joinDate || '无');
            }
            .width('92%')
            .padding(20)
            .margin({ top: 12, bottom: 24 })
            .backgroundColor(this.COLOR_CARD)
            .borderRadius(16)
            .border({ width: 1, color: this.COLOR_BORDER });

            // 聊天按钮 - 绛红渐变
            Button('发起聊天')
              .width('92%')
              .height(48)
              .backgroundColor(this.COLOR_PRIMARY)
              .fontColor('#FFFFFF')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .borderRadius(24)
              .margin({ bottom: 32 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/ChatPage',
                  params: { userId: this.userId, userName: this.user?.name, userAvatar: this.user?.avatar }
                });
              });
          }
          .width('100%')
          .padding({ bottom: 16 });
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.COLOR_BG);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.COLOR_BG);
  }
}
