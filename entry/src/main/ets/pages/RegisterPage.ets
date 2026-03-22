import { UserService, RegisterRequest, ApiResponse, User } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

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
    Column() {
      Text('注册账号')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#D32F2F')
        .margin({ top: '40px', bottom: '30px' })

      Scroll() {
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
          .margin({ bottom: '20px' })

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
          .margin({ bottom: '20px' })

          Column() {
            Text('姓名')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: '10px' })

            TextInput({ placeholder: '请输入姓名' })
              .width('100%')
              .height('150px')
              .onChange((value: string) => {
                this.name = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ bottom: '20px' })

          Column() {
            Text('党员编号')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: '10px' })

            TextInput({ placeholder: '请输入党员编号' })
              .width('100%')
              .height('150px')
              .onChange((value: string) => {
                this.partyId = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ bottom: '20px' })

          Column() {
            Text('角色选择')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: '10px' })

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
                .fontColor('#333333')
                .margin({ left: '10px' })

              Radio({ value: 'branch_admin', group: 'role' })
                .checked(this.role === 'branch_admin')
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.role = 'branch_admin';
                  }
                })
                .enabled(!this.isLoading)
                .margin({ left: '40px' })
              Text('支部管理员')
                .fontSize(15)
                .fontColor('#333333')
                .margin({ left: '10px' })
            }
          }
          .width('100%')
          .margin({ bottom: '20px' })

          if (this.role === 'branch_admin') {
            Column() {
              Text('管理支部')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: '10px' })

              TextInput({ placeholder: '请输入管理的支部名称' })
                .width('100%')
                .height('150px')
                .onChange((value: string) => {
                  this.branch = value;
                })
                .enabled(!this.isLoading)
            }
            .width('100%')
            .margin({ bottom: '20px' })
          }

          Column() {
            Text('入党日期')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: '10px' })

            // 点击触发自定义对话框
            Text(this.joinDate || '请选择入党日期 (YYYY-MM-DD)')
              .width('100%')
              .height('150px')
              .fontSize(16)
              .fontColor(this.joinDate ? '#333333' : '#999999')
              .textAlign(TextAlign.Start)
              .padding({ left: 10 })
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => {
                if (!this.isLoading) {
                  this.datePickerDialogController.open();
                }
              })
          }
          .width('100%')
          .margin({ bottom: '20px' })

          Column() {
            Text('手机号')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: '10px' })

            TextInput({ placeholder: '请输入手机号' })
              .width('100%')
              .height('150px')
              .onChange((value: string) => {
                this.phone = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ bottom: '20px' })

          Column() {
            Text('邮箱')
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: '10px' })

            TextInput({ placeholder: '请输入邮箱' })
              .width('100%')
              .height('150px')
              .onChange((value: string) => {
                this.email = value;
              })
              .enabled(!this.isLoading)
          }
          .width('100%')
          .margin({ bottom: '20px' })

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#D32F2F')
              .margin({ top: '20px', bottom: '10px' })
          }

          Button(this.isLoading ? '注册中...' : '注册')
            .width('100%')
            .height('160px')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#D32F2F')
            .borderRadius('60px')
            .margin({ top: '30px' })
            .enabled(!this.isLoading)
            .onClick(() => {
              this.register();
            })

          Row() {
            Text('已有账号？')
              .fontSize(15)
              .fontColor('#666666')
            Text('立即登录')
              .fontSize(15)
              .fontColor('#D32F2F')
              .fontWeight(FontWeight.Medium)
              .margin({ left: '8px' })
              .onClick(() => {
                router.replaceUrl({
                  url: 'pages/LoginPage'
                });
              })
          }
          .margin({ top: '30px', bottom: '40px' })
        }
        .width('88%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}