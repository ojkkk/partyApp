import router from '@ohos.router';
import { UserService, ApiResponse } from '../models/UserModel';
import promptAction from '@ohos.promptAction';


@Entry
@Component
export struct PasswordChangePage {
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;

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
        Button('返回')
          .fontSize(16)
          .fontColor('#D32F2F')
          .backgroundColor('transparent')
          .onClick(() => {
            router.back();
          })
        Text('修改密码')
          .fontSize(18)
          .fontWeight(700)
          .flexGrow(1)
          .textAlign(TextAlign.Center)
        Text('')
          .width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: '#EEEEEE' })

      // 表单内容
      Scroll() {
        Column() {
          Column() {
            Text('旧密码')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })
            
            TextInput({ placeholder: '请输入旧密码' })
              .type(InputType.Password)
              .width('100%')
              .height(150)
              .onChange((value: string) => {
                this.oldPassword = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ top: 20, left: 20, right: 20, bottom: 20 })

          Column() {
            Text('新密码')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })
            
            TextInput({ placeholder: '请输入新密码' })
              .type(InputType.Password)
              .width('100%')
              .height(150)
              .onChange((value: string) => {
                this.newPassword = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ left: 20, right: 20, bottom: 20 })

          Column() {
            Text('确认新密码')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })
            
            TextInput({ placeholder: '请再次输入新密码' })
              .type(InputType.Password)
              .width('100%')
              .height(150)
              .onChange((value: string) => {
                this.confirmPassword = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ left: 20, right: 20, bottom: 20 })

          // 保存按钮
          Button(this.isLoading ? '修改中...' : '修改密码')
            .width('90%')
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#D32F2F')
            .borderRadius(8)
            .margin({ top: 40, bottom: 30 })
            .enabled(!this.isLoading)
            .onClick(async () => {
              await this.changePassword();
            })
        }
        .width('100%')
      }
      .flexGrow(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
