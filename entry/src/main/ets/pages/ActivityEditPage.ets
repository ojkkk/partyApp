import { Activity, ActivityService, ActivityCreate } from '../models/ActivityModel';
import { ApiResponse } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';
@Entry
@Component
struct ActivityEditPage {
  private activityService: ActivityService = new ActivityService();
  @State activityId: string = '';
  @State isEdit: boolean = false;
  @State title: string = '';
  @State content: string = '';
  @State location: string = '';
  @State organizer: string = '';
  @State imageUrl: string = '';
  @State startTime: string = new Date().toISOString().split('T')[0] + ' 09:00:00';
  @State endTime: string = new Date().toISOString().split('T')[0] + ' 18:00:00';
  @State maxParticipants: string = '50';
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;
  @State showStartDatePicker: boolean = false;
  @State showEndDatePicker: boolean = false;
  @State startDate: Date = new Date();
  @State endDate: Date = new Date(Date.now() + 9 * 60 * 60 * 1000);

  formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  parseDate(dateStr: string): Date {
    const parts = dateStr.split(' ');
    const dateParts = parts[0].split('-');
    const timeParts = parts[1].split(':');
    return new Date(
      parseInt(dateParts[0]),
      parseInt(dateParts[1]) - 1,
      parseInt(dateParts[2]),
      parseInt(timeParts[0]),
      parseInt(timeParts[1]),
      parseInt(timeParts[2])
    );
  }

  async aboutToAppear() {
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params['activityId']) {
      this.activityId = params['activityId'];
      this.isEdit = true;
      await this.loadActivity();
    } else {
      this.startDate = new Date();
      this.startDate.setHours(9, 0, 0, 0);
      this.endDate = new Date();
      this.endDate.setHours(18, 0, 0, 0);
    }
  }

  async loadActivity() {
    this.isLoading = true;
    try {
      const response: ApiResponse<Activity> = await this.activityService.getActivityDetail(this.activityId);
      if (response.code === 200 && response.data) {
        const activity = response.data;
        this.title = activity.title;
        this.content = activity.content;
        this.location = activity.location;
        this.organizer = activity.organizer;
        this.imageUrl = activity.imageUrl;
        this.startTime = activity.startTime;
        this.endTime = activity.endTime;
        this.startDate = this.parseDate(activity.startTime);
        this.endDate = this.parseDate(activity.endTime);
        this.maxParticipants = activity.maxParticipants.toString();
      }
    } catch (error) {
      console.error('加载活动失败:', error);
      promptAction.showToast({
        message: '加载失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async saveActivity() {
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
    if (!this.location.trim()) {
      promptAction.showToast({
        message: '请输入地点',
        duration: 2000
      });
      return;
    }
    if (!this.organizer.trim()) {
      promptAction.showToast({
        message: '请输入组织者',
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
    if (!this.maxParticipants.trim()) {
      promptAction.showToast({
        message: '请输入最大参与人数',
        duration: 2000
      });
      return;
    }

    this.isSaving = true;
    try {
      const maxParticipantsNum = parseInt(this.maxParticipants);
      if (isNaN(maxParticipantsNum) || maxParticipantsNum <= 0) {
        promptAction.showToast({
          message: '请输入有效的最大参与人数',
          duration: 2000
        });
        return;
      }

      const activityData: ActivityCreate = {
        title: this.title.trim(),
        content: this.content.trim(),
        location: this.location.trim(),
        organizer: this.organizer.trim(),
        imageUrl: this.imageUrl.trim(),
        startTime: this.formatDate(this.startDate),
        endTime: this.formatDate(this.endDate),
        maxParticipants: maxParticipantsNum,
        status: 'upcoming' // 状态会自动计算，这里设置一个默认值
      };

      let response: ApiResponse<Activity>;
      if (this.isEdit) {
        const updateData: Activity = {
          id: this.activityId,
          title: activityData.title,
          content: activityData.content,
          location: activityData.location,
          organizer: activityData.organizer,
          imageUrl: activityData.imageUrl || '',
          startTime: this.formatDate(this.startDate),
          endTime: this.formatDate(this.endDate),
          maxParticipants: activityData.maxParticipants,
          participantCount: 0,
          status: 'upcoming' // 状态会自动计算，这里设置一个默认值
        };
        response = await this.activityService.updateActivity(this.activityId, updateData);
      } else {
        response = await this.activityService.createActivity(activityData);
      }

      if (response.code === 200) {
        promptAction.showToast({
          message: this.isEdit ? '更新成功' : '创建成功',
          duration: 2000
        });
        emitter.emit("refreshActivity", null);
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
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Row() {
          Image($rawfile('返回.png'))
            .width(24)
            .height(24)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              router.back();

            })
          Text(this.isEdit ? '编辑活动' : '新建活动')
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
                TextInput({ text: this.title, placeholder: '请输入活动标题' })
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
                Text('开始时间')
                  .fontSize(16)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 8 })
                Row() {
                  Text(this.formatDate(this.startDate))
                    .fontSize(16)
                    .fontColor('#333333')
                    .layoutWeight(1)
                  Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=calendar%20icon&image_size=square')
                    .width(24)
                    .height(24)
                }
                .width('100%')
                .height(48)
                .padding({ left: 12, right: 12 })
                .border({ width: 1, color: '#E0E0E0' })
                .borderRadius(8)
                .onClick(() => {
                  this.showStartDatePicker = true;
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .margin({ bottom: 12 })

              Column() {
                Text('结束时间')
                  .fontSize(16)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 8 })
                Row() {
                  Text(this.formatDate(this.endDate))
                    .fontSize(16)
                    .fontColor('#333333')
                    .layoutWeight(1)
                  Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=calendar%20icon&image_size=square')
                    .width(24)
                    .height(24)
                }
                .width('100%')
                .height(48)
                .padding({ left: 12, right: 12 })
                .border({ width: 1, color: '#E0E0E0' })
                .borderRadius(8)
                .onClick(() => {
                  this.showEndDatePicker = true;
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .margin({ bottom: 12 })

              Column() {
                Text('地点')
                  .fontSize(16)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 8 })
                TextInput({ text: this.location, placeholder: '请输入活动地点' })
                  .width('100%')
                  .height(48)
                  .onChange((value: string) => {
                    this.location = value;
                  })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .margin({ bottom: 12 })

              Column() {
                Text('组织者')
                  .fontSize(16)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 8 })
                TextInput({ text: this.organizer, placeholder: '请输入组织者' })
                  .width('100%')
                  .height(48)
                  .onChange((value: string) => {
                    this.organizer = value;
                  })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .margin({ bottom: 12 })

              Column() {
                Text('最大参与人数')
                  .fontSize(16)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 8 })
                TextInput({ text: this.maxParticipants, placeholder: '请输入最大参与人数' })
                  .width('100%')
                  .height(48)
                  .onChange((value: string) => {
                    this.maxParticipants = value;
                  })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .margin({ bottom: 12 })



              Column() {
                Text('活动内容')
                  .fontSize(16)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 8 })
                TextArea({ text: this.content, placeholder: '请输入活动内容' })
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
              this.saveActivity();
            })
        }
      }
      .width('100%')
      .height('100%')

      if (this.showStartDatePicker) {
        Column() {
          Column() {
            Row() {
              Button('取消')
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.showStartDatePicker = false;
                })
              Blank()
              Text('选择开始时间')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
              Blank()
              Button('确定')
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.startTime = this.formatDate(this.startDate);
                  this.showStartDatePicker = false;
                })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Column() {
              Text('选择日期')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8, left: 16, right: 16, top: 8 })
              
              DatePicker({
                start: new Date('2020-01-01'),
                end: new Date('2030-12-31'),
                selected: this.startDate
              })
                .onChange((value: DatePickerResult) => {
                  const newDate = new Date(this.startDate);
                  newDate.setFullYear(value.year ?? this.startDate.getFullYear(), value.month ?? this.startDate.getMonth(), value.day ?? this.startDate.getDate());
                  this.startDate = newDate;
                })
                .height(180)
                .width('100%')

              Text('选择时间')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8, left: 16, right: 16, top: 12 })
              
              TimePicker({ selected: this.startDate })
                .onChange((value: TimePickerResult) => {
                  const newDate = new Date(this.startDate);
                  newDate.setHours(value.hour ?? this.startDate.getHours(), value.minute ?? this.startDate.getMinutes(), value.second ?? this.startDate.getSeconds());
                  this.startDate = newDate;
                })
                .height(180)
                .width('100%')
            }
            .width('100%')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius({ topLeft: 16, topRight: 16 })
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.End)
      }

      if (this.showEndDatePicker) {
        Column() {
          Column() {
            Row() {
              Button('取消')
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.showEndDatePicker = false;
                })
              Blank()
              Text('选择结束时间')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
              Blank()
              Button('确定')
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.endTime = this.formatDate(this.endDate);
                  this.showEndDatePicker = false;
                })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Column() {
              Text('选择日期')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8, left: 16, right: 16, top: 8 })
              
              DatePicker({
                start: new Date('2020-01-01'),
                end: new Date('2030-12-31'),
                selected: this.endDate
              })
                .onChange((value: DatePickerResult) => {
                  const newDate = new Date(this.endDate);
                  newDate.setFullYear(value.year ?? this.endDate.getFullYear(), value.month ?? this.endDate.getMonth(), value.day ?? this.endDate.getDate());
                  this.endDate = newDate;
                })
                .height(180)
                .width('100%')

              Text('选择时间')
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8, left: 16, right: 16, top: 12 })
              
              TimePicker({ selected: this.endDate })
                .onChange((value: TimePickerResult) => {
                  const newDate = new Date(this.endDate);
                  newDate.setHours(value.hour ?? this.endDate.getHours(), value.minute ?? this.endDate.getMinutes(), value.second ?? this.endDate.getSeconds());
                  this.endDate = newDate;
                })
                .height(180)
                .width('100%')
            }
            .width('100%')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius({ topLeft: 16, topRight: 16 })
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .height('100%')
  }
}
