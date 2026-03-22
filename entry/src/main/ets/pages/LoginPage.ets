import { UserService, ApiResponse, LoginResponse } from '../models/UserModel';
import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct LoginPage {
  private userService: UserService = new UserService();
  @State username: string = '';
  @State password: string = '';
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  async login() {
    if (!this.username || !this.password) {
      this.errorMessage = '请输入用户名和密码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const response: ApiResponse<LoginResponse> = await this.userService.login(this.username, this.password);
      
      if (response.code === 200 && response.data) {
        await StorageService.setItem('user', response.data.user);
        await StorageService.setItem('token', response.data.token);
        await StorageService.setItem('userId', response.data.user.id);
        promptAction.showToast({
          message: '登录成功',
          duration: 2000
        });
        router.replaceUrl({
          url: 'pages/Index'
        });
      } else {
        this.errorMessage = response.message || '登录失败';
      }
    } catch (error) {
      console.error('登录请求失败:', error);
      this.errorMessage = '网络请求失败，请稍后重试';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Text('党建工作APP')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#D32F2F')
        .margin({ top: '80px', bottom: '60px' })

      Column() {
        Column() {
          Text('用户名')
            .fontSize(16)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: '10px' })
          
          TextInput({ placeholder: '请输入用户名' })
            .width('100%')
            .height('150px')
            .onChange((value: string) => {
              this.username = value;
            })
            .enabled(!this.isLoading)
        }
        .width('100%')
        .margin({ bottom: '24px' })

        Column() {
          Text('密码')
            .fontSize(16)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: '10px' })
          
          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)
            .width('100%')
            .height('150px')
            .onChange((value: string) => {
              this.password = value;
            })
            .enabled(!this.isLoading)
        }
        .width('100%')
        .margin({ bottom: '24px' })

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#D32F2F')
            .margin({ bottom: '20px' })
        }

        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height('160px')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#D32F2F')
          .borderRadius('60px')
          .margin({ top: '10px' })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.login();
          })

        Row() {
          Text('还没有账号？')
            .fontSize(15)
            .fontColor('#666666')
          Text('立即注册')
            .fontSize(15)
            .fontColor('#D32F2F')
            .fontWeight(FontWeight.Medium)
            .margin({ left: '8px' })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/RegisterPage'
              });
            })
        }
        .margin({ top: '30px' })
      }
      .width('88%')

      Column() {
        Text('测试账号:')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: '80px', bottom: '12px' })
        Text('系统管理员: admin / admin123')
          .fontSize(13)
          .fontColor('#999999')
          .margin({ bottom: '6px' })
        Text('支部管理员: branch / branch123')
          .fontSize(13)
          .fontColor('#999999')
          .margin({ bottom: '6px' })
        Text('普通党员: member / member123')
          .fontSize(13)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}
