import lottie from '@ohos/lottie';


export interface NavigationItem {
  name: string;
  icon?: string | Resource;
  lottie?: string;
  component: Object;
}

@Component
export struct NavigationBar {
  public items: Array<NavigationItem> = [];
  @Link currentIndex: number;
  @State scales: number[] = [];
  private canvasContexts: CanvasRenderingContext2D[] = [];

  // 颜色配置 - 庄重红金正式风
  private readonly COLOR_PRIMARY = '#B51F2E';      // 绛红 - 选中状态
  private readonly COLOR_GOLD = '#C9A45C';         // 暖金 - 装饰
  private readonly COLOR_TEXT_NORMAL = '#666666';  // 未选中文字
  private readonly COLOR_BG = '#FFFFFF';           // 背景白
  private readonly COLOR_BORDER = '#EFE7DB';       // 金色边框

  aboutToAppear() {
    if (!this.items) {
      this.items = [];
    }
    for (let i = 0; i < this.items.length; i++) {
      this.scales.push(1);
      const settings: RenderingContextSettings = new RenderingContextSettings(true);
      this.canvasContexts[i] = new CanvasRenderingContext2D(settings);
    }
  }

  aboutToDisappear() {
    for (let i = 0; i < this.items.length; i++) {
      if (this.items[i].lottie) {
        lottie.destroy(`nav_animation_${i}`);
      }
    }
  }

  handleClick(index: number) {
    this.scales[index] = 0.92;
    setTimeout(() => {
      this.scales[index] = 1;
    }, 120);
    this.currentIndex = index;
  }

  loadLottieAnimation(index: number, canvasContext: CanvasRenderingContext2D, lottiePath: string) {
    lottie.destroy(`nav_animation_${index}`);
    try {
      lottie.loadAnimation({
        container: canvasContext,
        renderer: 'canvas',
        path: lottiePath,
        loop: true,
        autoplay: true,
        name: `nav_animation_${index}`
      });
    } catch (e) {
      console.error('Failed to load lottie animation:', e);
    }
  }

  // 选中态指示器
  @Builder
  ActiveIndicator() {
    Column() {
      Text()
        .width(18)
        .height(2.5)
        .borderRadius(1.5)
        .backgroundColor(this.COLOR_PRIMARY)
        .margin({bottom:2})
    }
    .position({ x: '50%', y: 0 })
    .markAnchor({ x: '50%', y: 0 })
    .offset({ x: 0, y: 6 })
  }

  build() {
    Column() {
      // 顶部金色渐变装饰线
      Row()
        .width('100%')
        .height(1)
        .backgroundColor(this.COLOR_BORDER)


      Row() {
        ForEach(this.items, (item: NavigationItem, index: number) => {
          Column() {
            // 选中态顶部指示器
            if (this.currentIndex === index) {
              this.ActiveIndicator()
            }

            Column() {
              // 图标区域
              if (item.lottie) {
                Canvas(this.canvasContexts[index])
                  .width(20)
                  .height(20)
                  .onReady(() => {
                    this.canvasContexts[index].imageSmoothingEnabled = true;
                    this.canvasContexts[index].imageSmoothingQuality = 'medium';
                    this.loadLottieAnimation(index, this.canvasContexts[index], item.lottie!);
                  })
              } else if (item.icon && typeof item.icon === 'object') {
                Image(item.icon as Resource)
                  .width(22)
                  .height(22)
                  .fillColor(this.currentIndex === index ? this.COLOR_PRIMARY : this.COLOR_TEXT_NORMAL)
              } else if (item.icon) {
                Text(item.icon as string)
                  .fontSize(18)
                  .fontColor(this.currentIndex === index ? this.COLOR_PRIMARY : this.COLOR_TEXT_NORMAL)
              }

              // 文字标签
              Text(item.name)
                .fontSize(11)
                .fontColor(this.currentIndex === index ? this.COLOR_PRIMARY : this.COLOR_TEXT_NORMAL)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
                .margin({ top: 2 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 8 })
          }
          .width('20%')
          .height('100%')
          .scale({ x: this.scales[index], y: this.scales[index] })
          .animation({
            duration: 120,
            curve: Curve.EaseOut
          })
          .onClick(() => {
            this.handleClick(index);
          })
        })
      }
      .width('100%')
      .height(36)
      .backgroundColor(this.COLOR_BG)
    }
    .width('100%')
    .height(36)
    .backgroundColor(this.COLOR_BG)
    .shadow({ radius: 3, color: '#00000005', offsetX: 0, offsetY: -1 })
    .zIndex(900)
  }
}
