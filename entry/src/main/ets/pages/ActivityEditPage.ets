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
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async saveActivity() {
    if (!this.title.trim()) {
      promptAction.showToast({ message: '请输入标题', duration: 2000 });
      return;
    }
    if (!this.content.trim()) {
      promptAction.showToast({ message: '请输入内容', duration: 2000 });
      return;
    }
    if (!this.location.trim()) {
      promptAction.showToast({ message: '请输入地点', duration: 2000 });
      return;
    }
    if (!this.organizer.trim()) {
      promptAction.showToast({ message: '请输入组织者', duration: 2000 });
      return;
    }
    if (!this.imageUrl.trim()) {
      promptAction.showToast({ message: '请输入图片URL', duration: 2000 });
      return;
    }
    if (!this.maxParticipants.trim()) {
      promptAction.showToast({ message: '请输入最大参与人数', duration: 2000 });
      return;
    }

    this.isSaving = true;
    try {
      const maxParticipantsNum = parseInt(this.maxParticipants);
      if (isNaN(maxParticipantsNum) || maxParticipantsNum <= 0) {
        promptAction.showToast({ message: '请输入有效的最大参与人数', duration: 2000 });
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
        status: 'upcoming'
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
          status: 'upcoming'
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
        promptAction.showToast({ message: response.message || '保存失败', duration: 2000 });
      }
    } catch (error) {
      console.error('保存失败:', error);
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.isSaving = false;
    }
  }

  // ── 字段标签 ─────────────────────────────────────────
  @Builder
  FieldLabel(label: string, required: boolean = true) {
    Row() {
      if (required) {
        Text('*')
          .fontSize(13)
          .fontColor('#B51F2E')
          .margin({ right: 3 })
      }
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#555555')
    }
    .margin({ bottom: 8 })
    .width('100%')
  }

  // ── 标题卡片 ─────────────────────────────────────────
  @Builder
  TitleCard() {
    Column() {
      this.FieldLabel('活动标题')
      TextInput({ text: this.title, placeholder: '请输入活动标题' })
        .width('100%')
        .height(46)
        .fontSize(15)
        .borderRadius(8)
        .placeholderColor('#CCCCCC')
        .onChange((value: string) => {
          this.title = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 封面图卡片 ───────────────────────────────────────
  @Builder
  ImageCard() {
    Column() {
      this.FieldLabel('封面图片')
      if (this.imageUrl) {
        Image(this.imageUrl)
          .width('100%')
          .height(180)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .margin({ bottom: 10 })
      }
      TextInput({ text: this.imageUrl, placeholder: '请输入图片 URL 地址' })
        .width('100%')
        .height(46)
        .fontSize(15)
        .borderRadius(8)
        .placeholderColor('#CCCCCC')
        .onChange((value: string) => {
          this.imageUrl = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 开始时间卡片 ─────────────────────────────────────
  @Builder
  StartTimeCard() {
    Column() {
      this.FieldLabel('开始时间')
      Row() {
        Text(this.formatDate(this.startDate))
          .fontSize(15)
          .fontColor('#1F1F1F')
          .layoutWeight(1)
        Text('›')
          .fontSize(20)
          .fontColor('#C9A45C')
      }
      .width('100%')
      .height(46)
      .padding({ left: 12, right: 12 })
      .borderRadius(8)
      .border({ width: 1, color: '#EFE7DB' })
      .backgroundColor('#FFFCF8')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.showStartDatePicker = true;
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 结束时间卡片 ─────────────────────────────────────
  @Builder
  EndTimeCard() {
    Column() {
      this.FieldLabel('结束时间')
      Row() {
        Text(this.formatDate(this.endDate))
          .fontSize(15)
          .fontColor('#1F1F1F')
          .layoutWeight(1)
        Text('›')
          .fontSize(20)
          .fontColor('#C9A45C')
      }
      .width('100%')
      .height(46)
      .padding({ left: 12, right: 12 })
      .borderRadius(8)
      .border({ width: 1, color: '#EFE7DB' })
      .backgroundColor('#FFFCF8')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.showEndDatePicker = true;
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 地点卡片 ─────────────────────────────────────────
  @Builder
  LocationCard() {
    Column() {
      this.FieldLabel('活动地点')
      TextInput({ text: this.location, placeholder: '请输入活动地点' })
        .width('100%')
        .height(46)
        .fontSize(15)
        .borderRadius(8)
        .placeholderColor('#CCCCCC')
        .onChange((value: string) => {
          this.location = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 组织者卡片 ───────────────────────────────────────
  @Builder
  OrganizerCard() {
    Column() {
      this.FieldLabel('组织者')
      TextInput({ text: this.organizer, placeholder: '请输入组织者' })
        .width('100%')
        .height(46)
        .fontSize(15)
        .borderRadius(8)
        .placeholderColor('#CCCCCC')
        .onChange((value: string) => {
          this.organizer = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 最大参与人数卡片 ─────────────────────────────────
  @Builder
  MaxParticipantsCard() {
    Column() {
      this.FieldLabel('最大参与人数')
      TextInput({ text: this.maxParticipants, placeholder: '请输入最大参与人数' })
        .width('100%')
        .height(46)
        .fontSize(15)
        .borderRadius(8)
        .type(InputType.Number)
        .placeholderColor('#CCCCCC')
        .onChange((value: string) => {
          this.maxParticipants = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 活动内容卡片 ─────────────────────────────────────
  @Builder
  ContentCard() {
    Column() {
      this.FieldLabel('活动内容')
      TextArea({ text: this.content, placeholder: '请输入活动内容' })
        .width('100%')
        .height(160)
        .fontSize(15)
        .borderRadius(8)
        .placeholderColor('#CCCCCC')
        .onChange((value: string) => {
          this.content = value;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  // ── 时间选择浮层 ─────────────────────────────────────
  @Builder
  StartDatePickerSheet() {
    Column() {
      Column() {
        Row() {
          Text('取消')
            .fontSize(15)
            .fontColor('#B51F2E')
            .onClick(() => {
              this.showStartDatePicker = false;
            })
          Blank()
          Text('选择开始时间')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
          Blank()
          Text('确定')
            .fontSize(15)
            .fontColor('#B51F2E')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.startTime = this.formatDate(this.startDate);
              this.showStartDatePicker = false;
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .border({ width: { bottom: 1 }, color: { bottom: '#EFE7DB' } })

        Text('日期')
          .fontSize(13)
          .fontColor('#888888')
          .width('100%')
          .padding({ left: 16, top: 10, bottom: 6 })

        DatePicker({
          start: new Date('2020-01-01'),
          end: new Date('2030-12-31'),
          selected: this.startDate
        })
          .onChange((value: DatePickerResult) => {
            const d = new Date(this.startDate);
            d.setFullYear(value.year ?? d.getFullYear(), value.month ?? d.getMonth(), value.day ?? d.getDate());
            this.startDate = d;
          })
          .height(180)
          .width('100%')

        Text('时间')
          .fontSize(13)
          .fontColor('#888888')
          .width('100%')
          .padding({ left: 16, top: 10, bottom: 6 })

        TimePicker({ selected: this.startDate })
          .onChange((value: TimePickerResult) => {
            const d = new Date(this.startDate);
            d.setHours(value.hour ?? d.getHours(), value.minute ?? d.getMinutes(), value.second ?? d.getSeconds());
            this.startDate = d;
          })
          .height(180)
          .width('100%')
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .backgroundColor('rgba(0,0,0,0.48)')
    .justifyContent(FlexAlign.End)
  }

  @Builder
  EndDatePickerSheet() {
    Column() {
      Column() {
        Row() {
          Text('取消')
            .fontSize(15)
            .fontColor('#B51F2E')
            .onClick(() => {
              this.showEndDatePicker = false;
            })
          Blank()
          Text('选择结束时间')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
          Blank()
          Text('确定')
            .fontSize(15)
            .fontColor('#B51F2E')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.endTime = this.formatDate(this.endDate);
              this.showEndDatePicker = false;
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .border({ width: { bottom: 1 }, color: { bottom: '#EFE7DB' } })

        Text('日期')
          .fontSize(13)
          .fontColor('#888888')
          .width('100%')
          .padding({ left: 16, top: 10, bottom: 6 })

        DatePicker({
          start: new Date('2020-01-01'),
          end: new Date('2030-12-31'),
          selected: this.endDate
        })
          .onChange((value: DatePickerResult) => {
            const d = new Date(this.endDate);
            d.setFullYear(value.year ?? d.getFullYear(), value.month ?? d.getMonth(), value.day ?? d.getDate());
            this.endDate = d;
          })
          .height(180)
          .width('100%')

        Text('时间')
          .fontSize(13)
          .fontColor('#888888')
          .width('100%')
          .padding({ left: 16, top: 10, bottom: 6 })

        TimePicker({ selected: this.endDate })
          .onChange((value: TimePickerResult) => {
            const d = new Date(this.endDate);
            d.setHours(value.hour ?? d.getHours(), value.minute ?? d.getMinutes(), value.second ?? d.getSeconds());
            this.endDate = d;
          })
          .height(180)
          .width('100%')
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .backgroundColor('rgba(0,0,0,0.48)')
    .justifyContent(FlexAlign.End)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // ── 顶部导航栏 ─────────────────────────────────
        Row() {
          Row() {
            Text('‹')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .margin({ bottom: 6 })
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor('rgba(255,255,255,0.18)')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            router.back();
          })

          Text(this.isEdit ? '编辑活动' : '新建活动')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ left: 12 })
        }
        .width('100%')
        .height(64)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .linearGradient({
          angle: 135,
          colors: [['#B51F2E', 0.0], ['#8B1520', 1.0]]
        })

        // ── 表单区 ──────────────────────────────────────
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(44)
              .height(44)
              .color('#B51F2E')
            Text('加载中...')
              .fontSize(13)
              .fontColor('#B51F2E')
              .margin({ top: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F7F4EF')
        } else {
          Scroll() {
            Column() {
              this.TitleCard()
              this.ImageCard()
              this.StartTimeCard()
              this.EndTimeCard()
              this.LocationCard()
              this.OrganizerCard()
              this.MaxParticipantsCard()
              this.ContentCard()
            }
            .padding({ left: 14, right: 14, top: 14, bottom: 100 })
          }
          .layoutWeight(1)
          .backgroundColor('#F7F4EF')
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%')
      .height('100%')

      // ── 底部保存按钮（悬浮固定） ─────────────────────
      if (!this.isLoading) {
        Column() {
          Button() {
            Row() {
              Text(this.isSaving ? '保存中...' : (this.isEdit ? '保存修改' : '发布活动'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .letterSpacing(1)
            }
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .height(50)
          .borderRadius(12)
          .linearGradient({
            angle: 90,
            colors: [['#C9292A', 0.0], ['#A01222', 1.0]]
          })
          .shadow({ radius: 8, color: '#B51F2E40', offsetX: 0, offsetY: 4 })
          .enabled(!this.isSaving)
          .onClick(() => {
            this.saveActivity();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24, top: 12 })
        .backgroundColor('#F7F4EF')
        .border({ width: { top: 1 }, color: { top: '#EFE7DB' } })
        .zIndex(99)
      }

      // ── 开始时间选择浮层 ─────────────────────────────
      if (this.showStartDatePicker) {
        this.StartDatePickerSheet()
      }

      // ── 结束时间选择浮层 ─────────────────────────────
      if (this.showEndDatePicker) {
        this.EndDatePickerSheet()
      }
    }
    .width('100%')
    .height('100%')
  }
}
