import router from '@ohos.router';
import { UserService, ApiResponse } from '../models/UserModel';
import promptAction from '@ohos.promptAction';

// 设计系统常量
const PRIMARY_COLOR: string = '#D32F2F'; // 保持主色不变
const BG_GRAY: string = '#F8FAFC';
const CARD_BG: string = '#FFFFFF';
const TEXT_PRIMARY: string = '#1E293B';
const TEXT_SECONDARY: string = '#64748B';
const TEXT_HINT: string = '#94A3B8';
const BORDER_COLOR: string = '#E2E8F0';
const SHADOW_LOW: string = 'rgba(211, 47, 47, 0.1)';
const SHADOW_MEDIUM: string = 'rgba(211, 47, 47, 0.2)';

@Entry
@Component
export struct PasswordChangePage {
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State showPasswordRules: boolean = false;

  async changePassword() {
    if (!this.oldPassword || !this.newPassword || !this.confirmPassword) {
      promptAction.showToast({
        message: '请填写所有必填项',
        duration: 2000
      });
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      promptAction.showToast({
        message: '两次输入的新密码不一致',
        duration: 2000
      });
      return;
    }

    // 验证密码格式
    if (this.newPassword.length < 8) {
      promptAction.showToast({
        message: '密码长度至少为8位',
        duration: 2000
      });
      return;
    }
    const hasNumber = /\d/.test(this.newPassword);
    const hasLetter = /[a-zA-Z]/.test(this.newPassword);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(this.newPassword);
    if (!hasNumber || !hasLetter || !hasSpecial) {
      promptAction.showToast({
        message: '密码必须包含数字、英文和特殊字符',
        duration: 2000
      });
      return;
    }

    this.isLoading = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<boolean> = await userService.changePassword(this.oldPassword, this.newPassword);
      if (response.code === 200 && response.data) {
        promptAction.showToast({
          message: '密码修改成功',
          duration: 2000
        });
        router.back();
      } else {
        promptAction.showToast({
          message: response.message || '密码修改失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('修改密码失败:', error);
      promptAction.showToast({
        message: '修改密码失败',
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
        Button(){
          Image($rawfile('返回.png'))
            .width(24)
            .height(24)
        }
          .fontSize(20)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor('transparent')
          .onClick(() => {
            router.back();
          });

        Text('修改密码')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank()
          .width(24)
          .margin({right:0})
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(CARD_BG)
      .borderWidth({ bottom: 1 })
      .borderColor(BORDER_COLOR)
      .shadow({ radius: 4, color: SHADOW_LOW, offsetY: 2 })

      // 表单内容
      Scroll() {
        Column() {
          // 旧密码
          Column() {
            Text('旧密码')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
              .width('100%')
              .margin({ bottom: 8 });

            TextInput({ placeholder: '请输入旧密码', text: this.oldPassword })
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
              .onChange((value: string) => {
                this.oldPassword = value;
              })
              .enabled(!this.isLoading);
          }
          .width('100%')
          .margin({ top: 24, left: 24, right: 24 })

          // 新密码
          Column() {
            Text('新密码')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
              .width('100%')
              .margin({ bottom: 8 });

            TextInput({ placeholder: '请输入新密码', text: this.newPassword })
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
              .onChange((value: string) => {
                this.newPassword = value;
              })
              .enabled(!this.isLoading);
          }
          .width('100%')
          .margin({ left: 24, right: 24, bottom: 24 })

          // 密码规则提示
          Column() {
            Text('密码要求')
              .fontSize(13)
              .fontColor(TEXT_HINT)
              .margin({ bottom: 4 });

            Row() {
              Text('• 至少8位')
                .fontSize(13)
                .fontColor(this.newPassword.length >= 8 ? TEXT_PRIMARY : TEXT_HINT)
                .margin({ right: 8 });

              Text('• 包含数字、字母和特殊字符')
                .fontSize(13)
                .fontColor(
                  this.newPassword.length >= 8 &&
                  /\d/.test(this.newPassword) &&
                  /[a-zA-Z]/.test(this.newPassword) &&
                  /[!@#$%^&*(),.?":{}|<>]/.test(this.newPassword) ?
                    TEXT_PRIMARY : TEXT_HINT
                );
            }
            .width('100%')
            .margin({ top: 4 });
          }
          .width('100%')
          .margin({ left: 24, right: 24, bottom: 16 })

          // 确认密码
          Column() {
            Text('确认新密码')
              .fontSize(14)
              .fontColor(TEXT_SECONDARY)
              .width('100%')
              .margin({ bottom: 8 });

            TextInput({ placeholder: '请再次输入新密码', text: this.confirmPassword })
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
              .onChange((value: string) => {
                this.confirmPassword = value;
              })
              .enabled(!this.isLoading);
          }
          .width('100%')
          .margin({ left: 24, right: 24, bottom: 24 })

          // 保存按钮
          Button(this.isLoading ? '修改中...' : '修改密码')
            .width('90%')
            .height(56)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY_COLOR)
            .borderRadius(12)
            .shadow({ radius: 8, color: SHADOW_MEDIUM, offsetY: 4 })
            .margin({ top: 24, bottom: 32 })
            .enabled(!this.isLoading)
            .onClick(async () => {
              await this.changePassword();
            });
        }
        .width('100%')
        .padding({ bottom: 32 })
      }
      .flexGrow(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_GRAY)
  }
}