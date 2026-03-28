import router from '@ohos.router';
import { UserService, ApiResponse } from '../models/UserModel';
import promptAction from '@ohos.promptAction';

// 设计系统常量
const PRIMARY_COLOR: string = '#D32F2F';
const BG_GRAY: string = '#F8FAFC';
const CARD_BG: string = '#FFFFFF';
const TEXT_PRIMARY: string = '#1E293B';
const TEXT_SECONDARY: string = '#64748B';
const TEXT_HINT: string = '#94A3B8';
const BORDER_COLOR: string = '#E2E8F0';
const SHADOW_LOW: string = 'rgba(211, 47, 47, 0.1)';
const SHADOW_MEDIUM: string = 'rgba(211, 47, 47, 0.2)';
// 新增统一间距常量
const PADDING_HORIZONTAL: number = 20; // 左右边距（解决贴边核心）
const SPACE_MD: number = 16;
const SPACE_LG: number = 24;

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

  async changePassword() {
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

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Image($rawfile('返回.png'))
            .width(24)
            .height(24)
        }
        .backgroundColor('transparent')
        .onClick(() => router.back());

        Text('修改密码')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Blank().width(24);
      }
      .width('100%')
      .height(56)
      .padding({ left: PADDING_HORIZONTAL, right: PADDING_HORIZONTAL })
      .backgroundColor(CARD_BG)
      .borderWidth({ bottom: 1 })
      .borderColor(BORDER_COLOR)
      .shadow({ radius: 4, color: SHADOW_LOW, offsetY: 2 });

      // 表单内容（核心：统一左右边距，解决贴边）
      Scroll() {
        Column({ space: SPACE_LG }) {
          // 旧密码输入框
          this.buildInputItem('旧密码', '请输入旧密码', this.oldPassword, (value) => this.oldPassword = value);

          // 新密码输入框
          this.buildInputItem('新密码', '请输入新密码', this.newPassword, (value) => this.newPassword = value);

          // 密码规则提示（优化排版）
          this.buildPasswordRule();

          // 确认密码输入框
          this.buildInputItem('确认新密码', '请再次输入新密码', this.confirmPassword, (value) => this.confirmPassword = value);

          // 保存按钮
          this.buildSubmitButton();
        }
        .width('100%')
        .padding({ top: SPACE_LG, bottom: SPACE_LG, left: PADDING_HORIZONTAL, right: PADDING_HORIZONTAL });
      }
      .flexGrow(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_GRAY);
  }

  // 封装输入框组件（代码复用 + 统一样式）
  @Builder
  buildInputItem(label: string, placeholder: string, text: string, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(14)
        .fontColor(TEXT_SECONDARY)
        .width('100%');

      TextInput({ placeholder, text })
        .type(InputType.Password)
        .width('100%')
        .height(52)
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
        .placeholderColor(TEXT_HINT)
        .backgroundColor(CARD_BG)
        .borderRadius(12)
        .borderWidth(1)
        .borderColor(BORDER_COLOR)
        .onChange(onChange)
        .enabled(!this.isLoading)
        .padding({ left: 16, right: 16 });
    }
    .width('100%');
  }

  // 封装密码规则组件
  @Builder
  buildPasswordRule() {
    Column({ space: 4 }) {
      Text('密码要求')
        .fontSize(13)
        .fontColor(TEXT_HINT)
        .width('100%');

      Row({ space: 12 }) {
        Text('• 至少8位')
          .fontSize(13)
          .fontColor(this.checkPasswordLength() ? PRIMARY_COLOR : TEXT_HINT);

        Text('• 数字+字母+特殊字符')
          .fontSize(13)
          .fontColor(this.checkPasswordComplex() ? PRIMARY_COLOR : TEXT_HINT);
      }
      .width('100%');
    }
    .width('100%');
  }

  // 封装提交按钮
  @Builder
  buildSubmitButton() {
    Button(this.isLoading ? '修改中...' : '修改密码')
      .width('100%')
      .height(56)
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor(this.isLoading ? TEXT_HINT : PRIMARY_COLOR)
      .borderRadius(12)
      .shadow({ radius: 8, color: SHADOW_MEDIUM, offsetY: 4 })
      .enabled(!this.isLoading)
      .onClick(async () => await this.changePassword())
      .margin({ top: 8 });
  }
}