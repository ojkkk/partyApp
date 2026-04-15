import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import { UserService, ApiResponse, User } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
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

// 头像输入弹窗
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
        .fontColor('#1F1F1F')
        .margin({ bottom: 20 });

      TextInput({ placeholder: '请输入图片网络地址 (URL)', text: this.inputUrl })
        .width('100%')
        .height(52)
        .borderRadius(12)
        .backgroundColor('#F7F4EF')
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
          .fontColor('#666666')
          .borderRadius(12)
          .borderWidth(1)
          .borderColor('#EFE7DB')
          .onClick((): void => {
            this.controller.close();
          });

        Button('确定')
          .layoutWeight(1)
          .height(52)
          .margin({ left: 12 })
          .backgroundColor('#B51F2E')
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
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 8 });
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
      // ==================== 顶部导航栏 ====================
      Row() {
        Button(){
          Image($rawfile('返回.png'))
            .width(24)
            .height(24);
        }
        .backgroundColor('transparent')
        .onClick((): void => {
          router.back();
        });

        Text('编辑个人信息')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Text('').width(24);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 });

      // ==================== 主内容区域 ====================
      Scroll() {
        Column({ space: 0 }) {
          // 头像区域
          Column() {
            Stack() {
              // 头像容器
              Column() {
                if (this.avatar) {
                  Image(this.avatar)
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                    .onError((): void => {
                      console.error('Image load failed');
                    });
                } else {
                  Text(this.user?.name ? this.user.name.charAt(0) : '党')
                    .fontSize(36)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF');
                }
              }
              .width(100)
              .height(100)
              .borderRadius(50)
              .backgroundColor('#B51F2E')
              .justifyContent(FlexAlign.Center);

              // 更换按钮遮罩
              Column() {
                Text('更换')
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium);
              }
              .width(100)
              .height(100)
              .borderRadius(50)
              .backgroundColor('rgba(0, 0, 0, 0.45)')
              .justifyContent(FlexAlign.Center);
            }
            .width(100)
            .height(100)
            .margin({ top: 28, bottom: 12 })
            .onClick((): void => {
              this.inputAvatarUrl();
            });

            Text('点击更换头像')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ bottom: 24 });
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center);

          // 信息填写卡片
          Column() {
            // 姓名
            Row() {
              Text('姓名')
                .fontSize(15)
                .fontColor('#666666')
                .width(70);
              TextInput({ placeholder: '请输入姓名', text: this.name })
                .layoutWeight(1)
                .height(52)
                .fontSize(15)
                .fontColor('#1F1F1F')
                .placeholderColor('#999999')
                .backgroundColor('#FFFFFF')
                .borderRadius(10)
                .borderWidth(1)
                .borderColor('#EFE7DB')
                .onChange((value: string): void => {
                  this.name = value;
                });
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 });

            Divider().color('#EFE7DB').strokeWidth(1);

            // 手机号
            Row() {
              Text('手机号')
                .fontSize(15)
                .fontColor('#666666')
                .width(70);
              TextInput({ placeholder: '请输入手机号', text: this.phone })
                .layoutWeight(1)
                .height(52)
                .fontSize(15)
                .fontColor('#1F1F1F')
                .placeholderColor('#999999')
                .backgroundColor('#FFFFFF')
                .borderRadius(10)
                .borderWidth(1)
                .borderColor('#EFE7DB')
                .type(InputType.PhoneNumber)
                .onChange((value: string): void => {
                  this.phone = value;
                });
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 });

            Divider().color('#EFE7DB').strokeWidth(1);

            // 邮箱
            Row() {
              Text('邮箱')
                .fontSize(15)
                .fontColor('#666666')
                .width(70);
              TextInput({ placeholder: '请输入邮箱', text: this.email })
                .layoutWeight(1)
                .height(52)
                .fontSize(15)
                .fontColor('#1F1F1F')
                .placeholderColor('#999999')
                .backgroundColor('#FFFFFF')
                .borderRadius(10)
                .borderWidth(1)
                .borderColor('#EFE7DB')
                .type(InputType.Email)
                .onChange((value: string): void => {
                  this.email = value;
                });
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 });
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ top: 16 });

          // 保存按钮
          Button(this.isLoading ? '保存中...' : '保存')
            .width('100%')
            .height(56)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#B51F2E')
            .borderRadius(14)
            .shadow({ radius: 8, color: 'rgba(181,31,46,0.3)', offsetY: 4 })
            .margin({ top: 24, bottom: 32 })
            .enabled(!this.isLoading && !this.isUploadingAvatar)
            .opacity((this.isLoading || this.isUploadingAvatar) ? 0.6 : 1)
            .onClick((): void => {
              this.saveChanges();
            });
        }
        .padding({ bottom: 32 });
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }
}