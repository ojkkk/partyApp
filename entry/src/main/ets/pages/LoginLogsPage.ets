import router from '@ohos.router';
import { UserService, ApiResponse, LoginLog } from '../models/UserModel';
import promptAction from '@ohos.promptAction';


@Entry
@Component
export struct LoginLogsPage {
  @State logs: LoginLog[] = [];
  @State isLoading: boolean = false;

  async aboutToAppear() {
    await this.loadLoginLogs();
  }

  async loadLoginLogs() {
    this.isLoading = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<LoginLog[]> = await userService.getLoginLogs();
      if (response.code === 200 && response.data) {
        this.logs = response.data;
      }
    } catch (error) {
      console.error('获取登录日志失败:', error);
      promptAction.showToast({
        message: '获取登录日志失败',
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
        Text('登录日志')
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

      // 日志列表
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.logs.length === 0) {
        Column() {
          Text('暂无登录日志')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.logs, (log: LoginLog) => {
            ListItem() {
              Column() {
                Row() {
                  Text('登录时间:')
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(log.loginTime)
                    .fontSize(14)
                    .fontColor('#333333')
                    .flexGrow(1)
                    .textAlign(TextAlign.End)
                }
                .margin({ bottom: 8 })
                
                Row() {
                  Text('设备:')
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(log.device)
                    .fontSize(14)
                    .fontColor('#333333')
                    .flexGrow(1)
                    .textAlign(TextAlign.End)
                }
                .margin({ bottom: 8 })
                
                Row() {
                  Text('登录地点:')
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(log.location)
                    .fontSize(14)
                    .fontColor('#333333')
                    .flexGrow(1)
                    .textAlign(TextAlign.End)
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor('#FFFFFF')
              .borderWidth({ bottom: 1 })
              .borderColor({ bottom: '#EEEEEE' })
            }
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
