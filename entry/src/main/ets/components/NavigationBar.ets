import lottie from '@ohos/lottie';

import util from '@ohos.util';


export interface NavigationItem {
  name: string;
  icon?: string | Resource; // 图片或emoji
  lottie?: string; // lottie动画文件路径
  component: Object;
}

@Component
export struct NavigationBar {
  public items: Array<NavigationItem> = [];
  @Link currentIndex: number;
  @State scales: number[] = [];
  private canvasContexts: CanvasRenderingContext2D[] = [];

  aboutToAppear() {
    if (!this.items) {
      this.items = [];
    }
    for (let i = 0; i < this.items.length; i++) {
      this.scales.push(1);
      // 为每个导航项创建Canvas上下文
      const settings: RenderingContextSettings = new RenderingContextSettings(true);
      this.canvasContexts[i] = new CanvasRenderingContext2D(settings);
    }
  }

  aboutToDisappear() {
    // 销毁所有lottie动画
    for (let i = 0; i < this.items.length; i++) {
      if (this.items[i].lottie) {
        lottie.destroy(`nav_animation_${i}`);
      }
    }
  }

  handleClick(index: number) {
    console.log('NavigationBar item clicked, index:', index);
    this.scales[index] = 0.9;
    setTimeout(() => {
      this.scales[index] = 1;
    }, 150);
    this.currentIndex = index;
  }

  loadLottieAnimation(index: number, canvasContext: CanvasRenderingContext2D, lottiePath: string) {
    // 销毁之前的动画
    lottie.destroy(`nav_animation_${index}`);

    try {
      // 简化实现，直接使用path加载
      // 加载新动画
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

  build() {
    Row() {
      ForEach(this.items, (item: NavigationItem, index: number) => {
        Column() {
          // ==============================================
          // 👇 核心：自动判断是lottie动画、图片还是文字/emoji
          // ==============================================
          if (item.lottie) {
            // lottie动画模式
            Canvas(this.canvasContexts[index])
              .width(24)
              .height(24)
              .onReady(() => {
                // 抗锯齿设置
                this.canvasContexts[index].imageSmoothingEnabled = true;
                this.canvasContexts[index].imageSmoothingQuality = 'medium';
                // 加载lottie动画
                this.loadLottieAnimation(index, this.canvasContexts[index], item.lottie!);
              })
          } else if (item.icon && typeof item.icon === 'object') {
            // 图片模式（$rawfile）
            Image(item.icon as Resource)
              .width(24)
              .height(24)
          } else if (item.icon) {
            // 文字 / Emoji 模式
            Text(item.icon as string)
              .fontSize(20)
              .fontColor(this.currentIndex === index ? '#D32F2F' : '#666666')
          }

          Text(item.name)
            .fontSize(12)
            .fontColor(this.currentIndex === index ? '#D32F2F' : '#666666')
        }
        .width('20%')
        .height('80px')
        .justifyContent(FlexAlign.Center)
        .scale({ x: this.scales[index], y: this.scales[index] })
        .onClick(() => {
          this.handleClick(index);
        })
      })
    }
    .height('120px')
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderWidth({ top: 1 })
    .borderColor({ top: '#EEEEEE' })
    .zIndex(900)
  }
}