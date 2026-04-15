import router from '@ohos.router';
import { UserService, ApiResponse, DuesStats, DuesPayment } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

@Entry
@Component
export struct DuesPaymentPage {
  @State duesStats: DuesStats | null = null;
  @State isLoading: boolean = false;
  @State selectedPaymentIds: string[] = [];

  // ===================== 颜色配置 - 庄重红金正式风 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';      // 绛红
  private readonly COLOR_PRIMARY_LIGHT = '#D83A34'; // 亮红
  private readonly COLOR_GOLD = '#C9A45C';         // 暖金
  private readonly COLOR_GOLD_DARK = '#A67C2E';    // 深金
  private readonly COLOR_BG = '#F7F4EF';           // 米白背景
  private readonly COLOR_CARD = '#FFFFFF';         // 卡片白
  private readonly COLOR_TEXT_PRIMARY = '#1F1F1F'; // 主文字
  private readonly COLOR_TEXT_SECONDARY = '#666666'; // 次要文字
  private readonly COLOR_TEXT_TERTIARY = '#999999';  // 辅助文字
  private readonly COLOR_DIVIDER = '#F0EBE3';      // 分割线

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
        emitter.emit("refreshProfile", null);
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
        emitter.emit("refreshProfile", null);
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
      // 顶部导航栏 - 绛红渐变风格
      this.buildHeader();

      // 主体内容区
      Scroll() {
        Column() {
          // 统计卡片
          if (this.duesStats) {
            this.buildStatsCard();
          }

          // 列表标题
          Row() {
            // 左侧红色装饰条
            Row()
              .width(3)
              .height(14)
              .backgroundColor(this.COLOR_PRIMARY)
              .borderRadius(2)
              .margin({ right: 8 });

            Text('缴费明细')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.COLOR_TEXT_PRIMARY);
          }
          .width('100%')
          .padding({ left: 16, bottom: 12 });

          // 加载/空状态
          if (this.isLoading) {
            this.buildLoadingState();
          } else if (!this.duesStats || !this.duesStats.paymentHistory || this.duesStats.paymentHistory.length === 0) {
            this.buildEmptyState();
          } else {
            // 缴费列表
            ForEach(this.duesStats.paymentHistory, (payment: DuesPayment) => {
              this.buildPaymentItem(payment);
            });
          }

          // 底部占位
          Blank().height(20);
        }
      }
      .layoutWeight(1)
      .backgroundColor(this.COLOR_BG)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart);

      // 底部批量缴纳按钮
      if (this.selectedPaymentIds.length > 0) {
        this.buildBottomActionBar();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.COLOR_BG);
  }

  @Builder
  buildHeader() {
    Stack({ alignContent: Alignment.Bottom }) {
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#B51F2E', 0], ['#D83A34', 1]]
        });

      Row() {
        // 返回按钮
        Row() {
          Text('‹')
            .fontSize(32)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Regular)
            .margin({ bottom: 6 })
            .onClick(() => {
              emitter.emit("refreshProfile", null);
              router.back();
            });
        }
        .width(56)
        .height('100%')
        .justifyContent(FlexAlign.Center);

        // 标题
        Text('党费缴纳')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        // 右侧占位
        Row()
          .width(56)
          .height('100%');
      }
      .width('100%')
      .height(56)
      .padding({ top: 8 });

      // 金色装饰线
      Row()
        .width('100%')
        .height(1)
        .backgroundColor('rgba(201, 164, 92, 0.4)');
    }
    .width('100%')
    .height(56);
  }

  @Builder
  buildStatsCard() {
    Column() {
      Row() {
        // 待缴
        Column() {
          Text('待缴金额')
            .fontSize(12)
            .fontColor(this.COLOR_TEXT_TERTIARY)
            .margin({ bottom: 6 });
          Text(`¥${this.duesStats!.pendingAmount || 0}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.COLOR_PRIMARY);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);

        // 金色分割线
        Column()
          .width(1)
          .height(32)
          .backgroundColor(this.COLOR_DIVIDER);

        // 已缴
        Column() {
          Text('已缴金额')
            .fontSize(12)
            .fontColor(this.COLOR_TEXT_TERTIARY)
            .margin({ bottom: 6 });
          Text(`¥${this.duesStats!.paidAmount || 0}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.COLOR_GOLD);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);

        // 金色分割线
        Column()
          .width(1)
          .height(32)
          .backgroundColor(this.COLOR_DIVIDER);

        // 总计
        Column() {
          Text('总金额')
            .fontSize(12)
            .fontColor(this.COLOR_TEXT_TERTIARY)
            .margin({ bottom: 6 });
          Text(`¥${this.duesStats!.totalDue || 0}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.COLOR_TEXT_PRIMARY);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .padding(16);
    }
    .width('100%')
    .margin({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_GOLD })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 });
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.COLOR_PRIMARY);
      Text('加载中...')
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_SECONDARY)
        .margin({ top: 12 });
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildEmptyState() {
    Column() {
      // 金色装饰圆环
      Column() {
        Text('¥')
          .fontSize(32)
          .fontColor(this.COLOR_GOLD);
      }
      .width(72)
      .height(72)
      .border({ width: 2, color: this.COLOR_GOLD })
      .borderRadius(36)
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 16 });

      Text('暂无缴费记录')
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_TERTIARY);
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildPaymentItem(payment: DuesPayment) {
    Row() {
      // 复选框 (仅未缴费显示)
      if (payment.paymentStatus !== 'paid') {
        Checkbox()
          .select(this.isSelected(payment.id))
          .selectedColor(this.COLOR_PRIMARY)
          .onChange(() => this.toggleSelection(payment.id))
          .margin({ right: 12 });
      }

      // 内容区域
      Column() {
        // 第一行：月份和金额
        Row() {
          Text(payment.paymentMonth)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY);

          Blank();

          Text(`¥${payment.amount}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .margin({top:22});

        }
        .width('100%')
        .margin({ bottom: 8 });

        // 第二行：状态和时间
        Row() {
          // 状态标签
          Text(this.getStatusText(payment.paymentStatus))
            .fontSize(11)
            .fontColor(this.getStatusColor(payment.paymentStatus))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(4)
            .backgroundColor(this.getStatusBgColor(payment.paymentStatus));

          if (payment.paymentDate) {
            Text(payment.paymentDate.replace('T', ' '))
              .fontSize(12)
              .fontColor(this.COLOR_TEXT_TERTIARY)
              .margin({ left: 12 });
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);
      }
      .layoutWeight(1);

      // 缴纳按钮 (仅未缴费显示)
      if (payment.paymentStatus !== 'paid') {
        Button('缴纳')
          .width(64)
          .height(32)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(this.COLOR_PRIMARY)
          .borderRadius(16)
          .margin({ left: 12 })
          .onClick(async () => {
            await this.payDues(payment);
          });
      }
    }
    .width('100%')
    .padding(16)
    .margin({ left: 16, right: 16, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 1 });
  }

  getStatusText(status: string): string {
    if (status === 'paid') return '已缴纳';
    if (status === 'overdue') return '已欠费';
    return '待缴纳';
  }

  getStatusColor(status: string): string {
    if (status === 'paid') return this.COLOR_GOLD;
    if (status === 'overdue') return this.COLOR_PRIMARY;
    return this.COLOR_TEXT_SECONDARY;
  }

  getStatusBgColor(status: string): string {
    if (status === 'paid') return '#FFF8E1';
    if (status === 'overdue') return '#FEF2F2';
    return '#F5F5F5';
  }

  @Builder
  buildBottomActionBar() {
    Column() {
      Button(`批量缴纳 (${this.selectedPaymentIds.length})`)
        .width('92%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(this.COLOR_PRIMARY)
        .borderRadius(24)
        .shadow({ radius: 6, color: 'rgba(181, 31, 46, 0.3)', offsetX: 0, offsetY: 2 })
        .onClick(async () => {
          await this.payMultipleDues();
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.COLOR_CARD)
    .border({ width: { top: 1 }, color: this.COLOR_DIVIDER });
  }
}
