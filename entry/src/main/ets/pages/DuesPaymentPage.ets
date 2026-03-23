import router from '@ohos.router';
import { UserService, ApiResponse, DuesStats, DuesPayment } from '../models/UserModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct DuesPaymentPage {
  @State duesStats: DuesStats | null = null;
  @State isLoading: boolean = false;
  @State selectedPaymentIds: string[] = [];

  async aboutToAppear() {
    await this.loadDuesStats();
  }

  async loadDuesStats() {
    this.isLoading = true;
    this.selectedPaymentIds = [];
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
      // 使用批量缴费的接口，传递单个ID
      const response: ApiResponse<boolean> = await userService.payMultipleDues(
        [payment.id],
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

  async payMultipleDues() {
    if (this.selectedPaymentIds.length === 0) {
      promptAction.showToast({
        message: '请选择要缴纳的党费',
        duration: 2000
      });
      return;
    }

    this.isLoading = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<boolean> = await userService.payMultipleDues(
        this.selectedPaymentIds,
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
      console.error('批量缴纳党费失败:', error);
      promptAction.showToast({
        message: '批量缴纳党费失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  toggleSelection(paymentId: string): void {
    const index = this.selectedPaymentIds.indexOf(paymentId);
    if (index > -1) {
      this.selectedPaymentIds.splice(index, 1);
    } else {
      this.selectedPaymentIds.push(paymentId);
    }
  }

  isSelected(paymentId: string): boolean {
    return this.selectedPaymentIds.indexOf(paymentId) > -1;
  }

  build() {
    Column() {
      // 1. 顶部导航栏
      Row() {
        Image($rawfile('返回.png'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('党费缴纳')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位，保持标题居中
        Text('')
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 2. 主体内容区
      Scroll() {
        Column() {
          // 3. 统计卡片（核心修改：压缩高度）
          if (this.duesStats) {
            Row() {
              // 待缴
              Column() {
                Text('待缴金额')
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .margin({ bottom: 4 }) // 缩小标签和数字的间距
                Text(`¥${this.duesStats.pendingAmount || 0}`)
                  .fontSize(18) // 数字字体稍微缩小，更紧凑
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#F5222D')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              // 分割线
              Column()
                .width(1)
                .height('20%')
                .backgroundColor('#F0F0F0')

              // 已缴
              Column() {
                Text('已缴金额')
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .margin({ bottom: 4 })
                Text(`¥${this.duesStats.paidAmount || 0}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#52C41A')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              // 分割线
              Column()
                .width(1)
                .height('20%')
                .backgroundColor('#F0F0F0')

              // 总计
              Column() {
                Text('总金额')
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .margin({ bottom: 4 })
                Text(`¥${this.duesStats.totalDue || 0}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 14, bottom: 14 }) // 大幅缩小上下内边距
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
            .shadow({
              radius: 8,
              color: '#0A000000',
              offsetY: 2
            })
            .margin({ left: 16, right: 16, top: 16, bottom: 16 }) // 缩小底部外边距
          }

          // 4. 列表标题
          Row() {
            Text('缴费明细')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
          }
          .width('100%')
          .padding({ left: 16, bottom: 12 })

          // 5. 加载/空状态
          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .width(40)
                .height(40)
                .color('#D32F2F')
              Text('加载中...')
                .fontSize(14)
                .fontColor('#8C8C8C')
                .margin({ top: 12 })
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
          } else if (!this.duesStats || !this.duesStats.paymentHistory || this.duesStats.paymentHistory.length === 0) {
            Column() {
              Text('暂无缴费记录')
                .fontSize(14)
                .fontColor('#BFBFBF')
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
          } else {
            // 6. 缴费列表
            ForEach(this.duesStats.paymentHistory, (payment: DuesPayment) => {
              Row() {
                // 复选框 (仅未缴费显示)
                if (payment.paymentStatus !== 'paid') {
                  Checkbox()
                    .select(this.isSelected(payment.id))
                    .selectedColor('#D32F2F')
                    .onChange(() => this.toggleSelection(payment.id))
                    .margin({ right: 12 })
                }

                // 内容区域
                Column() {
                  // 第一行：月份和金额
                  Row() {
                    Text(payment.paymentMonth)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1A1A1A')

                    Blank()

                    Text(`¥${payment.amount}`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1A1A1A')
                  }
                  .width('100%')
                  .margin({ bottom: 8 })

                  // 第二行：状态和时间
                  Row() {
                    // 状态标签
                    Text(payment.paymentStatus === 'paid' ? '已缴纳' : payment.paymentStatus === 'overdue' ? '已欠费' : '待缴纳')
                      .fontSize(12)
                      .fontColor(payment.paymentStatus === 'paid' ? '#52C41A' : '#F5222D')
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                      .borderRadius(4)
                      .backgroundColor(payment.paymentStatus === 'paid' ? '#F6FFED' : '#FFF1F0')

                    if (payment.paymentDate) {
                      Text(payment.paymentDate.replace('T', ' '))
                        .fontSize(12)
                        .fontColor('#8C8C8C')
                        .margin({ left: 12 })
                    }
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                }
                .layoutWeight(1)

                // 缴纳按钮 (仅未缴费显示)
                if (payment.paymentStatus !== 'paid') {
                  Button('缴纳')
                    .width(72)
                    .height(32)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#D32F2F')
                    .borderRadius(16)
                    .margin({ left: 12 })
                    .onClick(async () => {
                      await this.payDues(payment);
                    })
                }
              }
              .width('100%')
              .padding(16)
              .alignItems(VerticalAlign.Center)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 12 })
              .shadow({
                radius: 6,
                color: '#08000000',
                offsetY: 1
              })
            })
          }

          // 底部占位，防止按钮遮挡内容
          Blank()
            .height(20)
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F7F8FA')
      .scrollBar(BarState.Off)

      // 7. 底部批量缴纳按钮 (悬浮式)
      if (this.selectedPaymentIds.length > 0) {
        Column() {
          Button(`批量缴纳 (${this.selectedPaymentIds.length})`)
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#D32F2F')
            .borderRadius(24)
            .shadow({
              radius: 8,
              color: '#2FD32F2F',
              offsetY: 4
            })
            .onClick(async () => {
              await this.payMultipleDues();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}