import { UserService, RegisterRequest, ApiResponse, User } from '../models/UserModel';
import router from '@ohos.router';
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

// 【修复】API 20 兼容的自定义日期选择器
@CustomDialog
struct DatePickerDialog {
  // 【关键修复】必须声明 controller 属性，由系统自动注入
  controller: CustomDialogController;

  @State selectYear: number = new Date().getFullYear();
  @State selectMonth: number = new Date().getMonth();
  @State selectDay: number = new Date().getDate();
  onConfirm?: (year: number, month: number, day: number) => void;

  build() {
    Column() {
      // 顶部操作栏（匹配页面红色主题）
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#666666')
          .onClick(() => {
            this.controller.close();
          })

        Blank()

        Text('确定')
          .fontSize(16)
          .fontColor('#D32F2F')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm(this.selectYear, this.selectMonth, this.selectDay);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })

      // 日期选择器主体（限制入党日期范围）
      DatePicker({
        start: new Date('1921-01-01'),
        end: new Date(),
        selected: new Date(this.selectYear, this.selectMonth, this.selectDay)
      })
        .onChange((value: DatePickerResult) => {
          // 处理可能为 undefined 的属性
          if (value.year !== undefined) this.selectYear = value.year;
          if (value.month !== undefined) this.selectMonth = value.month;
          if (value.day !== undefined) this.selectDay = value.day;
        })
        .layoutWeight(1)
    }
    .width('100%')
    .height(300)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@Entry
@Component
struct RegisterPage {
  private userService: UserService = new UserService();
  @State username: string = '';
  @State password: string = '';
  @State name: string = '';
  @State role: 'member' | 'branch_admin' = 'member';
  @State partyId: string = '';
  @State branch: string = '';
  @State joinDate: string = '';
  @State phone: string = '';
  @State email: string = '';
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
  // 自定义对话框控制器
  datePickerDialogController: CustomDialogController = new CustomDialogController({
    builder: DatePickerDialog({
      onConfirm: (year: number, month: number, day: number) => {
        // 格式化日期：月份+1，补零
        const formatMonth = (month + 1).toString().padStart(2, '0');
        const formatDay = day.toString().padStart(2, '0');
        this.joinDate = `${year}-${formatMonth}-${formatDay}`;
      }
    }),
    isModal: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  async register() {
    // 验证必填项
    if (!this.username || !this.password || !this.name || !this.joinDate) {
      this.errorMessage = '请填写必填项';
      return;
    }

    // 验证支部管理员是否填写支部
    if (this.role === 'branch_admin' && !this.branch) {
      this.errorMessage = '支部管理员必须填写支部名称';
      return;
    }

    // 验证姓名格式
    if (this.name.length < 2 || this.name.length > 20) {
      this.errorMessage = '姓名长度应在2-20个字符之间';
      return;
    }

    // 验证密码格式
    if (this.password.length < 8) {
      this.errorMessage = '密码长度至少为8位';
      return;
    }
    const hasNumber = /\d/.test(this.password);
    const hasLetter = /[a-zA-Z]/.test(this.password);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(this.password);
    if (!hasNumber || !hasLetter || !hasSpecial) {
      this.errorMessage = '密码必须包含数字、英文和特殊字符';
      return;
    }

    // 验证手机号格式
    if (this.phone) {
      const phoneRegex = /^1[3-9]\d{9}$/;
      if (!phoneRegex.test(this.phone)) {
        this.errorMessage = '请输入正确的手机号格式';
        return;
      }
    }

    // 验证邮箱格式
    if (this.email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(this.email)) {
        this.errorMessage = '请输入正确的邮箱格式';
        return;
      }
    }

    this.isLoading = true;
    this.errorMessage = '';

    const newUser: RegisterRequest = {
      username: this.username,
      password: this.password,
      name: this.name,
      role: this.role,
      partyId: this.partyId,
      branch: this.branch,
      joinDate: this.joinDate,
      phone: this.phone,
      email: this.email
    };

    console.log('开始注册，请求数据:', newUser);

    try {
      const response: ApiResponse<User> = await this.userService.register(newUser);
      console.log('注册响应:', response);
      if (response.code === 200) {
        promptAction.showToast({
          message: '注册成功，请登录',
          duration: 2000
        });
        router.replaceUrl({
          url: 'pages/LoginPage'
        });
      } else {
        this.errorMessage = response.message || '注册失败';
      }
    } catch (error) {
      console.error('注册请求失败:', error);
      let errorMsg = '网络请求失败，请稍后重试';
      if (error instanceof Error) {
        errorMsg = `错误: ${error.message}`;
      } else {
        errorMsg = `错误: ${String(error)}`;
      }
      this.errorMessage = errorMsg;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    // 🚩 根容器：Stack布局叠加背景红旗装饰
    Stack() {
      // 红旗装饰层

      
      // 底部长城-红背景
      Image($rawfile('长城-红.png'))
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Cover)
        .opacity(0.2)
        .position({ y: '80%' })

      // 内容层：注册表单
      Column() {
        // 顶部党建标识区域

        // 注册卡片
        Column() {
          // 表单标题
          Text('用户注册')
            .fontSize(23)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 35 })
            .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

          // 滚动表单
          Scroll() {
            Column() {
              // 用户名输入框
              Column({ space: 10 }) {
                Text('用户名')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                TextInput({ placeholder: '请输入用户名' })
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
              .margin({ bottom: 24 })

              // 密码输入框
              Column({ space: 10 }) {
                Text('密码')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                TextInput({ placeholder: '请输入密码' })
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
              .margin({ bottom: 24 })

              // 姓名输入框
              Column({ space: 10 }) {
                Text('姓名')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                TextInput({ placeholder: '请输入姓名' })
                  .width('100%')
                  .height(54)
                  .fontSize(16)
                  .backgroundColor(CARD_WHITE)
                  .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
                  .padding({ left: 18, right: 18 })
                  .onChange((value: string) => {
                    this.name = value;
                  })
                  .enabled(!this.isLoading)
              }
              .width('100%')
              .margin({ bottom: 24 })

              // 党员编号输入框
              Column({ space: 10 }) {
                Text('党员编号')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                TextInput({ placeholder: '请输入党员编号' })
                  .width('100%')
                  .height(54)
                  .fontSize(16)
                  .backgroundColor(CARD_WHITE)
                  .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
                  .padding({ left: 18, right: 18 })
                  .onChange((value: string) => {
                    this.partyId = value;
                  })
                  .enabled(!this.isLoading)
              }
              .width('100%')
              .margin({ bottom: 24 })

              // 角色选择
              Column({ space: 10 }) {
                Text('角色选择')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                Row() {
                  Radio({ value: 'member', group: 'role' })
                    .checked(this.role === 'member')
                    .onChange((isChecked: boolean) => {
                      if (isChecked) {
                        this.role = 'member';
                      }
                    })
                    .enabled(!this.isLoading)
                  Text('普通党员')
                    .fontSize(15)
                    .fontColor(TEXT_MAIN)
                    .margin({ left: 10 })
                    .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                  Radio({ value: 'branch_admin', group: 'role' })
                    .checked(this.role === 'branch_admin')
                    .onChange((isChecked: boolean) => {
                      if (isChecked) {
                        this.role = 'branch_admin';
                      }
                    })
                    .enabled(!this.isLoading)
                    .margin({ left: 40 })
                  Text('支部管理员')
                    .fontSize(15)
                    .fontColor(TEXT_MAIN)
                    .margin({ left: 10 })
                    .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')
                }
              }
              .width('100%')
              .margin({ bottom: 24 })

              if (this.role === 'branch_admin') {
                Column({ space: 10 }) {
                  Text('管理支部')
                    .fontSize(16)
                    .fontColor(TEXT_MAIN)
                    .width('100%')
                    .fontWeight(FontWeight.Medium)
                    .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                  TextInput({ placeholder: '请输入管理的支部名称' })
                    .width('100%')
                    .height(54)
                    .fontSize(16)
                    .backgroundColor(CARD_WHITE)
                    .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
                    .padding({ left: 18, right: 18 })
                    .onChange((value: string) => {
                      this.branch = value;
                    })
                    .enabled(!this.isLoading)
                }
                .width('100%')
                .margin({ bottom: 24 })
              }

              // 入党日期
              Column({ space: 10 }) {
                Text('入党日期')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                // 点击触发自定义对话框
                Text(this.joinDate || '请选择入党日期 (YYYY-MM-DD)')
                  .width('100%')
                  .height(54)
                  .fontSize(16)
                  .fontColor(this.joinDate ? TEXT_MAIN : TEXT_SUB)
                  .textAlign(TextAlign.Start)
                  .padding({ left: 18 })
                  .backgroundColor(CARD_WHITE)
                  .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')
                  .onClick(() => {
                    if (!this.isLoading) {
                      this.datePickerDialogController.open();
                    }
                  })
              }
              .width('100%')
              .margin({ bottom: 24 })

              // 手机号输入框
              Column({ space: 10 }) {
                Text('手机号')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                TextInput({ placeholder: '请输入手机号' })
                  .width('100%')
                  .height(54)
                  .fontSize(16)
                  .backgroundColor(CARD_WHITE)
                  .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
                  .padding({ left: 18, right: 18 })
                  .onChange((value: string) => {
                    this.phone = value;
                  })
                  .enabled(!this.isLoading)
              }
              .width('100%')
              .margin({ bottom: 24 })

              // 邮箱输入框
              Column({ space: 10 }) {
                Text('邮箱')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')

                TextInput({ placeholder: '请输入邮箱' })
                  .width('100%')
                  .height(54)
                  .fontSize(16)
                  .backgroundColor(CARD_WHITE)
                  .border({ width: 1.2, color: BORDER_LIGHT, radius: 14 })
                  .padding({ left: 18, right: 18 })
                  .onChange((value: string) => {
                    this.email = value;
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
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')
              }

              // 注册按钮
              Button(this.isLoading ? '注册中...' : '注     册')
                .width('100%')
                .height(58)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .backgroundColor(this.isLoading ? '#BDBDBD' : PARTY_RED)
                .borderRadius(14)
                .enabled(!this.isLoading)
                .shadow({ radius: 10, color: SHADOW_RED, offsetY: 5 })
                .fontFamily('HarmonyOS Sans')
                .onClick(() => {
                  this.register();
                })

              // 登录跳转
              Row() {
                Text('已有账号？')
                  .fontSize(15)
                  .fontColor(TEXT_SUB)
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')
                Text('立即登录')
                  .fontSize(15)
                  .fontColor(PARTY_RED)
                  .fontWeight(FontWeight.Medium)
                  .margin({ left: 8 })
                  .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')
                  .onClick(() => {
                    router.replaceUrl({
                      url: 'pages/LoginPage'
                    });
                  })
              }
              .margin({ top: 30, bottom: 40 })
            }
            .width('100%')
          }
          .width('100%')
          .height(600) // 设置固定高度，超出部分可滚动
          .scrollBar(BarState.Off)
        }
        .width('90%')
        .padding({ top: 36, bottom: 36, left: 28, right: 28 })
        .backgroundColor(CARD_WHITE)
        .borderRadius(22)
        .shadow({ radius: 15, color: 'rgba(0,0,0,0.08)', offsetY: 8 })
        .border({ width: 1, color: '#FFE0E0' })

        // 底部版权
        Text('© 2026 党建工作平台')
          .fontSize(12)
          .fontColor(TEXT_SUB)
          .margin({ top: 40, bottom: 20 })
          .fontFamily(this.fontLoaded ? 'HWST' : 'HarmonyOS Sans')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(GRADIENT_BG)
  }
}