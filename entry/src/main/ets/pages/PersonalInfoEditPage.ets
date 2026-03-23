import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import { UserService, ApiResponse, User } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import photoPicker from '@ohos.file.picker';
import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { emitter } from '@kit.BasicServicesKit';

// 1. 定义自定义弹窗组件：用于输入URL
@CustomDialog
struct AvatarUrlInputDialog {
  @State inputUrl: string = '';
  controller: CustomDialogController = new CustomDialogController({
    builder: () => {},
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    customStyle: false,
    isModal: true,
  });

  // 回调函数：将输入的URL传回给页面
  onConfirm: (url: string) => void = (url: string) => {};

  build() {
    Column() {
      Text('设置头像地址')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16, top: 10 });

      TextInput({ placeholder: '请输入图片网络地址 (URL)', text: this.inputUrl })
        .width('100%')
        .height(48)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .onChange((value: string) => {
          this.inputUrl = value;
        })
        .margin({ bottom: 20 });

      Row() {
        Button('取消')
          .flexGrow(1)
          .height(44)
          .backgroundColor('#EEEEEE')
          .fontColor('#333333')
          .onClick(() => {
            this.controller.close();
          });

        Button('确定')
          .flexGrow(1)
          .height(44)
          .margin({ left: 12 })
          .backgroundColor('#D32F2F')
          .fontColor('#FFFFFF')
          .onClick(() => {
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
    .padding(20)
    .width('90%')
    .borderRadius(12);
  }
}

interface PhotoResult {
  uri: string;
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

  // 定义弹窗控制器
  private urlDialogController: CustomDialogController | null = null;

  async aboutToAppear(): Promise<void> {
    await this.loadUserInfo();
  }

  async loadUserInfo(): Promise<void> {
    this.isLoading = true;
    try {
      const userService = new UserService();
      const response = await userService.getProfile();
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

  /**
   * 打开输入框让用户输入URL
   */
  async inputAvatarUrl(): Promise<void> {
    if (this.isUploadingAvatar) return;

    // 2. 初始化并打开弹窗
    if (!this.urlDialogController) {
      this.urlDialogController = new CustomDialogController({
        builder: AvatarUrlInputDialog({
          onConfirm: (url: string) => {
            this.handleUrlInput(url);
          }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        isModal: true,
      });
    }
    this.urlDialogController.open();
  }

  /**
   * 处理用户输入的URL
   */
  handleUrlInput(url: string): void {
    // 简单的URL格式校验
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      promptAction.showToast({ message: '链接需以 http:// 或 https:// 开头' });
      return;
    }

    this.avatar = url;
    promptAction.showToast({ message: '正在设置头像...' });
    this.uploadAvatar(url);
  }

  /**
   * 上传头像到服务器
   */
  async uploadAvatar(avatarUrl: string): Promise<void> {
    this.isUploadingAvatar = true;

    try {
      console.log('Avatar URL:', avatarUrl);
      const userService = new UserService();
      const response = await userService.uploadAvatar(avatarUrl);

      if (response.code === 200) {
        promptAction.showToast({ message: '头像设置成功' });
      } else {
        promptAction.showToast({ message: response.message || '设置失败，请重试' });
        // 如果服务器失败，可选：回滚头像显示
        // this.avatar = this.user?.avatar ?? '';
      }
    } catch (uploadErr) {
      console.error('Upload Error Details:', JSON.stringify(uploadErr));
      promptAction.showToast({ message: '设置失败，请检查网络' });
      // 回滚
      // this.avatar = this.user?.avatar ?? '';
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
      const userService = new UserService();
      await userService.updateProfile({
        name: this.name,
        phone: this.phone,
        email: this.email
      });
      promptAction.showToast({ message: '保存成功', duration: 2000 });
      // 发送事件通知ProfilePage刷新
      emitter.emit("refreshProfile", null);
      router.back();
    } catch {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Button('返回')
          .backgroundColor('transparent')
          .fontColor('#D32F2F')
          .onClick(() => router.back());

        Text('编辑个人信息')
          .fontSize(18)
          .fontWeight(700)
          .flexGrow(1)
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .height(56)
      .backgroundColor('#fff');

      Scroll() {
        Column({ space: 16 }) {
          Stack() {
            if (this.avatar) {
              Image(this.avatar)
                .width(90)
                .height(90)
                .borderRadius(45)
                .objectFit(ImageFit.Cover)
                // 加载网络图片时添加占位符/错误处理
                .onError(() => {
                  console.error('Image load failed');
                  promptAction.showToast({ message: '图片加载失败' });
                });
            } else {
              Text('头像')
                .width(90)
                .height(90)
                .backgroundColor('#eee')
                .borderRadius(45)
                .textAlign(TextAlign.Center);
            }
          }
          .onClick(() => this.inputAvatarUrl())
          .margin({ top: 20 });

          TextInput({ placeholder: '姓名', text: this.name })
            .width('100%')
            .height(50)
            .backgroundColor('#fff')
            .borderRadius(8)
            .padding({ left: 16 })
            .onChange((value) => this.name = value);

          TextInput({ placeholder: '手机号', text: this.phone })
            .width('100%')
            .height(50)
            .backgroundColor('#fff')
            .borderRadius(8)
            .padding({ left: 16 })
            .onChange((value) => this.phone = value);

          TextInput({ placeholder: '邮箱', text: this.email })
            .width('100%')
            .height(50)
            .backgroundColor('#fff')
            .borderRadius(8)
            .padding({ left: 16 })
            .onChange((value) => this.email = value);

          Button('保存')
            .width('100%')
            .height(50)
            .backgroundColor('#D32F2F')
            .fontColor('#fff')
            .borderRadius(8)
            .onClick(() => this.saveChanges());
        }
        .padding(20);
      }
      .flexGrow(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}