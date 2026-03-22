export interface NavigationItem {
  name: string;
  icon: string | Resource; // 👈 这里改了！支持 图片 + emoji
  component: Object;
}

@Component
export struct NavigationBar {
  public items: Array<NavigationItem> = [];
  @Link currentIndex: number;
  @State scales: number[] = [];

  aboutToAppear() {
    if (!this.items) {
      this.items = [];
    }
    for (let i = 0; i < this.items.length; i++) {
      this.scales.push(1);
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

  build() {
    Row() {
      ForEach(this.items, (item: NavigationItem, index: number) => {
        Column() {
          // ==============================================
          // 👇 核心：自动判断是图片 还是 文字/emoji
          // ==============================================
          if (typeof item.icon === 'object') {
            // 图片模式（$rawfile）
            Image(item.icon as Resource)
              .width(24)
              .height(24)
            //.color(this.currentIndex === index ? '#D32F2F' : '#666666')
          } else {
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