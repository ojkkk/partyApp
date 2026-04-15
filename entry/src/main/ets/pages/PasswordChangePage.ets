import router from '@ohos.router';
import { UserService, ApiResponse } from '../models/UserModel';
import promptAction from '@ohos.promptAction';

// ─────────────────────────────────────────────────────────────────────────────
// 设计规范（庄重红金正式风）
//  主色        #B51F2E  绛红
//  强调色      #D83A34  亮红
//  金色        #C9A45C  暖金
//  背景        #F7F4EF  米白底
//  卡片背景    #FFFFFF  纯白
//  文字主色    #1F1F1F  深灰黑
//  文字副色    #666666  中灰
//  文字弱色    #999999  浅灰
//  分割线      #EFE7DB  暖灰金
// ─────────────────────────────────────────────────────────────────────────────

@Entry
@Component
export struct PasswordChangePage {
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;

  // 密码规则校验
  checkPasswordLength(): boolean {
    return this.newPassword.length >= 8;
  }

  checkPasswordComplex(): boolean {
    const hasNumber = /\d/.test(this.newPassword);
    const hasLetter = /[a-zA-Z]/.test(this.newPassword);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(this.newPassword);
    return hasNumber && hasLetter && hasSpecial;
  }

  async changePassword(): Promise<void> {
    if (!this.oldPassword || !this.newPassword || !this.confirmPassword) {
      promptAction.showToast({ message: '请填写所有必填项', duration: 2000 });
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的新密码不一致', duration: 2000 });
      return;
    }

    if (!this.checkPasswordLength()) {
      promptAction.showToast({ message: '密码长度至少为8位', duration: 2000 });
      return;
    }

    if (!this.checkPasswordComplex()) {
      promptAction.showToast({ message: '密码必须包含数字、英文和特殊字符', duration: 2000 });
      return;
    }

    this.isLoading = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<boolean> = await userService.changePassword(this.oldPassword, this.newPassword);
      if (response.code === 200 && response.data) {
        promptAction.showToast({ message: '密码修改成功', duration: 2000 });
        router.back();
      } else {
        promptAction.showToast({ message: response.message || '密码修改失败', duration: 2000 });
      }
    } catch (error) {
      console.error('修改密码失败:', error);
      promptAction.showToast({ message: '修改密码失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  // 输入框构建器
  @Builder
  InputItem(label: string, placeholder: string, password: string, onChange: (value: string) => void): void {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width('100%');

      TextInput({ placeholder, text: password })
        .type(InputType.Password)
        .width('100%')
        .height(52)
        .fontSize(15)
        .fontColor('#1F1F1F')
        .placeholderColor('#999999')
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .borderWidth(1)
        .borderColor('#EFE7DB')
        .onChange(onChange)
        .enabled(!this.isLoading)
        .padding({ left: 16, right: 16 });
    }
    .width('100%');
  }

  // 密码规则提示构建器
  @Builder
  PasswordRule(): void {
    Column({ space: 6 }) {
      Text('密码要求')
        .fontSize(13)
        .fontColor('#999999')
        .width('100%');

      Row({ space: 16 }) {
        Row({ space: 4 }) {
          Stack() {
            Circle()
              .width(14)
              .height(14)
              .fill(this.checkPasswordLength() ? '#2E7D32' : '#CCCCCC');

            Text(this.checkPasswordLength() ? '✓' : '')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .position({ x: 2, y: 1 });
          }
          .width(14)
          .height(14);

          Text('至少8位')
            .fontSize(13)
            .fontColor(this.checkPasswordLength() ? '#2E7D32' : '#999999');
        }

        Row({ space: 4 }) {
          Stack() {
            Circle()
              .width(14)
              .height(14)
              .fill(this.checkPasswordComplex() ? '#2E7D32' : '#CCCCCC');

            Text(this.checkPasswordComplex() ? '✓' : '')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .position({ x: 2, y: 1 });
          }
          .width(14)
          .height(14);

          Text('数字+字母+特殊字符')
            .fontSize(13)
            .fontColor(this.checkPasswordComplex() ? '#2E7D32' : '#999999');
        }
      }
      .width('100%');
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 });
  }

  build(): void {
    Column() {
      // ==================== 顶部导航栏 ====================
      Row() {
        Button() {
          Image($rawfile('返回.png'))
            .width(24)
            .height(24);
        }
        .backgroundColor('transparent')
        .onClick((): void => {
          router.back();
        });

        Text('修改密码')
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

      // ==================== 表单内容 ====================
      Scroll() {
        Column({ space: 20 }) {
          // 标题
          Column() {
            Text('修改密码')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F1F1F');
            Text('请填写以下信息以修改密码')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 8 });
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 20 });

          // 输入框卡片
          Column({ space: 16 }) {
            this.InputItem('旧密码', '请输入旧密码', this.oldPassword, (value) => this.oldPassword = value);
            Divider().color('#EFE7DB').strokeWidth(1);
            this.InputItem('新密码', '请输入新密码', this.newPassword, (value) => this.newPassword = value);
            this.PasswordRule();
            Divider().color('#EFE7DB').strokeWidth(1);
            this.InputItem('确认新密码', '请再次输入新密码', this.confirmPassword, (value) => this.confirmPassword = value);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 16 })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16, top: 20 });

          // 提交按钮
          Button(this.isLoading ? '修改中...' : '确认修改')
            .width('100%')
            .height(56)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.isLoading ? '#CCCCCC' : '#B51F2E')
            .borderRadius(14)
            .shadow({ radius: 8, color: 'rgba(181,31,46,0.3)', offsetY: 4 })
            .margin({ left: 16, right: 16, top: 8 })
            .enabled(!this.isLoading)
            .onClick(async (): Promise<void> => await this.changePassword());

          // 提示
          Text('密码修改后将使用新密码登录')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 16 });
        }
        .width('100%')
        .padding({ top: 16, bottom: 32 });
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }
}