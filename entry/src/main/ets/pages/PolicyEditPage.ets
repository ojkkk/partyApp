import { Policy, PolicyService } from '../models/PolicyModel';
import { ApiResponse } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct PolicyEditPage {
  private policyService: PolicyService = new PolicyService();
  @State policyId: string = '';
  @State isEdit: boolean = false;
  @State title: string = '';
  @State content: string = '';
  @State selectedType: string = '新闻动态';
  private types = ['新闻动态', '政策法规', '重要讲话', '先进典型'];
  @State publishDate: string = new Date().toISOString().split('T')[0];
  @State imageUrl: string = '';
  @State videoUrl: string = '';
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;

  async aboutToAppear() {
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params['policyId']) {
      this.policyId = params['policyId'];
      this.isEdit = true;
      await this.loadPolicy();
    }
  }

  async loadPolicy() {
    this.isLoading = true;
    try {
      const response: ApiResponse<Policy> = await this.policyService.getPolicyDetail(this.policyId);
      if (response.code === 200 && response.data) {
        const policy = response.data;
        this.title = policy.title;
        this.content = policy.content;
        this.selectedType = policy.type;
        this.publishDate = policy.publishDate;
        this.imageUrl = policy.imageUrl;
        this.videoUrl = policy.videoUrl || '';
      }
    } catch (error) {
      console.error('加载政策失败:', error);
      promptAction.showToast({
        message: '加载失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async savePolicy() {
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
    if (!this.imageUrl.trim()) {
      promptAction.showToast({
        message: '请输入图片URL',
        duration: 2000
      });
      return;
    }

    this.isSaving = true;
    try {
      const policy: Policy = {
        id: this.policyId,
        title: this.title.trim(),
        content: this.content.trim(),
        type: this.selectedType,
        publishDate: this.publishDate,
        imageUrl: this.imageUrl.trim(),
        videoUrl: this.videoUrl.trim() || undefined
      };

      let response: ApiResponse<Policy>;
      if (this.isEdit) {
        response = await this.policyService.updatePolicy(this.policyId, policy);
      } else {
        response = await this.policyService.createPolicy(policy);
      }

      if (response.code === 200) {
        promptAction.showToast({
          message: this.isEdit ? '更新成功' : '创建成功',
          duration: 2000
        });
        router.back();
      } else {
        promptAction.showToast({
          message: response.message || '保存失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('保存失败:', error);
      promptAction.showToast({
        message: '保存失败',
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
          .margin({ left: 16, right: 16 })
          .onClick(() => {
            router.back();
          })
        Text(this.isEdit ? '编辑政策' : '新建政策')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
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
              TextInput({ text: this.title, placeholder: '请输入标题' })
                .width('100%')
                .height(48)
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
                      .fontColor(this.selectedType === type ? '#FFFFFF' : '#333333')
                      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                      .borderRadius(20)
                      .backgroundColor(this.selectedType === type ? '#D32F2F' : '#F5F5F5')
                      .margin({ right: 8 })
                      .onClick(() => {
                        this.selectedType = type;
                      })
                  })
                }
              }
              .scrollable(ScrollDirection.Horizontal)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ bottom: 12 })

            Column() {
              Text('发布日期')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              TextInput({ text: this.publishDate, placeholder: '请输入发布日期' })
                .width('100%')
                .height(48)
                .onChange((value: string) => {
                  this.publishDate = value;
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
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .margin({ bottom: 12 })
              }
              
              TextInput({ text: this.imageUrl, placeholder: '请输入图片URL地址，例如：https://example.com/image.jpg' })
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
              TextArea({ text: this.content, placeholder: '请输入内容' })
                .width('100%')
                .height(200)
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

        Button(this.isSaving ? '保存中...' : '保存')
          .width('90%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#D32F2F')
          .borderRadius(8)
          .margin({ top: 16, bottom: 16 })
          .enabled(!this.isSaving)
          .onClick(() => {
            this.savePolicy();
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}
