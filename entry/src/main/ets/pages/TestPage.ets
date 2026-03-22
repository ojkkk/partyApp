import router from '@ohos.router';

@Entry
@Component
struct TestPage {
  @State inputText: string = '';

  build() {
    Column() {
      Text('测试页面')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: '50px', bottom: '30px' })

      // 修复核心：补充TextInput的关键样式
      TextInput({ placeholder: '请输入内容...' })
        .width('80%')
        .height('200px')
        .fontSize(40) // 必加：设置输入文字大小（默认可能为0或极小）
        .fontColor('#333433') // 必加：设置输入文字颜色（与背景对比明显）
        .backgroundColor('#FFFFFF') // 必加：输入框背景色（与文字色区分）
        .placeholderColor('#999999') // 可选：优化占位符颜色
        .borderRadius(8) // 可选：增加圆角，提升视觉体验
        .padding({ left: 10, right: 10 }) // 可选：文字内边距，避免贴边
        .onChange((value: string) => {
          this.inputText = value;
        })


      Text('输入的内容:')
        .fontSize(16)
        .margin({ top: '30px' })

      Text(this.inputText)
        .fontSize(20)
        .fontColor('#007AFF')
        .margin({ top: '10px' })

      Button('去登录页')
        .width('60%')
        .height('45px')
        .margin({ top: '50px' })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/LoginPage'
          });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}