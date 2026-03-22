import router from '@ohos.router';
import { UserService, ApiResponse, User } from '../models/UserModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct UserDetailPage {
  @State user: User | null = null;
  @State isLoading: boolean = false;
  private userService: UserService = new UserService();
  private userId: string = '';

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

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .backgroundColor('transparent')
          .fontColor('#D32F2F')
          .onClick(() => router.back());

        Text('个人信息')
          .fontSize(18)
          .fontWeight(700)
          .flexGrow(1)
          .textAlign(TextAlign.Center);

        Text('')
          .width(50);
      }
      .width('100%')
      .height(56)
      .backgroundColor('#fff');

      // 用户信息
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
        }
        .width('100%')
        .height('80%')
        .justifyContent(1);
      } else if (this.user) {
        Column() {
          // 头像
          if (this.user.avatar) {
            Image(this.user.avatar)
              .width(120)
              .height(120)
              .borderRadius(60)
              .margin({ top: 40, bottom: 20 });
          } else {
            Text(this.user.name.charAt(0))
              .width(120)
              .height(120)
              .borderRadius(60)
              .backgroundColor('#D32F2F')
              .fontColor('#fff')
              .fontSize(48)
              .textAlign(TextAlign.Center)
              .margin({ top: 40, bottom: 20 });
          }

          // 姓名
          Text(this.user.name)
            .fontSize(24)
            .fontWeight(700)
            .margin({ bottom: 8 });

          // 角色
          Text(this.user.role === 'admin' ? '系统管理员' : this.user.role === 'branch_admin' ? '支部管理员' : '党员同志')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ bottom: 32 });

          // 详细信息
          Column() {
            Row() {
              Text('党员编号')
                .fontSize(16)
                .fontColor('#666666')
                .width(100);
              Text(this.user.partyId || '无')
                .fontSize(16)
                .flexGrow(1)
                .textAlign(TextAlign.End);
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 });

            Divider()
              .height(1)
              .color('#F0F0F0');

            Row() {
              Text('所在支部')
                .fontSize(16)
                .fontColor('#666666')
                .width(100);
              Text(this.user.branch || '无')
                .fontSize(16)
                .flexGrow(1)
                .textAlign(TextAlign.End);
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 });

            Divider()
              .height(1)
              .color('#F0F0F0');

            Row() {
              Text('手机号')
                .fontSize(16)
                .fontColor('#666666')
                .width(100);
              Text(this.user.phone || '无')
                .fontSize(16)
                .flexGrow(1)
                .textAlign(TextAlign.End);
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 });

            Divider()
              .height(1)
              .color('#F0F0F0');

            Row() {
              Text('邮箱')
                .fontSize(16)
                .fontColor('#666666')
                .width(100);
              Text(this.user.email || '无')
                .fontSize(16)
                .flexGrow(1)
                .textAlign(TextAlign.End);
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 });

            Divider()
              .height(1)
              .color('#F0F0F0');

            Row() {
              Text('入党日期')
                .fontSize(16)
                .fontColor('#666666')
                .width(100);
              Text(this.user.joinDate || '无')
                .fontSize(16)
                .flexGrow(1)
                .textAlign(TextAlign.End);
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 });

            Divider()
              .height(1)
              .color('#F0F0F0');
          }
          .width('100%')
          .backgroundColor('#fff');

          // 聊天按钮
          Button('发起聊天')
            .width('80%')
            .height(50)
            .backgroundColor('#D32F2F')
            .fontColor('#fff')
            .borderRadius(25)
            .margin({ top: 40 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ChatPage',
                params: { userId: this.userId, userName: this.user?.name, userAvatar: this.user?.avatar }
              });
            });
        }
        .width('100%')
        .flexGrow(1);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }


}
