import { Activity, ActivityService } from '../models/ActivityModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

// 删除确认对话框
@CustomDialog
struct ConfirmDeleteDialog {
  controller: CustomDialogController;
  title: string = '确认删除';
  message: string = '确定要删除该项吗？此操作不可撤销。';
  onConfirm?: () => void;

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F1F1F')
        .margin({ bottom: 12 });

      Text(this.message)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 24 });

      Row() {
        Button('取消')
          .width(100)
          .height(40)
          .fontSize(15)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
          });

        Button('确定删除')
          .width(100)
          .height(40)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor('#B51F2E')
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
            if (this.onConfirm) {
              this.onConfirm();
            }
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16);
  }
}

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

@Component
struct StatusBadge {
  @Prop status: string = '';

  private getLabel(): string {
    if (this.status === 'upcoming') return '即将开始';
    if (this.status === 'ongoing') return '进行中';
    return '已结束';
  }

  private getBgColor(): string {
    if (this.status === 'upcoming') return '#FFF6E8';
    if (this.status === 'ongoing') return '#FFF1F1';
    return '#F5F5F5';
  }

  private getTextColor(): string {
    if (this.status === 'upcoming') return '#A67C2E';
    if (this.status === 'ongoing') return '#B51F2E';
    return '#8F8F8F';
  }

  private getBorderColor(): string {
    if (this.status === 'upcoming') return '#E6C98C';
    if (this.status === 'ongoing') return '#E7B3B3';
    return '#DEDEDE';
  }

  build() {
    Row() {
      Text()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(this.getTextColor())
        .margin({ right: 6 })
      Text(this.getLabel())
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getTextColor())
    }
    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
    .backgroundColor(this.getBgColor())
    .borderRadius(13)
    .border({ width: 1, color: this.getBorderColor() })
  }
}

@Entry
@Component
export struct ActivityPage {
  @State selectedTab: string = '活动列表';
  private tabs = ['活动列表', '我的活动'];
  private activityService: ActivityService = new ActivityService();
  @State activities: Array<Activity> = [];
  @State isLoading: boolean = false;
  @State user: UserInfo | null = null;
  @State registeredActivities: Map<string, boolean> = new Map();
  @State checkedInActivities: Map<string, boolean> = new Map();
  // 筛选状态: 'all' | 'ongoing' | 'upcoming' | 'completed'
  @State filterType: string = 'all';

  // 删除确认对话框控制器
  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDeleteDialog({
      onConfirm: () => {}
    }),
    isModal: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadActivities();
    emitter.on('refreshActivity', async () => {
      console.info('✅ 从活动编辑返回，刷新活动');
      await this.loadActivities();
    });
  }

  aboutToDisappear() {
    emitter.off('refreshActivity');
  }

  async onPageShow() {
    if (this.user) {
      await this.loadActivities();
    }
  }

  canManage(): boolean {
    return this.user?.role === 'admin' || this.user?.role === 'branch_admin';
  }

  isActivityCreator(activity: Activity): boolean {
    return activity.createdBy === this.user?.id;
  }

  isRegistered(activityId: string): boolean {
    return this.registeredActivities.get(activityId) || false;
  }

  isCheckedIn(activityId: string): boolean {
    return this.checkedInActivities.get(activityId) || false;
  }

  getUpcomingCount(): number {
    return this.activities.filter(item => item.status === 'upcoming').length;
  }

  getOngoingCount(): number {
    return this.activities.filter(item => item.status === 'ongoing').length;
  }

  getEndedCount(): number {
    return this.activities.filter(item => item.status === 'completed').length;
  }

  getProgressPercent(activity: Activity): number {
    if (!activity.maxParticipants || activity.maxParticipants <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(((activity.participantCount || 0) / activity.maxParticipants) * 100));
  }

  getRoleLabel(): string {
    if (this.user?.role === 'admin' || this.user?.role === 'branch_admin') {
      return '当前身份：活动管理者';
    }
    return '当前身份：活动参与者';
  }

  async loadActivities() {
    this.isLoading = true;
    try {
      let response: ApiResponse<Activity[]>;
      if (this.selectedTab === '我的活动') {
        response = await this.activityService.getMyActivities();
      } else {
        response = await this.activityService.getActivities();
      }
      if (response.code === 200 && response.data) {
        this.activities = response.data;
        if (this.user) {
          await this.checkRegisteredActivities();
        }
      }
    } catch (error) {
      console.error('加载活动失败:', error);
      promptAction.showToast({ message: '加载活动失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async checkRegisteredActivities() {
    try {
      this.registeredActivities.clear();
      this.checkedInActivities.clear();
      for (const activity of this.activities) {
        const response = await this.activityService.getActivityParticipants(activity.id);
        if (response.code === 200 && response.data && this.user) {
          const userId = this.user.id;
          if (userId) {
            const participant = response.data.find(p => p.userId === userId);
            const isRegistered = participant !== undefined;
            const isCheckedIn = participant?.isCheckedIn || false;
            this.registeredActivities.set(activity.id, isRegistered);
            this.checkedInActivities.set(activity.id, isCheckedIn);
          }
        }
      }
    } catch (error) {
      console.error('检查报名状态失败:', error);
    }
  }

  async deleteActivity(id: string) {
    try {
      const response = await this.activityService.deleteActivity(id);
      if (response.code === 200) {
        promptAction.showToast({ message: '删除成功', duration: 2000 });
        await this.loadActivities();
      } else {
        promptAction.showToast({ message: response.message || '删除失败', duration: 2000 });
      }
    } catch (error) {
      console.error('删除失败:', error);
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    }
  }

  async registerActivity(id: string) {
    try {
      const response = await this.activityService.registerActivity(id);
      if (response.code === 200) {
        promptAction.showToast({ message: '报名成功', duration: 2000 });
        this.registeredActivities.set(id, true);
        const activityIndex = this.activities.findIndex(a => a.id === id);
        if (activityIndex !== -1) {
          const activity = this.activities[activityIndex];
          if (activity) {
            if (activity.participantCount === undefined) {
              activity.participantCount = 1;
            } else {
              activity.participantCount++;
            }
          }
        }
      } else {
        promptAction.showToast({ message: response.message || '报名失败', duration: 2000 });
      }
    } catch (error) {
      console.error('报名失败:', error);
      promptAction.showToast({ message: '报名失败', duration: 2000 });
    }
  }

  async cancelRegistration(id: string) {
    try {
      const response = await this.activityService.cancelRegistration(id);
      if (response.code === 200) {
        promptAction.showToast({ message: '取消报名成功', duration: 2000 });
        this.registeredActivities.set(id, false);
        const activityIndex = this.activities.findIndex(a => a.id === id);
        if (activityIndex !== -1) {
          const activity = this.activities[activityIndex];
          if (activity && activity.participantCount !== undefined && activity.participantCount > 0) {
            activity.participantCount--;
          }
        }
      } else {
        promptAction.showToast({ message: response.message || '取消报名失败', duration: 2000 });
      }
    } catch (error) {
      console.error('取消报名失败:', error);
      promptAction.showToast({ message: '取消报名失败', duration: 2000 });
    }
  }

  async checkIn(id: string) {
    try {
      const response = await this.activityService.checkIn(id);
      if (response.code === 200) {
        promptAction.showToast({ message: '签到成功', duration: 2000 });
        this.checkedInActivities.set(id, true);
        await this.loadActivities();
      } else {
        promptAction.showToast({ message: response.message || '签到失败', duration: 2000 });
      }
    } catch (error) {
      console.error('签到失败:', error);
      promptAction.showToast({ message: '签到失败', duration: 2000 });
    }
  }

  @Builder
  StatCard(label: string, value: string, type: string, accent: boolean = false) {
    Column() {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.filterType === type ? '#B51F2E' : (accent ? '#B51F2E' : '#2A2A2A'))
        .margin({ bottom: 6 })
      Text(label)
        .fontSize(12)
        .fontColor(this.filterType === type ? '#B51F2E' : (accent ? '#A3473B' : '#7A7A7A'))
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.filterType === type ? '#FFF1F1' : (accent ? '#FFF7F3' : '#FFFCF8'))
    .borderRadius(12)
    .border({ width: 1, color: this.filterType === type ? '#B51F2E' : (accent ? '#E8C8B9' : '#EFE7DB') })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.setFilter(type))
  }

  // ===================== 【设置筛选】 =====================
  private setFilter(type: string) {
    this.filterType = type;
  }

  // ===================== 【获取筛选后的活动列表】 =====================
  private getFilteredActivities(): Activity[] {
    if (this.filterType === 'all') return this.activities;
    return this.activities.filter(a => a.status === this.filterType);
  }

  @Builder
  InfoRow(icon: Resource, label: string, value: string, highlight: boolean = false) {
    Row() {
      Row() {
        Image(icon)
          .width(14)
          .height(14)
          .opacity(highlight ? 0.9 : 0.58)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(highlight ? '#FFF1F1' : '#F7F4EF')
      .justifyContent(FlexAlign.Center)
      .margin({ right: 10 })

      Text(label)
        .fontSize(13)
        .fontColor('#888888')
        .margin({ right: 6 })

      Text(value)
        .fontSize(13)
        .fontColor(highlight ? '#B51F2E' : '#555555')
        .fontWeight(highlight ? FontWeight.Medium : FontWeight.Regular)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  OverviewPanel() {
    Column() {
      Row() {
        Row() {
          Row()
            .width(4)
            .height(16)
            .borderRadius(2)
            .backgroundColor('#B51F2E')
            .margin({ right: 8 })
          Text('活动总览')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2A2A2A')
        }
        .layoutWeight(1)

        Text(this.getRoleLabel())
          .fontSize(12)
          .fontColor('#9A7B46')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 })
          .backgroundColor('#FFF7E8')
          .borderRadius(12)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 14 })

      Row() {
        Column() {
          this.StatCard('活动总数', `${this.activities.length}`, 'all', true)
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          this.StatCard('进行中', `${this.getOngoingCount()}`, 'ongoing')
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          this.StatCard('即将开始', `${this.getUpcomingCount()}`, 'upcoming')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
    .margin({ top: 14, bottom: 6 })
  }

  @Builder
  ActivityCard(activity: Activity) {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(activity.imageUrl)
          .width('100%')
          .height(188)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 18, topRight: 18 })

        Column()
          .width('100%')
          .height(188)
          .linearGradient({
            angle: 180,
            colors: [['#00000000', 0.0], ['#00000018', 0.56], ['#00000036', 1.0]]
          })
          .borderRadius({ topLeft: 18, topRight: 18 })

        Row() {
          Text(this.selectedTab === '我的活动' ? '我的参与' : '活动展示')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#00000026')
            .borderRadius(12)

          Blank()

          StatusBadge({ status: activity.status })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14 })
      }
      .width('100%')
      .height(188)

      Column() {
        Row() {
          Column()
            .width(4)
            .height(24)
            .borderRadius(2)
            .linearGradient({
              angle: 180,
              colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
            })
            .margin({ right: 10 })

          Text(activity.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 14 })

        Row() {
          Text(activity.status === 'ongoing' ? '现场组织有序进行中' : activity.status === 'upcoming' ? '活动准备阶段，可提前报名参与' : '活动已结束，可查看详情回顾')
            .fontSize(12)
            .fontColor('#9A7B46')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#FFF7E8')
            .borderRadius(12)
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column() {
          this.InfoRow($rawfile('时间.png'), '活动时间', activity.startTime)
          Divider().color('#F3EBDD').strokeWidth(1).margin({ top: 10, bottom: 10 })
          this.InfoRow($rawfile('地点.png'), '活动地点', activity.location)
          Divider().color('#F3EBDD').strokeWidth(1).margin({ top: 10, bottom: 10 })
          this.InfoRow($rawfile('人员报名.png'), '报名情况', `${activity.participantCount || 0} / ${activity.maxParticipants} 人`, true)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .backgroundColor('#FFFCF8')
        .borderRadius(14)
        .border({ width: 1, color: '#F3EBDD' })
        .margin({ bottom: 16 })

        Column() {
          Row() {
            Text('参与进度')
              .fontSize(13)
              .fontColor('#777777')

            Blank()

            Text(`${this.getProgressPercent(activity)}%`)
              .fontSize(12)
              .fontColor('#B51F2E')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Stack() {
            Row()
              .width('100%')
              .height(8)
              .borderRadius(8)
              .backgroundColor('#F2E8D8')

            Row()
              .width(`${this.getProgressPercent(activity)}%`)
              .height(8)
              .borderRadius(8)
              .linearGradient({
                angle: 90,
                colors: [['#E7C77D', 0.0], ['#D83A34', 0.2], ['#B51F2E', 1.0]]
              })
          }
          .alignContent(Alignment.Start)
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 18 })

        Row() {
          Blank()

          if (this.canManage() && this.isActivityCreator(activity)) {
            Button() {
              Row() {
                Image($rawfile('编辑普通.png'))
                  .width(14)
                  .height(14)
                  .opacity(0.85)
                  .margin({ right: 6 })
                Text('编辑')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#B51F2E')
              }
            }
            .height(38)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFF8F5')
            .border({ width: 1, color: '#D8B36A' })
            .borderRadius(10)
            .margin({ right: 10 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ActivityEditPage',
                params: { activityId: activity.id }
              });
            })

            Button() {
              Row() {
                Image($rawfile('删除.png'))
                  .width(14)
                  .height(14)
                  .opacity(0.78)
                  .margin({ right: 6 })
                Text('删除')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#B51F2E')
              }
            }
            .height(38)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFF1F1')
            .border({ width: 1, color: '#E3B3B3' })
            .borderRadius(10)
            .onClick(() => {
              promptAction.showDialog({
                title: '确认删除',
                message: '确定要删除这个活动吗？此操作不可撤销。',
                buttons: [
                  { text: '删除', color: '#B51F2E' },
                  { text: '取消', color: '#999999' }
                ]
              }).then((value) => {
                if (value.index === 0) {
                  this.deleteActivity(activity.id);
                }
              });
            })
          } else {
            if (activity.status === 'upcoming') {
              if (this.isRegistered(activity.id)) {
                Button('✓ 已报名')
                  .fontSize(13)
                  .height(38)
                  .padding({ left: 18, right: 18 })
                  .fontColor('#B51F2E')
                  .backgroundColor('#FFF4F2')
                  .border({ width: 1, color: '#E2B6AC' })
                  .borderRadius(10)
              } else {
                Button('立即报名')
                  .fontSize(13)
                  .height(38)
                  .padding({ left: 18, right: 18 })
                  .fontColor('#FFFFFF')
                  .linearGradient({
                    angle: 90,
                    colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
                  })
                  .borderRadius(10)
                  .shadow({ radius: 10, color: '#B51F2E28', offsetX: 0, offsetY: 4 })
                  .onClick(() => {
                    this.registerActivity(activity.id);
                  })
              }
            } else if (activity.status === 'ongoing' && this.isRegistered(activity.id)) {
              if (this.isCheckedIn(activity.id)) {
                Button('✓ 已签到')
                  .fontSize(13)
                  .height(38)
                  .padding({ left: 18, right: 18 })
                  .fontColor('#2E7D32')
                  .backgroundColor('#F3FAF1')
                  .border({ width: 1, color: '#B8D8B9' })
                  .borderRadius(10)
              } else {
                Button('立即签到')
                  .fontSize(13)
                  .height(38)
                  .padding({ left: 18, right: 18 })
                  .fontColor('#FFFFFF')
                  .backgroundColor('#2E7D32')
                  .borderRadius(10)
                  .shadow({ radius: 8, color: '#2E7D3226', offsetX: 0, offsetY: 4 })
                  .onClick(() => {
                    this.checkIn(activity.id);
                  })
              }
            } else if (activity.status === 'ongoing' && !this.isRegistered(activity.id)) {
              Button('请先报名')
                .fontSize(13)
                .height(38)
                .padding({ left: 18, right: 18 })
                .fontColor('#999999')
                .backgroundColor('#F5F2EE')
                .border({ width: 1, color: '#E6DFD5' })
                .borderRadius(10)
            } else {
              Button('查看详情')
                .fontSize(13)
                .height(38)
                .padding({ left: 18, right: 18 })
                .fontColor('#B51F2E')
                .backgroundColor('#FFF8F5')
                .border({ width: 1, color: '#D8B36A' })
                .borderRadius(10)
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/ActivityDetailPage',
                    params: { activityId: activity.id }
                  });
                })
            }
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 18 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 18, bottomRight: 18 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .border({ width: 1, color: '#EFE7DB' })
    .clip(true)
    .shadow({ radius: 12, color: '#00000012', offsetX: 0, offsetY: 6 })
    .margin({ bottom: 16 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/ActivityDetailPage',
        params: { activityId: activity.id }
      });
    })
  }

  @Builder
  EmptyState() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(104)
          .height(104)
          .borderRadius(52)
          .linearGradient({
            angle: 180,
            colors: [['#FFF6EA', 0.0], ['#F9EBD2', 1.0]]
          })

        Column()
          .width(72)
          .height(72)
          .borderRadius(36)
          .backgroundColor('#FFFFFF')
          .shadow({ radius: 10, color: '#C9A45C22', offsetX: 0, offsetY: 4 })

        Text('文')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#B51F2E')
      }
      .margin({ bottom: 20 })

      Text('暂无活动内容')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2A2A2A')
        .margin({ bottom: 8 })

      Text(this.selectedTab === '活动列表' ? '当前还没有发布任何活动，后续内容将在此展示。' : '你暂时还没有参与的活动，去列表中看看吧。')
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .padding({ left: 36, right: 36 })
    }
    .width('100%')
    .height('80%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 155,
            colors: [['#D83A34', 0.0], ['#B51F2E', 0.56], ['#8E1824', 1.0]]
          })

        Column()
          .width('100%')
          .height(4)
          .backgroundColor('#E6C98C')
          .opacity(0.9)
          .position({ x: 0, y: 0 })

        Column()
          .width(168)
          .height(168)
          .borderRadius(84)
          .backgroundColor('#FFFFFF')
          .opacity(0.07)
          .position({ x: 254, y: -52 })

        Column()
          .width(94)
          .height(94)
          .borderRadius(47)
          .backgroundColor('#FFFFFF')
          .opacity(0.08)
          .position({ x: 318, y: 26 })

        // 左上角：标题和当前浏览（大字）
        Column() {
          Text('活动管理')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .letterSpacing(1)

          Text(this.selectedTab === '活动列表' ? '当前浏览：全部活动' : '当前浏览：我的活动')
            .fontSize(12)
            .fontColor('#FFFFFF70')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, top: 20 })

        // 右下角：发布按钮
        Row() {
          if (this.canManage()) {
            Button() {
              Row() {
                Text('＋')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#A3202D')
                  .margin({ right: 3 })
                Text('发布')
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#A3202D')
              }
            }
            .height(28)
            .padding({ left: 10, right: 10 })
            .backgroundColor('#FFF8F1')
            .border({ width: 1, color: '#F0D7A5' })
            .borderRadius(6)
            .shadow({ radius: 6, color: '#00000015', offsetX: 0, offsetY: 3 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/ActivityEditPage' });
            })
          }
        }
        .padding({ right: 16, bottom: 12 })
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: '100%', y: '100%' })

        // 左下角：统计信息
        Row() {
          Text(`共 ${this.activities.length} 项活动`)
            .fontSize(11)
            .fontColor('#8C5D13')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#FFF4DE')
            .border({ width: 1, color: '#F0D29A' })
            .borderRadius(10)
        }
        .padding({ left: 16, bottom: 12 })
        .position({ x: 0, y: '100%' })
        .markAnchor({ x: 0, y: '100%' })
      }
      .width('100%')
      .height(150)

      Row() {
        ForEach(this.tabs, (tab: string) => {
          Column() {
            Text(tab)
              .fontSize(15)
              .fontWeight(this.selectedTab === tab ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.selectedTab === tab ? '#B51F2E' : '#7A7A7A')
              .padding({ left: 22, right: 22, top: 12, bottom: 10 })

            Row()
              .width(this.selectedTab === tab ? 42 : 24)
              .height(3)
              .borderRadius(3)
              .backgroundColor(this.selectedTab === tab ? '#B51F2E' : '#00000000')
          }
          .padding({ bottom: 8 })
          .layoutWeight(1)
          .backgroundColor(this.selectedTab === tab ? '#FFF8F3' : '#FFFFFF')
          .borderRadius(12)
          .onClick(async () => {
            this.selectedTab = tab;
            await this.loadActivities();
          })
        })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14, bottom: 0 })
      .backgroundColor('#F7F4EF')
      .justifyContent(FlexAlign.SpaceBetween)

      if (this.isLoading) {
        Column() {
          Column() {
            LoadingProgress()
              .width(42)
              .height(42)
              .color('#B51F2E')
            Text('内容加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 14 })
          }
          .padding({ top: 28, bottom: 28 })
          .width(180)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .border({ width: 1, color: '#EFE7DB' })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F7F4EF')
      } else if (this.activities.length === 0) {
        Column() {
          this.EmptyState()
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F7F4EF')
      } else {
        List({ space: 0 }) {
          ListItem() {
            Column() {
              this.OverviewPanel()
            }
            .padding({ left: 14, right: 14 })
          }

          ListItem() {
            Row() {
              Row() {
                Row()
                  .width(3)
                  .height(14)
                  .borderRadius(2)
                  .backgroundColor('#B51F2E')
                  .margin({ right: 8 })
                Text(`为你整理了 ${this.getFilteredActivities().length} 项活动内容`)
                  .fontSize(13)
                  .fontColor('#666666')
              }

              Blank()

              if (this.filterType !== 'all') {
                Text(`已筛选: ${this.filterType === 'ongoing' ? '进行中' : '即将开始'}`)
                  .fontSize(12)
                  .fontColor('#B51F2E')
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .backgroundColor('#FFF1F1')
                  .borderRadius(10)
                  .margin({ right: 8 })
                  .onClick(() => this.setFilter('all'));
              }


            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          }

          ForEach(this.getFilteredActivities(), (activity: Activity) => {
            ListItem() {
              Column() {
                this.ActivityCard(activity)
              }
              .padding({ left: 14, right: 14 })
            }
          })

          ListItem() {
            Row().height(28)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F7F4EF')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF')
  }
}
