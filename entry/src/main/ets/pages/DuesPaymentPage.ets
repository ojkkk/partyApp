import router from '@ohos.router';
import { UserService, ApiResponse, DuesStats, DuesPayment } from '../models/UserModel';
import promptAction from '@ohos.promptAction';


@Entry
@Component
export struct DuesPaymentPage {
  @State duesStats: DuesStats | null = null;
  @State isLoading: boolean = false;
  @State selectedPayment: DuesPayment | null = null;

  async aboutToAppear() {
    await this.loadDuesStats();
  }

  async loadDuesStats() {
    this.isLoading = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<DuesStats> = await userService.getDuesStats();
      if (response.code === 200 && response.data) {
        this.duesStats = response.data;
      }
    } catch (error) {
      console.error('获取党费统计失败:', error);
      promptAction.showToast({
        message: '获取党费统计失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async payDues(payment: DuesPayment) {
    this.isLoading = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<boolean> = await userService.payDues(
        payment.paymentMonth,
        payment.amount,
        'online'
      );
      if (response.code === 200 && response.data) {
        promptAction.showToast({
          message: '党费缴纳成功',
          duration: 2000
        });
        await this.loadDuesStats();
      } else {
        promptAction.showToast({
          message: '党费缴纳失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('缴纳党费失败:', error);
      promptAction.showToast({
        message: '缴纳党费失败',
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
        Text('党费缴纳')
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

      // 统计信息
      if (this.duesStats) {
        Column() {
          Row() {
            Column() {
              Text('待缴金额')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Text(`¥${this.duesStats.overdueAmount || 0}`)
                .fontSize(18)
                .fontWeight(700)
                .fontColor('#D32F2F')
            }
            .flexGrow(1)
            .alignItems(HorizontalAlign.Center)
            
            Column() {
              Text('已缴金额')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Text(`¥${this.duesStats.paidAmount || 0}`)
                .fontSize(18)
                .fontWeight(700)
                .fontColor('#4CAF50')
            }
            .flexGrow(1)
            .alignItems(HorizontalAlign.Center)
            
            Column() {
              Text('总金额')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Text(`¥${this.duesStats.totalDue || 0}`)
                .fontSize(18)
                .fontWeight(700)
                .fontColor('#333333')
            }
            .flexGrow(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ bottom: 12 })
      }

      // 缴费记录
      Text('缴费记录')
        .fontSize(16)
        .fontWeight(500)
        .margin({ left: 16, top: 20, bottom: 12 })

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.duesStats || !this.duesStats.paymentHistory || this.duesStats.paymentHistory.length === 0) {
        Column() {
          Text('暂无缴费记录')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.duesStats.paymentHistory, (payment: DuesPayment) => {
            ListItem() {
              Column() {
                Row() {
                  Text(`缴费月份: ${payment.paymentMonth}`)
                    .fontSize(16)
                    .fontColor('#333333')
                  Text(`¥${payment.amount}`)
                    .fontSize(16)
                    .fontColor('#333333')
                    .fontWeight(500)
                }
                .margin({ bottom: 8 })
                
                Row() {
                  Text(`状态: ${payment.paymentStatus === 'paid' ? '已缴纳' : payment.paymentStatus === 'overdue' ? '欠费' : '待缴纳'}`)
                    .fontSize(14)
                    .fontColor(payment.paymentStatus === 'paid' ? '#4CAF50' : '#D32F2F')
                  if (payment.paymentDate) {
                    Text(`缴纳时间: ${payment.paymentDate}`)
                      .fontSize(14)
                      .fontColor('#666666')
                      .margin({ left: 16 })
                  }
                }
                
                if (payment.paymentStatus !== 'paid') {
                  Button('立即缴纳')
                    .width('120px')
                    .height('36px')
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#D32F2F')
                    .borderRadius(8)
                    .margin({ top: 12 })
                    .onClick(async () => {
                      await this.payDues(payment);
                    })
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
