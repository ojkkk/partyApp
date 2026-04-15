import { Activity, ActivityService, ActivityParticipant } from "../models/ActivityModel";
import { ApiResponse, UserInfo } from "../models/UserModel";
import { StorageService } from '../services/StorageService';
import router from "@ohos.router";
import promptAction from "@ohos.promptAction";

@Entry
@Component
export struct ActivityDetailPage {
  private activityService: ActivityService = new ActivityService();
  @State activity: Activity | null = null;
  private activityId: string = "";
  @State summary: string = "";
  @State isLoading: boolean = false;
  @State user: UserInfo | null = null;
  @State checkedCount: number = 0;
  @State isRegistered: boolean = false;
  @State isCheckedIn: boolean = false;

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params["activityId"]) {
      this.activityId = params["activityId"];
      await this.loadActivityDetail();
    }
  }

  canManage(): boolean {
    return this.user?.role === 'admin' || this.user?.role === 'branch_admin';
  }

  isActivityCreator(): boolean {
    return this.activity?.createdBy === this.user?.id;
  }

  async loadActivityDetail() {
    this.isLoading = true;
    try {
      const response: ApiResponse<Activity> = await this.activityService.getActivityDetail(this.activityId);
      if (response.code === 200 && response.data) {
        this.activity = response.data;
        if (this.canManage() && this.isActivityCreator()) {
          await this.loadCheckedCount();
        }
        if (this.user) {
          await this.checkIfRegistered();
        }
      }
    } catch (error) {
      console.error("加载活动详情失败:", error);
      promptAction.showToast({ message: "加载失败", duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async checkIfRegistered() {
    try {
      const response: ApiResponse<ActivityParticipant[]> = await this.activityService.getActivityParticipants(this.activityId);
      if (response.code === 200 && response.data && this.user) {
        const userId = this.user.id;
        if (userId) {
          const participant = response.data.find(p => p.userId === userId);
          this.isRegistered = participant !== undefined;
          this.isCheckedIn = participant?.isCheckedIn || false;
        }
      }
    } catch (error) {
      console.error("检查报名状态失败:", error);
    }
  }

  async loadCheckedCount() {
    try {
      const response: ApiResponse<ActivityParticipant[]> = await this.activityService.getActivityParticipants(this.activityId);
      if (response.code === 200 && response.data) {
        this.checkedCount = response.data.filter(p => p.isCheckedIn).length;
      }
    } catch (error) {
      console.error("加载签到人数失败:", error);
    }
  }

  async registerActivity() {
    try {
      const response = await this.activityService.registerActivity(this.activityId);
      if (response.code === 200) {
        promptAction.showToast({ message: "报名成功", duration: 2000 });
        this.isRegistered = true;
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({ message: response.message || "报名失败", duration: 2000 });
      }
    } catch (error) {
      console.error("报名失败:", error);
      promptAction.showToast({ message: "报名失败", duration: 2000 });
    }
  }

  async cancelRegistration() {
    try {
      const response = await this.activityService.cancelRegistration(this.activityId);
      if (response.code === 200) {
        promptAction.showToast({ message: "取消报名成功", duration: 2000 });
        this.isRegistered = false;
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({ message: response.message || "取消报名失败", duration: 2000 });
      }
    } catch (error) {
      console.error("取消报名失败:", error);
      promptAction.showToast({ message: "取消报名失败", duration: 2000 });
    }
  }

  async checkIn() {
    try {
      const response = await this.activityService.checkIn(this.activityId);
      if (response.code === 200) {
        promptAction.showToast({ message: "签到成功", duration: 2000 });
        this.isCheckedIn = true;
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({ message: response.message || "签到失败", duration: 2000 });
      }
    } catch (error) {
      console.error("签到失败:", error);
      promptAction.showToast({ message: "签到失败", duration: 2000 });
    }
  }

  async uploadSummary() {
    if (!this.summary) {
      promptAction.showToast({ message: "请输入活动总结", duration: 2000 });
      return;
    }
    try {
      const response = await this.activityService.uploadSummary(this.activityId, this.summary);
      if (response.code === 200) {
        promptAction.showToast({ message: "上传成功", duration: 2000 });
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({ message: response.message || "上传失败", duration: 2000 });
      }
    } catch (error) {
      console.error("上传总结失败:", error);
      promptAction.showToast({ message: "上传失败", duration: 2000 });
    }
  }

  getStatusText(status: string): string {
    if (status === 'upcoming') return '即将开始';
    if (status === 'ongoing') return '进行中';
    return '已结束';
  }

  getStatusBgColor(status: string): string {
    if (status === 'upcoming') return '#FFF6E8';
    if (status === 'ongoing') return '#F0FBF0';
    return '#F5F5F5';
  }

  getStatusTextColor(status: string): string {
    if (status === 'upcoming') return '#B07B26';
    if (status === 'ongoing') return '#2D7A3C';
    return '#8C8C8C';
  }

  getStatusBorderColor(status: string): string {
    if (status === 'upcoming') return '#E8C97A';
    if (status === 'ongoing') return '#8DC89E';
    return '#D6D6D6';
  }

  @Builder
  SectionTitle(title: string, showEdit: boolean = false) {
    Row() {
      Row()
        .width(4)
        .height(18)
        .borderRadius(2)
        .linearGradient({
          angle: 180,
          colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
        })
        .margin({ right: 10 })

      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F1F1F')

      Blank()

      // 编辑按钮（仅管理员可见）
      if (showEdit && this.canManage() && this.isActivityCreator()) {
        Button() {
          Row() {
            Image($rawfile('编辑普通.png'))
              .width(13)
              .height(13)
              .margin({ right: 4 })
            Text('编辑')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#C9A45C')
          }
        }
        .height(28)
        .padding({ left: 10, right: 10 })
        .backgroundColor('#FFFAF5')
        .border({ width: 1, color: '#E8D5B5' })
        .borderRadius(14)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ActivityEditPage',
            params: { activityId: this.activityId }
          });
        })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 14 })
  }

  @Builder
  InfoRow(icon: Resource, label: string, value: string) {
    Row() {
      Row() {
        Image(icon)
          .width(15)
          .height(15)
          .opacity(0.55)
      }
      .width(28)
      .height(28)
      .borderRadius(8)
      .backgroundColor('#F7F2EC')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ right: 10 })

      Text(label)
        .fontSize(13)
        .fontColor('#999999')
        .width(64)
        .flexShrink(0)

      Text(value)
        .fontSize(14)
        .fontColor('#1F1F1F')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#B51F2E')
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12 })
          }
          .padding({ top: 28, bottom: 28 })
          .width(160)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .border({ width: 1, color: '#EFE7DB' })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F7F4EF')
      } else if (!this.activity) {
        Column() {
          Text('暂无内容')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F7F4EF')
      } else {
        Scroll() {
          Column() {

            // ── 封面图 + 顶部导航栏 ──
            Stack({ alignContent: Alignment.TopStart }) {
              Image(this.activity.imageUrl)
                .width('100%')
                .height(280)
                .objectFit(ImageFit.Cover)

              // 遮罩，底部渐变过渡
              Column()
                .width('100%')
                .height(280)
                .linearGradient({
                  angle: 180,
                  colors: [['#00000012', 0.0], ['#00000022', 0.5], ['#00000055', 1.0]]
                })

              // 顶部导航：返回按钮
              Row() {
                Row() {
                  Image($rawfile('返回.png'))
                    .width(20)
                    .height(20)
                    .opacity(0.9)
                }
                .width(38)
                .height(38)
                .borderRadius(19)
                .backgroundColor('#00000036')
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  router.back();
                })

                Blank()
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 48 })
              .alignItems(VerticalAlign.Center)

              // 封面底部：活动标题 + 状态标签
              Column() {
                Row() {
                  Text(this.getStatusText(this.activity.status))
                    .fontSize(12)
                    .fontColor(this.getStatusTextColor(this.activity.status))
                    .fontWeight(FontWeight.Medium)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor(this.getStatusBgColor(this.activity.status))
                    .border({ width: 1, color: this.getStatusBorderColor(this.activity.status) })
                    .borderRadius(12)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Text(this.activity.title)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2E2E2E')
                  .width('100%')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding({ left: 18, right: 18, bottom: 20 })
              .alignItems(HorizontalAlign.Start)
              .position({ x: 0, y: 196 })
            }
            .width('100%')
            .height(280)
            .clip(true)

            // ── 活动信息卡片 ──
            Column() {
              this.SectionTitle('活动信息', true)

              Column() {
                this.InfoRow($rawfile('时间.png'), '开始时间', this.activity.startTime)
                Divider()
                  .color('#F3EBDD')
                  .strokeWidth(1)
                  .margin({ top: 10, bottom: 10 })
                this.InfoRow($rawfile('时间.png'), '结束时间', this.activity.endTime)
                Divider()
                  .color('#F3EBDD')
                  .strokeWidth(1)
                  .margin({ top: 10, bottom: 10 })
                this.InfoRow($rawfile('地点.png'), '活动地点', this.activity.location)
                Divider()
                  .color('#F3EBDD')
                  .strokeWidth(1)
                  .margin({ top: 10, bottom: 10 })
                this.InfoRow($rawfile('组织者.png'), '组织者', this.activity.organizer)
              }
              .width('100%')
              .padding({ left: 14, right: 14, top: 14, bottom: 14 })
              .backgroundColor('#FFFCF8')
              .borderRadius(14)
              .border({ width: 1, color: '#F3EBDD' })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 4 })

            // ── 参与情况卡片 ──
            Column() {
              this.SectionTitle('参与情况')

              Column() {
                // 参与人数
                Row() {
                  Row() {
                    Image($rawfile('人员报名.png'))
                      .width(15)
                      .height(15)
                      .opacity(0.55)
                  }
                  .width(28)
                  .height(28)
                  .borderRadius(8)
                  .backgroundColor('#F7F2EC')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .margin({ right: 10 })

                  Text('参与人数')
                    .fontSize(13)
                    .fontColor('#999999')
                    .width(64)
                    .flexShrink(0)

                  Text(`${this.activity.participantCount || 0} / ${this.activity.maxParticipants} 人`)
                    .fontSize(14)
                    .fontColor('#B51F2E')
                    .fontWeight(FontWeight.Bold)
                    .layoutWeight(1)

                  if (this.canManage() && this.isActivityCreator() && this.activity) {
                    Button() {
                      Row() {
                        Image($rawfile('查看(报名).png'))
                          .width(14)
                          .height(14)
                          .opacity(0.8)
                          .margin({ right: 4 })
                        Text('查看名单')
                          .fontSize(12)
                          .fontColor('#9A7B46')
                      }
                    }
                    .height(30)
                    .padding({ left: 10, right: 10 })
                    .backgroundColor('#FFF7E8')
                    .border({ width: 1, color: '#E8D0A2' })
                    .borderRadius(15)
                    .onClick(() => {
                      router.pushUrl({
                        url: 'pages/ActivityParticipantsPage',
                        params: {
                          activityId: this.activity!.id,
                          type: 'all',
                          activityTitle: this.activity!.title
                        }
                      });
                    })
                  }
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                // 报名进度条
                Column() {
                  Stack() {
                    Row()
                      .width('100%')
                      .height(6)
                      .borderRadius(6)
                      .backgroundColor('#F2E8D8')

                    Row()
                      .width(this.activity.maxParticipants > 0
                        ? `${Math.min(100, Math.round(((this.activity.participantCount || 0) / this.activity.maxParticipants) * 100))}%`
                        : '0%')
                      .height(6)
                      .borderRadius(6)
                      .linearGradient({
                        angle: 90,
                        colors: [['#E7C77D', 0.0], ['#D83A34', 0.3], ['#B51F2E', 1.0]]
                      })
                  }
                  .alignContent(Alignment.Start)
                  .width('100%')
                }
                .width('100%')
                .margin({ top: 10 })

                // 签到人数（管理员可见）
                if (this.activity && (this.activity.status === 'ongoing' || this.activity.status === 'completed')
                  && this.canManage() && this.isActivityCreator()) {
                  Divider()
                    .color('#F3EBDD')
                    .strokeWidth(1)
                    .margin({ top: 12, bottom: 12 })

                  Row() {
                    Row() {
                      Image($rawfile('签到.png'))
                        .width(15)
                        .height(15)
                        .opacity(0.55)
                    }
                    .width(28)
                    .height(28)
                    .borderRadius(8)
                    .backgroundColor('#F0FAF0')
                    .justifyContent(FlexAlign.Center)
                    .alignItems(VerticalAlign.Center)
                    .margin({ right: 10 })

                    Text('签到人数')
                      .fontSize(13)
                      .fontColor('#999999')
                      .width(64)
                      .flexShrink(0)

                    Text(`${this.checkedCount} 人`)
                      .fontSize(14)
                      .fontColor('#2D7A3C')
                      .fontWeight(FontWeight.Bold)
                      .layoutWeight(1)

                    Button() {
                      Row() {
                        Image($rawfile('查看(签到).png'))
                          .width(14)
                          .height(14)
                          .opacity(0.8)
                          .margin({ right: 4 })
                        Text('签到名单')
                          .fontSize(12)
                          .fontColor('#2D7A3C')
                      }
                    }
                    .height(30)
                    .padding({ left: 10, right: 10 })
                    .backgroundColor('#F0FAF0')
                    .border({ width: 1, color: '#9DD4AA' })
                    .borderRadius(15)
                    .onClick(() => {
                      router.pushUrl({
                        url: 'pages/ActivityParticipantsPage',
                        params: {
                          activityId: this.activity!.id,
                          type: 'checked',
                          activityTitle: this.activity!.title
                        }
                      });
                    })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                }
              }
              .width('100%')
              .padding({ left: 14, right: 14, top: 14, bottom: 14 })
              .backgroundColor('#FFFCF8')
              .borderRadius(14)
              .border({ width: 1, color: '#F3EBDD' })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 4 })

            // ── 活动内容卡片 ──
            Column() {
              this.SectionTitle('活动内容')

              Text(this.activity.content)
                .fontSize(15)
                .fontColor('#3A3A3A')
                .lineHeight(26)
                .width('100%')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 4 })

            // ── 活动总结卡片 ──
            if (this.activity.summary) {
              Column() {
                this.SectionTitle('活动总结')

                Text(this.activity.summary)
                  .fontSize(15)
                  .fontColor('#3A3A3A')
                  .lineHeight(26)
                  .width('100%')

                if (this.activity.summaryImageUrl) {
                  Image(this.activity.summaryImageUrl)
                    .width('100%')
                    .height(200)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(12)
                    .margin({ top: 14 })
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 20, bottom: 4 })
            }

            // ── 上传总结区域（管理员，已结束且无总结时显示）──
            if (this.activity.status === 'completed' && !this.activity.summary && this.canManage()) {
              Column() {
                this.SectionTitle('上传活动总结')

                TextArea({
                  placeholder: '请输入活动总结内容...',
                  text: this.summary
                })
                .width('100%')
                .height(130)
                .fontSize(14)
                .fontColor('#1F1F1F')
                .placeholderColor('#AAAAAA')
                .backgroundColor('#F7F4EF')
                .borderRadius(12)
                .border({ width: 1, color: '#E8DDD0' })
                .padding({ left: 12, right: 12, top: 12, bottom: 12 })
                .onChange((value: string) => {
                  this.summary = value;
                })
                .margin({ bottom: 14 })

                Button() {
                  Row() {
                    Image($rawfile('上传.png'))
                      .width(16)
                      .height(16)
                      .opacity(0.9)
                      .margin({ right: 6 })
                    Text('提交总结')
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FFFFFF')
                  }
                }
                .width('100%')
                .height(50)
                .linearGradient({
                  angle: 90,
                  colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
                })
                .borderRadius(12)
                .shadow({ radius: 10, color: '#B51F2E28', offsetX: 0, offsetY: 4 })
                .onClick(() => {
                  this.uploadSummary();
                })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 20, bottom: 4 })
            }

            // 底部安全留白
            Row().height(100)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor('#F7F4EF')
        .scrollBar(BarState.Off)

        // ── 底部操作栏（普通成员） ──
        if (!this.canManage()) {
          Column() {
            Divider()
              .color('#EFE7DB')
              .strokeWidth(1)

            Row() {
              if (this.activity.status === 'upcoming') {
                if (this.isRegistered) {
                  Row() {
                    Text('✓')
                      .fontSize(16)
                      .fontColor('#B51F2E')
                      .margin({ right: 6 })
                    Text('已报名')
                      .fontSize(15)
                      .fontColor('#B51F2E')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                } else {
                  Button('立即报名')
                    .width('100%')
                    .height(50)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .linearGradient({
                      angle: 90,
                      colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
                    })
                    .borderRadius(12)
                    .shadow({ radius: 10, color: '#B51F2E28', offsetX: 0, offsetY: 4 })
                    .onClick(() => {
                      this.registerActivity();
                    })
                }
              } else if (this.activity.status === 'ongoing' && this.isRegistered) {
                if (this.isCheckedIn) {
                  Row() {
                    Text('✓')
                      .fontSize(16)
                      .fontColor('#2D7A3C')
                      .margin({ right: 6 })
                    Text('已签到')
                      .fontSize(15)
                      .fontColor('#2D7A3C')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                } else {
                  Button('立即签到')
                    .width('100%')
                    .height(50)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#2D7A3C')
                    .borderRadius(12)
                    .shadow({ radius: 10, color: '#2D7A3C26', offsetX: 0, offsetY: 4 })
                    .onClick(() => {
                      this.checkIn();
                    })
                }
              } else if (this.activity.status === 'ongoing' && !this.isRegistered) {
                Row() {
                  Text('活动进行中，未报名')
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                Row() {
                  Text('活动已结束')
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF')
  }
}
