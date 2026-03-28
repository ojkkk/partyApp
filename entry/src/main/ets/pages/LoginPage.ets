import { UserService, ApiResponse, LoginResponse } from '../models/UserModel';
import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import font from '@ohos.font';
// 🚩 党建红色系 标准配色
const PARTY_RED: string = '#CE0000';       // 标准党旗红
const PARTY_RED_DARK: string = '#A80000';  // 深邃红
const PARTY_RED_LIGHT: string = '#FFEBEB'; // 浅红背景
const GRADIENT_BG: string = 'linear-gradient(180deg, #FFEBEB 0%, #FFFFFF 100%)'; // 庄重渐变
const CARD_WHITE: string = '#FFFFFF';       // 卡片白
const TEXT_MAIN: string = '#212121';        // 主文字
const TEXT_SUB: string = '#757575';         // 次文字
const BORDER_LIGHT: string = '#FFCDCD';      // 浅红边框
const SHADOW_RED: string = 'rgba(206, 0, 0, 0.18)'; // 红色阴影

@Entry
@Component
struct LoginPage {
  private userService: UserService = new UserService();
  @State username: string = '';
  @State password: string = '';
  @State errorMessage: string = '';
  @State isLoading: boolean = false;
  @State fontLoaded: boolean = false; // 标记字体是否加载完成

  aboutToAppear() {
    try {
      // 同步注册 rawfile 中的华文中宋字体
      font.registerFont({
        familyName: 'HWST', // 自定义字体别名
        familySrc: $rawfile('华文中宋.ttf')
      });

      console.info('华文中宋字体注册成功');
      this.fontLoaded = true; // 直接标记加载完成
    } catch (err) {
      console.error('字体注册失败:', JSON.stringify(err));
    }
  }
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
    // 🚩 根容器：Stack布局叠加背景红旗装饰
    Stack() {
      // 红旗装饰层
      Column() {
        Row() {
          // 左上角红旗装饰
          Image($rawfile('红旗-顶部.png'))
            .width('100%')
            .height(250)
            .opacity(0.8)
            .margin({ top: 0})
            .objectFit((ImageFit.Cover))





        }
        .width('100%')


      }
      .width('100%')
      .height('100%')

      // 底部长城-红背景
      Image($rawfile('长城-红.png'))
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Cover)
        .opacity(1)
        .position({ y: '80%' })

      // 2. 内容层：登录表单
      Column() {
        // 顶部党建标识区域
        Column() {
          // 党徽图标（核心标识，使用本地资源）
          Image($rawfile('党徽黄色.png'))
            .width(90)
            .height(90)
            .margin({ bottom: 40 })
            .shadow({ radius: 15, color: SHADOW_RED, offsetY: 5 })


          // 主标题
          Text('智慧党建')
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .fontColor(PARTY_RED)
            .margin({ bottom: 8 })
            .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

          // 副标题
          Text('不忘初心 牢记使命')
            .fontSize(17)
            .fontColor(PARTY_RED_DARK)
            .fontWeight(FontWeight.Medium)
            .letterSpacing(2)
            .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')
        }
        .margin({ top: 70, bottom: 30 })

        // 登录卡片
        Column() {


          // 用户名输入框
          Column({ space: 10 }) {
            Text('用户名')
              .fontSize(16)
              .fontColor(TEXT_MAIN)
              .width('100%')
              .fontWeight(FontWeight.Medium)


            TextInput({ placeholder: '请输入用户名', text: this.username })
              .width('100%')
              .height(54)

              .fontSize(16)

              .backgroundColor(CARD_WHITE)
              .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
              .padding({ left: 18, right: 18 })
              .onChange((value: string) => {
                this.username = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ bottom: 26 })

          // 密码输入框
          Column({ space: 10 }) {
            Text('密码')
              .fontSize(16)
              .fontColor(TEXT_MAIN)
              .width('100%')
              .fontWeight(FontWeight.Medium)


            TextInput({ placeholder: '请输入密码', text: this.password })
              .type(InputType.Password)
              .width('100%')
              .height(54)

              .fontSize(16)

              .backgroundColor(CARD_WHITE)
              .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
              .padding({ left: 18, right: 18 })
              .onChange((value: string) => {
                this.password = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ bottom: 18 })

          // 错误提示
          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor(PARTY_RED)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 18 })
          }

          // 登录按钮（庄重红渐变）
          Button(this.isLoading ? '登录中...' : '登    录')
            .width('100%')
            .height(58)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontFamily( 'HarmonyOS Sans')
            .fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#BDBDBD' : PARTY_RED)
            .borderRadius(14)
            .enabled(!this.isLoading)
            .shadow({ radius: 10, color: SHADOW_RED, offsetY: 5 })
            .onClick(() => {
              this.login();
            })

          // 注册跳转
          Row() {
            Text('还没有账号？')
              .fontSize(15)
              .fontColor(TEXT_SUB)

            Text('立即注册')
              .fontSize(15)
              .fontColor(PARTY_RED)
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/RegisterPage'
                });
              })
          }
          .margin({ top: 30,bottom:-10 })
        }
        .width('90%')
        .padding({ top: 36, bottom: 36, left: 28, right: 28 })
        .backgroundColor(CARD_WHITE)
        .borderRadius(22)
        .shadow({ radius: 15, color: 'rgba(0,0,0,0.08)', offsetY: 8 })
        .border({ width: 1, color: '#FFE0E0' })


      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(GRADIENT_BG)
  }
}