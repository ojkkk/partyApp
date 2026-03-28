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
        
        // 获取参与者信息并计算签到人数
        if (this.canManage() && this.isActivityCreator()) {
          await this.loadCheckedCount();
        }
        
        // 检查当前用户是否已报名
        if (this.user) {
          await this.checkIfRegistered();
        }
      }
    } catch (error) {
      console.error("加载活动详情失败:", error);
      promptAction.showToast({
        message: "加载失败",
        duration: 2000
      });
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
        promptAction.showToast({
          message: "报名成功",
          duration: 2000
        });
        this.isRegistered = true;
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({
          message: response.message || "报名失败",
          duration: 2000
        });
      }
    } catch (error) {
      console.error("报名失败:", error);
      promptAction.showToast({
        message: "报名失败",
        duration: 2000
      });
    }
  }

  async cancelRegistration() {
    try {
      const response = await this.activityService.cancelRegistration(this.activityId);
      if (response.code === 200) {
        promptAction.showToast({
          message: "取消报名成功",
          duration: 2000
        });
        this.isRegistered = false;
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({
          message: response.message || "取消报名失败",
          duration: 2000
        });
      }
    } catch (error) {
      console.error("取消报名失败:", error);
      promptAction.showToast({
        message: "取消报名失败",
        duration: 2000
      });
    }
  }

  async checkIn() {
    try {
      const response = await this.activityService.checkIn(this.activityId);
      if (response.code === 200) {
        promptAction.showToast({
          message: "签到成功",
          duration: 2000
        });
        this.isCheckedIn = true;
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({
          message: response.message || "签到失败",
          duration: 2000
        });
      }
    } catch (error) {
      console.error("签到失败:", error);
      promptAction.showToast({
        message: "签到失败",
        duration: 2000
      });
    }
  }

  async uploadSummary() {
    if (!this.summary) {
      promptAction.showToast({
        message: "请输入活动总结",
        duration: 2000
      });
      return;
    }

    try {
      const response = await this.activityService.uploadSummary(this.activityId, this.summary);
      if (response.code === 200) {
        promptAction.showToast({
          message: "上传成功",
          duration: 2000
        });
        await this.loadActivityDetail();
      } else {
        promptAction.showToast({
          message: response.message || "上传失败",
          duration: 2000
        });
      }
    } catch (error) {
      console.error("上传总结失败:", error);
      promptAction.showToast({
        message: "上传失败",
        duration: 2000
      });
    }
  }

  getStatusText(status: string): string {
    if (status === 'upcoming') return '即将开始';
    if (status === 'ongoing') return '进行中';
    return '已结束';
  }

  getStatusColor(status: string): ResourceColor {
    if (status === 'upcoming') return '#FF9800';
    if (status === 'ongoing') return '#4CAF50';
    return '#9E9E9E';
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .width("100%")
        .height("100%")
        .justifyContent(FlexAlign.Center)
      } else if (!this.activity) {
        Column() {
          Text("加载失败")
            .fontSize(16)
            .fontColor("#666666")
        }
        .width("100%")
        .height("100%")
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Stack({ alignContent: Alignment.TopStart }) {
              Image(this.activity.imageUrl)
                .width("100%")
                .height(350)
                .objectFit(ImageFit.Cover)
              
              Row() {
                Image($rawfile('返回.png'))
                  .width(24)
                  .height(24)
                  .onClick(() => {
                    router.back();
                  })
              }
              .width(40)
              .height(40)
              .borderRadius(20)
              .backgroundColor('rgba(0,0,0,0.3)')
              .justifyContent(FlexAlign.Center)
              .margin({ left: 16, top: 16 })
            }
            .width('100%')

            Column() {
              Row() {
                Text(this.getStatusText(this.activity.status))
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(4)
                  .backgroundColor(this.getStatusColor(this.activity.status))
                Blank()
                if (this.canManage() && this.isActivityCreator()) {
                  Button('编辑')
                    .fontSize(14)
                    .height(32)
                    .padding({ left: 12, right: 12 })
                    .backgroundColor('#D32F2F')
                    .onClick(() => {
                      router.pushUrl({
                        url: 'pages/ActivityEditPage',
                        params: { activityId: this.activityId }
                      });
                    })
                }
              }
              .width('100%')
              .margin({ bottom: 12 })

              Text(this.activity.title)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 16 })

              Column() {
                Row() {
                  Image($rawfile('时间.png'))
                    .width(18)
                    .height(18)
                    .margin({ right: 8 })
                  Text('活动时间')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ right: 12 })
                  Text(`${this.activity.startTime} - ${this.activity.endTime}`)
                    .fontSize(14)
                    .fontColor('#333333')
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 12 })

                Row() {
                  Image($rawfile('地点.png'))
                    .width(18)
                    .height(18)
                    .margin({ right: 8 })
                  Text('活动地点')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ right: 12 })
                  Text(this.activity.location)
                    .fontSize(14)
                    .fontColor('#333333')
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 12 })

                Row() {
                  Image($rawfile('组织者.png'))
                    .width(18)
                    .height(18)
                    .margin({ right: 8 })
                  Text('组织者')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ right: 12 })
                  Text(this.activity.organizer)
                    .fontSize(14)
                    .fontColor('#333333')
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 12 })

                Row() {
                  Image($rawfile('人员报名.png'))
                    .width(18)
                    .height(18)
                    .margin({ right: 8 })
                  Text('参与人数')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ right: 12 })
                  Text(`${this.activity.participantCount || 0}/${this.activity.maxParticipants}`)
                    .fontSize(14)
                    .fontColor('#D32F2F')
                    .fontWeight(FontWeight.Medium)
                  if (this.canManage() && this.isActivityCreator() && this.activity) {
                    Button(){Image($rawfile('查看(报名).png'))
                      .height(24)
                      .width(24)}
                      .fontSize(12)
                      .height(24)
                      .padding({ left: 8, right: 8 })
                      .backgroundColor('#FFFFFF')
                      .borderWidth(0)
                      .borderColor('#D32F2F')
                      .fontColor('#D32F2F')
                      .borderRadius(12)
                      .margin({ left: 12 })
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
                .margin({ bottom: 12 })

                // 签到人数
                if (this.activity && (this.activity.status === 'ongoing' || this.activity.status === 'completed') && this.canManage() && this.isActivityCreator()) {
                  Row() {
                    Image($rawfile('签到.png'))
                      .width(18)
                      .height(18)
                      .margin({ right: 8 })
                    Text('签到人数')
                      .fontSize(14)
                      .fontColor('#666666')
                      .margin({ right: 12 })
                    Text(`${this.checkedCount}`)
                      .fontSize(14)
                      .fontColor('#4CAF50')
                      .fontWeight(FontWeight.Medium)
                    Button(){Image($rawfile('查看(签到).png'))
                        .height(24)
                        .width(24)}
                      .fontSize(12)
                      .height(24)

                      .padding({ left: 8, right: 8 })
                      .backgroundColor('#FFFFFF')
                      .borderWidth(0)
                      .borderColor('#4CAF50')
                      .fontColor('#4CAF50')
                      .borderRadius(12)
                      .margin({ left: 12 })
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
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .margin({ bottom: 12 })

              Column() {
                Text('活动内容')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 12 })
                Text(this.activity.content)
                  .fontSize(15)
                  .fontColor('#666666')
                  .lineHeight(24)
                  .width('100%')
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .margin({ bottom: 12 })

              if (this.activity.summary) {
                Column() {
                  Text('活动总结')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                    .width('100%')
                    .margin({ bottom: 12 })
                  Text(this.activity.summary)
                    .fontSize(15)
                    .fontColor('#666666')
                    .lineHeight(24)
                    .width('100%')
                  if (this.activity.summaryImageUrl) {
                    Image(this.activity.summaryImageUrl)
                      .width('100%')
                      .height(200)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                      .margin({ top: 12 })
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ bottom: 12 })
              }

              if (this.activity.status === "completed" && !this.activity.summary && this.canManage()) {
                Column() {
                  Text('上传活动总结')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                    .width('100%')
                    .margin({ bottom: 12 })
                  TextArea({
                    placeholder: "请输入活动总结...",
                    text: this.summary
                  })
                  .width("100%")
                  .height(120)
                  .onChange((value: string) => {
                    this.summary = value;
                  })
                  .margin({ bottom: 12 })
                  Button("上传总结")
                    .width("100%")
                    .height(48)
                    .fontSize(16)
                    .fontColor("#FFFFFF")
                    .backgroundColor("#D32F2F")
                    .borderRadius(8)
                    .onClick(() => {
                      this.uploadSummary();
                    })
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ bottom: 80 })
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')

        if (!this.canManage()) {
          if (this.activity.status === "upcoming") {
            if (this.isRegistered) {
              Text("已报名")
                .fontSize(16)
                .fontColor("#999999")
                .width("100%")
                .height(50)
                .textAlign(TextAlign.Center)
            } else {
              Button("立即报名")
                .width("100%")
                .height(50)
                .fontSize(16)
                .fontColor("#FFFFFF")
                .backgroundColor("#D32F2F")
                .onClick(() => {
                  this.registerActivity();
                })
            }
          } else if (this.activity.status === "ongoing" && this.isRegistered) {
            if (this.isCheckedIn) {
              Text("已签到")
                .fontSize(16)
                .fontColor("#999999")
                .width("100%")
                .height(50)
                .textAlign(TextAlign.Center)
            } else {
              Button("立即签到")
                .width("100%")
                .height(50)
                .fontSize(16)
                .fontColor("#FFFFFF")
                .backgroundColor("#4CAF50")
                .onClick(() => {
                  this.checkIn();
                })
            }
          } else if (this.activity.status === "ongoing" && !this.isRegistered) {
            Text("请先报名活动")
              .fontSize(16)
              .fontColor("#999999")
              .width("100%")
              .height(50)
              .textAlign(TextAlign.Center)
          } else {
            Text("活动已结束")
              .fontSize(16)
              .fontColor("#999999")
              .width("100%")
              .height(50)
              .textAlign(TextAlign.Center)
          }
        }
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor('#F5F5F5')
  }
}
