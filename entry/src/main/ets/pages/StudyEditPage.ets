import { StudyResource, StudyService } from '../models/StudyModel';
import { ApiResponse } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

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
  private types = ['党史学习', '专题学习'];

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
      Row() {
        Image($rawfile('返回.png'))
          .width(24)
          .height(24)
          .margin({ top:15,left: 16, right: 16 })
          .onClick(() => {
            router.back();
          })
        Text('上传学习资源')
          .fontSize(18)
          .fontWeight(700)
          .margin({top:17})
      }
      .width('100%')
      .height(56)
      .alignItems(1)
      .backgroundColor('#FFFFFF')
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: '#EEEEEE' })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Text('标题')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              // 【关键修改 1】标题改为 TextArea，删除 multiline
              TextArea({ text: this.title, placeholder: '请输入标题' })
                .width('100%')
                .height(80)
                .onChange((value: string) => {
                  this.title = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ bottom: 12 })

            Column() {
              Text('类型')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              Scroll() {
                Row() {
                  ForEach(this.types, (type: string) => {
                    Text(type)
                      .fontSize(14)
                      .fontColor(this.type === type ? '#FFFFFF' : '#333333')
                      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                      .borderRadius(20)
                      .backgroundColor(this.type === type ? '#D32F2F' : '#F5F5F5')
                      .margin({ right: 8 })
                      .onClick(() => {
                        this.type = type;
                      })
                  })
                }
              }
              .scrollable(ScrollDirection.Horizontal) // 【优化】使用枚举代替 magic number
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ bottom: 12 })

            Column() {
              Text('学习时长(分钟)')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              TextInput({ text: this.duration.toString(), placeholder: '请输入学习时长' })
                .width('100%')
                .height(48)
                .type(InputType.Number) // 【优化】限定输入类型为数字
                .onChange((value: string) => {
                  this.duration = parseInt(value) || 0;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ bottom: 12 })

            Column() {
              Text('封面图片')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })

              if (this.imageUrl) {
                Image(this.imageUrl)
                  .width('100%')
                  .height(200)
                  .objectFit(ImageFit.Cover) // 【优化】使用枚举代替 magic number
                  .borderRadius(8)
                  .margin({ bottom: 12 })
              }

              TextInput({ text: this.imageUrl, placeholder: '请输入图片URL地址' })
                .width('100%')
                .height(48)
                .onChange((value: string) => {
                  this.imageUrl = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ bottom: 12 })

            Column() {
              Text('视频URL（可选）')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              TextInput({ text: this.videoUrl, placeholder: '请输入视频URL' })
                .width('100%')
                .height(48)
                .onChange((value: string) => {
                  this.videoUrl = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ bottom: 12 })

            Column() {
              Text('内容')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              // 【关键修改 2】内容也改为 TextArea 以支持多行输入
              TextArea({ text: this.content, placeholder: '请输入内容' })
                .width('100%')
                .height(100)
                .onChange((value: string) => {
                  this.content = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ bottom: 12 })
          }
          .padding({ top: 12, bottom: 12 })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')

        Button(this.isSaving ? '上传中...' : '上传')
          .width('90%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#D32F2F')
          .borderRadius(8)
          .margin({ top: 16, bottom: 16 })
          .enabled(!this.isSaving)
          .onClick(() => {
            this.saveResource();
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}