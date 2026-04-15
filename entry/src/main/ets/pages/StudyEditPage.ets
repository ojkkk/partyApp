import { StudyResource, StudyService } from '../models/StudyModel';
import { ApiResponse } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

// ─────────────────────────────────────────────────────────────────────────────
// 设计规范（庄重红金正式风）
//  主色        #B51F2E  绛红
//  强调色      #D83A34  亮红
//  金色        #C9A45C  暖金
//  深金        #A67C2E  深金
//  背景        #F7F4EF  米白底
//  卡片背景    #FFFFFF  纯白
//  文字主色    #1F1F1F  深灰黑
//  文字副色    #666666  中灰
//  文字弱色    #999999  浅灰
//  分割线      #EFE7DB  暖灰金
// ─────────────────────────────────────────────────────────────────────────────

@Entry
@Component
export struct StudyEditPage {
  private studyService: StudyService = new StudyService();
  @State title: string = '';
  @State type: string = '党史学习';
  @State content: string = '';
  @State duration: number = 0;
  @State imageUrl: string = '';
  @State videoUrl: string = '';
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;

  async saveResource() {
    if (!this.title.trim()) {
      promptAction.showToast({
        message: '请输入标题',
        duration: 2000
      });
      return;
    }
    if (!this.content.trim()) {
      promptAction.showToast({
        message: '请输入内容',
        duration: 2000
      });
      return;
    }
    if (this.duration <= 0) {
      promptAction.showToast({
        message: '请输入有效的学习时长',
        duration: 2000
      });
      return;
    }

    this.isSaving = true;
    try {
      const resource: StudyResource = {
        id: '',
        title: this.title.trim(),
        type: this.type,
        content: this.content.trim(),
        duration: this.duration,
        imageUrl: this.imageUrl.trim() || 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=study%20resource%20placeholder&image_size=square',
        videoUrl: this.videoUrl.trim() || undefined
      };

      const response = await this.studyService.createResource(resource);
      if (response.code === 200) {
        promptAction.showToast({
          message: '上传成功',
          duration: 2000
        });
        emitter.emit("refreshStudy", null);
        router.back();
      } else {
        promptAction.showToast({
          message: '上传失败: ' + response.message,
          duration: 2000
        });
      }
    } catch (error) {
      console.error('上传失败:', error);
      promptAction.showToast({
        message: '上传失败',
        duration: 2000
      });
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Column() {
      // ===================== 【沉浸式渐变 Header】 =====================
      Stack({ alignContent: Alignment.TopStart }) {
        // 渐变背景
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 155,
            colors: [['#D83A34', 0.0], ['#B51F2E', 0.56], ['#8E1824', 1.0]]
          });

        // 顶部金色装饰线
        Column()
          .width('100%')
          .height(3)
          .backgroundColor('#FFFFFF')
          .opacity(0.5)
          .position({ x: 0, y: 0 });

        // 装饰圆形
        Column()
          .width(180)
          .height(180)
          .borderRadius(90)
          .backgroundColor('#FFFFFF')
          .opacity(0.06)
          .position({ x: 260, y: -60 });

        Column()
          .width(100)
          .height(100)
          .borderRadius(50)
          .backgroundColor('#FFFFFF')
          .opacity(0.10)
          .position({ x: 320, y: 20 });

        // 返回按钮和标题
        Row() {
          Row() {
            Text('‹')
              .fontSize(28)
              .fontColor('#FFFFFF')
              .margin({ bottom: 6 })
              .onClick(() => {
                emitter.emit("refreshStudy", null);
                router.back();
              })
          }.width(40);
          Row() {
            Text('上传学习资源')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }.flexGrow(1)
          .justifyContent(FlexAlign.Center)

          Row().width(40);
        }
        .padding({ left: 16, top: 16, right: 16 })
        .width('100%')
        .height(60)
        .position({ x: 0, y: 0 });
      }
      .width('100%')
      .height(60);

      // ===================== 【表单区域】 =====================
      Scroll() {
        Column() {
          // 标题字段
          this.FormCard('标题', '请输入标题', true, this.title, (v: string) => {
            this.title = v;
          })

          // 类型（固定）
          this.TypeFixedCard()

          // 学习时长
          this.FormCardNumber('学习时长(分钟)', '请输入学习时长', true)

          // 封面图片
          this.ImageCard()

          // 视频URL
          this.FormCard('视频URL（可选）', '请输入视频URL', false, this.videoUrl, (v: string) => {
            this.videoUrl = v;
          })

          // 内容
          this.ContentCard()
        }
        .padding({ top: 12, bottom: 100 })
      }
      .layoutWeight(1)
      .backgroundColor('#F7F4EF');

      // ===================== 【悬浮保存按钮】 =====================
      Stack({ alignContent: Alignment.Bottom }) {
        Button(this.isSaving ? '上传中...' : '确认上传')
          .width('90%')
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .linearGradient({
            angle: 90,
            colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
          })
          .borderRadius(25)
          .shadow({
            radius: 12,
            color: '#B51F2E35',
            offsetX: 0,
            offsetY: 4
          })
          .margin({ bottom: 20 })
          .enabled(!this.isSaving)
          .onClick(() => {
            this.saveResource();
          });
      }
      .width('100%')
      .backgroundColor('#F7F4EF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }

  // ===================== 【表单卡片 Builder】 =====================
  @Builder
  FormCard(label: string, placeholder: string, required: boolean, value: string, onChange: (v: string) => void) {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor('#B51F2E')
          .margin({ right: 8 });
        Text(label)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F');
        if (required) {
          Text('*')
            .fontSize(15)
            .fontColor('#D83A34')
            .margin({ left: 4 });
        }
      }
      .alignItems(VerticalAlign.Center)
      .margin({ left: -4, bottom: 10 });

      TextArea({ text: value, placeholder: placeholder })
        .width('100%')
        .height(80)
        .backgroundColor('#FAFAFA')
        .borderRadius(10)
        .padding(12)
        .fontColor('#1F1F1F')
        .placeholderColor('#999999')
        .onChange(onChange);
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }

  // ===================== 【数字输入卡片 Builder】 =====================
  @Builder
  FormCardNumber(label: string, placeholder: string, required: boolean) {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor('#B51F2E')
          .margin({ right: 8 });
        Text(label)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F');
        if (required) {
          Text('*')
            .fontSize(15)
            .fontColor('#D83A34')
            .margin({ left: 4 });
        }
      }
      .alignItems(VerticalAlign.Center)
      .margin({ left: -4, bottom: 10 });

      TextInput({ text: this.duration.toString(), placeholder: placeholder })
        .width('100%')
        .height(48)
        .type(InputType.Number)
        .backgroundColor('#FAFAFA')
        .borderRadius(10)
        .padding({ left: 12, right: 12 })
        .fontColor('#1F1F1F')
        .placeholderColor('#999999')
        .onChange((value: string) => {
          this.duration = parseInt(value) || 0;
        });
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }

  // ===================== 【固定类型显示卡片 Builder】 =====================
  @Builder
  TypeFixedCard() {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor('#B51F2E')
          .margin({ right: 8 });
        Text('类型')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F');
      }
      .alignItems(VerticalAlign.Center)
      .margin({ left: -4, bottom: 10 });

      Row() {
        Text('党史学习')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .borderRadius(20)
          .backgroundColor('#B51F2E')
          .border({ width: 1, color: '#B51F2E' });
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }

  // ===================== 【图片卡片 Builder】 =====================
  @Builder
  ImageCard() {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor('#B51F2E')
          .margin({ right: 8 });
        Text('封面图片')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F');
      }
      .alignItems(VerticalAlign.Center)
      .margin({ left: -4, bottom: 10 });

      if (this.imageUrl) {
        Image(this.imageUrl)
          .width('100%')
          .height(180)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ bottom: 12 });
      }

      TextInput({ text: this.imageUrl, placeholder: '请输入图片URL地址' })
        .width('100%')
        .height(48)
        .backgroundColor('#FAFAFA')
        .borderRadius(10)
        .padding({ left: 12, right: 12 })
        .fontColor('#1F1F1F')
        .placeholderColor('#999999')
        .onChange((value: string) => {
          this.imageUrl = value;
        });
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }

  // ===================== 【内容卡片 Builder】 =====================
  @Builder
  ContentCard() {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor('#B51F2E')
          .margin({ right: 8 });
        Text('内容')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F');
        Text('*')
          .fontSize(15)
          .fontColor('#D83A34')
          .margin({ left: 4 });
      }
      .alignItems(VerticalAlign.Center)
      .margin({ left: -4, bottom: 10 });

      TextArea({ text: this.content, placeholder: '请输入内容' })
        .width('100%')
        .height(120)
        .backgroundColor('#FAFAFA')
        .borderRadius(10)
        .padding(12)
        .fontColor('#1F1F1F')
        .placeholderColor('#999999')
        .onChange((value: string) => {
          this.content = value;
        });
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }
}