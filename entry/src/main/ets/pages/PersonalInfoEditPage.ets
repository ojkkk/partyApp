import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import { UserService, ApiResponse, User } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

// 设计系统常量
const PRIMARY_COLOR: string = '#D32F2F'; // 柔和蓝作为主色
const BG_GRAY: string = '#F8FAFC';
const CARD_BG: string = '#FFFFFF';
const TEXT_PRIMARY: string = '#1E293B';
const TEXT_SECONDARY: string = '#64748B';
const TEXT_HINT: string = '#94A3B8';
const BORDER_COLOR: string = '#E2E8F0';
const SHADOW_LOW: string = 'rgba(0, 0, 0, 0.05)';
const SHADOW_MEDIUM: string = 'rgba(0, 0, 0, 0.1)';

// 美化后的URL输入弹窗
@CustomDialog
struct AvatarUrlInputDialog {
  @State inputUrl: string = '';
  controller: CustomDialogController = new CustomDialogController({
    builder: () => {},
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
    isModal: true,
  });

  onConfirm: (url: string) => void = (url: string) => {};

  build(): void {
    Column() {
      Text('设置头像地址')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)
        .margin({ bottom: 20 });

      TextInput({ placeholder: '请输入图片网络地址 (URL)', text: this.inputUrl })
        .width('100%')
        .height(52)
        .borderRadius(12)
        .backgroundColor(BG_GRAY)
        .padding({ left: 16, right: 16 })
        .onChange((value: string): void => {
          this.inputUrl = value;
        })
        .margin({ bottom: 24 });

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(52)
          .backgroundColor('transparent')
          .fontColor(TEXT_SECONDARY)
          .borderRadius(12)
          .borderWidth(1)
          .borderColor(BORDER_COLOR)
          .onClick((): void => {
            this.controller.close();
          });

        Button('确定')
          .layoutWeight(1)
          .height(52)
          .margin({ left: 12 })
          .backgroundColor(PRIMARY_COLOR)
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .onClick((): void => {
            if (this.inputUrl.trim()) {
              this.onConfirm(this.inputUrl.trim());
              this.controller.close();
            } else {
              promptAction.showToast({ message: '请输入链接地址' });
            }
          });
      }
      .width('100%');
    }
    .padding(28)
    .width('90%')
    .backgroundColor(CARD_BG)
    .borderRadius(20)
    .shadow({ radius: 12, color: SHADOW_LOW, offsetY: 8 });
  }
}

@Entry
@Component
export struct PersonalInfoEditPage {
  @State user: User | null = null;
  @State isLoading: boolean = false;
  @State name: string = '';
  @State phone: string = '';
  @State email: string = '';
  @State avatar: string = '';
  @State isUploadingAvatar: boolean = false;

  private urlDialogController: CustomDialogController | null = null;

  async aboutToAppear(): Promise<void> {
    await this.loadUserInfo();
  }

  async loadUserInfo(): Promise<void> {
    this.isLoading = true;
    try {
      const userService: UserService = new UserService();
      const response: ApiResponse<User> = await userService.getProfile();
      if (response.code === 200 && response.data) {
        this.user = response.data;
        this.name = response.data.name ?? '';
        this.phone = response.data.phone ?? '';
        this.email = response.data.email ?? '';
        this.avatar = response.data.avatar ?? '';
      }
    } catch {
      promptAction.showToast({ message: '获取信息失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async inputAvatarUrl(): Promise<void> {
    if (this.isUploadingAvatar) return;

    if (!this.urlDialogController) {
      this.urlDialogController = new CustomDialogController({
        builder: AvatarUrlInputDialog({
          onConfirm: (url: string): void => {
            this.handleUrlInput(url);
          }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        customStyle: true,
        isModal: true,
      });
    }
    this.urlDialogController.open();
  }

  handleUrlInput(url: string): void {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      promptAction.showToast({ message: '链接需以 http:// 或 https:// 开头' });
      return;
    }

    this.avatar = url;
    promptAction.showToast({ message: '正在设置头像...' });
    this.uploadAvatar(url);
  }

  async uploadAvatar(avatarUrl: string): Promise<void> {
    this.isUploadingAvatar = true;
    try {
      console.log('Avatar URL:', avatarUrl);
      const userService: UserService = new UserService();
      const response: ApiResponse<boolean> = await userService.uploadAvatar(avatarUrl);

      if (response.code === 200) {
        promptAction.showToast({ message: '头像设置成功' });
      } else {
        promptAction.showToast({ message: '设置失败，请重试' });
      }
    } catch (uploadErr) {
      console.error('Upload Error Details:', JSON.stringify(uploadErr));
      promptAction.showToast({ message: '设置失败，请检查网络' });
    } finally {
      this.isUploadingAvatar = false;
    }
  }

  validatePhone(phone: string): boolean {
    return /^1[3-9]\d{9}$/.test(phone);
  }

  validateEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  async saveChanges(): Promise<void> {
    if (!this.name || !this.phone || !this.email) {
      promptAction.showToast({ message: '请填写完整信息', duration: 2000 });
      return;
    }

    if (!this.validatePhone(this.phone)) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 });
      return;
    }

    if (!this.validateEmail(this.email)) {
      promptAction.showToast({ message: '请输入正确的邮箱', duration: 2000 });
      return;
    }

    this.isLoading = true;
    try {
      const userService: UserService = new UserService();
      await userService.updateProfile({
        name: this.name,
        phone: this.phone,
        email: this.email
      });
      promptAction.showToast({ message: '保存成功', duration: 2000 });
      emitter.emit("refreshProfile", null);
      router.back();
    } catch {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  build(): void {
    Column() {
      // 顶部导航栏
      Row() {
        Button(){
          Image($rawfile('返回.png'))
            .width(24)
            .height(24)
        }
          .backgroundColor('transparent')
          .fontColor(TEXT_PRIMARY)
          .fontSize(18)
          .onClick((): void => {
            router.back();
          });

        Text('编辑个人信息')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_PRIMARY)
          .layoutWeight(1)
          .margin({left:96})
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(CARD_BG)
      .shadow({ radius: 4, color: SHADOW_LOW, offsetY: 2 })

      // 主内容区域
      Scroll() {
        Column({ space: 0 }) {
          // 头像区域
          Column() {
            Stack() {
              // 头像容器
              Column() {
                if (this.avatar) {
                  Image(this.avatar)
                    .width(104)
                    .height(104)
                    .borderRadius(52)
                    .objectFit(ImageFit.Cover)
                    .onError((): void => {
                      console.error('Image load failed');
                    });
                } else {
                  Column() {
                    Text(this.user?.name ? this.user.name.charAt(0) : 'U')
                      .fontSize(36)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FFFFFF')
                  }
                  .width(104)
                  .height(104)
                  .borderRadius(52)
                  .backgroundColor(PRIMARY_COLOR)
                }
              }
              .width(104)
              .height(104)
              .borderRadius(52)
              .backgroundColor('#F0F4FF')
              .shadow({ radius: 4, color: SHADOW_LOW, offsetY: 2 })

              // 更换按钮
              Column() {
                Text('更换')
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
              }
              .width(104)
              .height(104)
              .borderRadius(52)
              .backgroundColor('rgba(0, 0, 0, 0.4)')
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }
            .width(104)
            .height(104)
            .margin({ top: 28, bottom: 16 })
            .onClick((): void => {
              this.inputAvatarUrl();
            })

            Text('点击更换头像')
              .fontSize(13)
              .fontColor(TEXT_HINT)
              .margin({ bottom: 24 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          // 信息填写卡片
          Column() {
            // 姓名
            Row() {
              Text('姓名')
                .fontSize(14)
                .fontColor(TEXT_SECONDARY)
                .width(72)
              TextInput({ placeholder: '请输入姓名', text: this.name })
                .layoutWeight(1)
                .height(52)
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .placeholderColor(TEXT_HINT)
                .backgroundColor(CARD_BG)
                .borderRadius(12)
                .borderWidth(1)
                .borderColor(BORDER_COLOR)
                .onChange((value: string): void => {
                  this.name = value;
                })
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })

            // 分割线
            Divider().color(BORDER_COLOR).strokeWidth(1)

            // 手机号
            Row() {
              Text('手机号')
                .fontSize(14)
                .fontColor(TEXT_SECONDARY)
                .width(72)
              TextInput({ placeholder: '请输入手机号', text: this.phone })
                .layoutWeight(1)
                .height(52)
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .placeholderColor(TEXT_HINT)
                .backgroundColor(CARD_BG)
                .borderRadius(12)
                .borderWidth(1)
                .borderColor(BORDER_COLOR)
                .type(InputType.PhoneNumber)
                .onChange((value: string): void => {
                  this.phone = value;
                })
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })

            // 分割线
            Divider().color(BORDER_COLOR).strokeWidth(1)

            // 邮箱
            Row() {
              Text('邮箱')
                .fontSize(14)
                .fontColor(TEXT_SECONDARY)
                .width(72)
              TextInput({ placeholder: '请输入邮箱', text: this.email })
                .layoutWeight(1)
                .height(52)
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .placeholderColor(TEXT_HINT)
                .backgroundColor(CARD_BG)
                .borderRadius(12)
                .borderWidth(1)
                .borderColor(BORDER_COLOR)
                .type(InputType.Email)
                .onChange((value: string): void => {
                  this.email = value;
                })
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
          .backgroundColor(CARD_BG)
          .borderRadius(16)
          .shadow({ radius: 12, color: SHADOW_LOW, offsetY: 4 })
          .margin({ top: 16 })

          // 保存按钮
          Button(this.isLoading ? '保存中...' : '保存')
            .width('100%')
            .height(56)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY_COLOR)
            .borderRadius(16)
            .shadow({ radius: 8, color: SHADOW_MEDIUM, offsetY: 4 })
            .margin({ top: 24, bottom: 32 })
            .enabled(!this.isLoading && !this.isUploadingAvatar)
            .opacity((this.isLoading || this.isUploadingAvatar) ? 0.8 : 1)
            .onClick((): void => {
              this.saveChanges();
            })
        }
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_GRAY)
  }
}