import { Activity, ActivityService } from '../models/ActivityModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';
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

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadActivities();
    emitter.on("refreshActivity", async () => {
      console.info("✅ 从活动编辑返回，刷新活动");
      await this.loadActivities();
    });
  }

  aboutToDisappear() {
    // 页面销毁时注销监听，防止内存泄漏和重复监听
    emitter.off("refreshActivity");
  }

  async onPageShow() {
    // 页面显示时刷新活动列表，确保从编辑页面返回时数据更新
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
        
        // 检查用户是否已报名这些活动
        if (this.user) {
          await this.checkRegisteredActivities();
        }
      }
    } catch (error) {
      console.error('加载活动失败:', error);
      promptAction.showToast({
        message: '加载活动失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async checkRegisteredActivities() {
    try {
      // 清空之前的记录
      this.registeredActivities.clear();
      this.checkedInActivities.clear();
      
      // 对于每个活动，检查用户是否已报名和签到
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
        promptAction.showToast({
          message: '删除成功',
          duration: 2000
        });
        await this.loadActivities();
      } else {
        promptAction.showToast({
          message: response.message || '删除失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('删除失败:', error);
      promptAction.showToast({
        message: '删除失败',
        duration: 2000
      });
    }
  }

  async registerActivity(id: string) {
    try {
      const response = await this.activityService.registerActivity(id);
      if (response.code === 200) {
        promptAction.showToast({
          message: '报名成功',
          duration: 2000
        });
        // 更新报名状态
        this.registeredActivities.set(id, true);
        // 更新活动的参与人数
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
        promptAction.showToast({
          message: response.message || '报名失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('报名失败:', error);
      promptAction.showToast({
        message: '报名失败',
        duration: 2000
      });
    }
  }

  async cancelRegistration(id: string) {
    try {
      const response = await this.activityService.cancelRegistration(id);
      if (response.code === 200) {
        promptAction.showToast({
          message: '取消报名成功',
          duration: 2000
        });
        // 更新报名状态
        this.registeredActivities.set(id, false);
        // 更新活动的参与人数
        const activityIndex = this.activities.findIndex(a => a.id === id);
        if (activityIndex !== -1) {
          const activity = this.activities[activityIndex];
          if (activity && activity.participantCount !== undefined && activity.participantCount > 0) {
            activity.participantCount--;
          }
        }
      } else {
        promptAction.showToast({
          message: response.message || '取消报名失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('取消报名失败:', error);
      promptAction.showToast({
        message: '取消报名失败',
        duration: 2000
      });
    }
  }

  async checkIn(id: string) {
    try {
      const response = await this.activityService.checkIn(id);
      if (response.code === 200) {
        promptAction.showToast({
          message: '签到成功',
          duration: 2000
        });
        this.checkedInActivities.set(id, true);
        await this.loadActivities();
      } else {
        promptAction.showToast({
          message: response.message || '签到失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('签到失败:', error);
      promptAction.showToast({
        message: '签到失败',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('活动管理')
          .fontSize(22)
          .fontWeight(700)
          .fontColor('#333333')
        Blank()
        if (this.canManage()) {
          Button('发布活动')
            .fontSize(14)
            .height(36)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#D32F2F')
            .borderRadius(18)
            .fontColor('#FFFFFF')
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ActivityEditPage'
              });
            })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 4,
        color: '#00000010',
        offsetX: 0,
        offsetY: 2
      })

      // 标签栏
      Row() {
        ForEach(this.tabs, (tab: string) => {
          Column() {
            Text(tab)
              .fontSize(16)
              .fontColor(this.selectedTab === tab ? '#D32F2F' : '#666666')
              .fontWeight(this.selectedTab === tab ? 600 : 400)
              .padding({ left: 24, right: 24, top: 16, bottom: 16 })
            if (this.selectedTab === tab) {
              Row() {
                Text()
                  .width(40)
                  .height(3)
                  .backgroundColor('#D32F2F')
                  .borderRadius(1.5)
              }
              .justifyContent(FlexAlign.Center)
            }
          }
          .onClick(async () => {
            this.selectedTab = tab;
            await this.loadActivities();
          })
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')

      // 内容区域
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#D32F2F')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        if (this.activities.length === 0) {
          Column() {
            Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=empty%20state%20illustration%20for%20activities&image_size=square')
              .width(120)
              .height(120)
              .margin({ bottom: 16 })
            Text('暂无活动')
              .fontSize(16)
              .fontColor('#999999')
            Text(this.selectedTab === '活动列表' ? '还没有发布任何活动' : '还没有参与任何活动')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .margin({ top: 8 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.activities, (activity: Activity, index: number) => {
              ListItem() {
                Column() {
                  // 活动图片
                  Image(activity.imageUrl)
                    .width('100%')
                    .height(200)
                    .objectFit(ImageFit.Cover)
                  
                  // 活动信息
                  Column() {
                    // 活动标题和状态
                    Row() {
                      Text(activity.title)
                        .fontSize(18)
                        .fontWeight(600)
                        .fontColor('#333333')
                        .flexGrow(1)
                      Text(activity.status === 'upcoming' ? '即将开始' : activity.status === 'ongoing' ? '进行中' : '已结束')
                        .fontSize(12)
                        .padding({ left:8, right: 8, top: 4, bottom: 4 })
                        .backgroundColor(activity.status === 'upcoming' ? '#E3F2FD' : activity.status === 'ongoing' ? '#E8F5E9' : '#F5F5F5')
                        .fontColor(activity.status === 'upcoming' ? '#1976D2' : activity.status === 'ongoing' ? '#388E3C' : '#757575')
                        .borderRadius(12)
                    }
                    .width('100%')
                    .margin({ top: 16 })
                    
                    // 活动详情
                    Row() {
                      Image($rawfile('时间.png'))
                        .width(16)
                        .height(16)
                        .margin({ right: 8 })
                      Text(`时间: ${activity.startTime}`)
                        .fontSize(14)
                        .fontColor('#666666')
                    }
                    .width('100%')
                    .margin({ top: 12 })
                    
                    Row() {
                      Image($rawfile('地点.png'))
                        .width(16)
                        .height(16)
                        .margin({ right: 8 })
                      Text(`地点: ${activity.location}`)
                        .fontSize(14)
                        .fontColor('#666666')
                    }
                    .width('100%')
                    .margin({ top: 8 })
                    
                    Row() {
                      Image($rawfile('人员报名.png'))
                        .width(16)
                        .height(16)
                        .margin({ right: 8 })
                      Text(`报名: ${activity.participantCount || 0}/${activity.maxParticipants}`)
                        .fontSize(14)
                        .fontColor('#D32F2F')
                    }
                    .width('100%')
                    .margin({ top: 8 })
                    
                    // 操作按钮
                    Row() {
                      Blank()
                      if (this.canManage() && this.isActivityCreator(activity)) {
                        Button('编辑')
                          .fontSize(14)
                          .height(32)
                          .padding({ left: 16, right: 16 })
                          .backgroundColor('#FFFFFF')
                          .borderWidth(1)
                          .borderColor('#FF3B30')
                          .fontColor('#FF3B30')
                          .borderRadius(16)
                          .margin({ right: 12 })
                          .onClick(() => {
                            router.pushUrl({
                              url: 'pages/ActivityEditPage',
                              params: { activityId: activity.id }
                            });
                          })
                        Button('删除')
                          .fontSize(14)
                          .height(32)
                          .padding({ left: 16, right: 16 })
                          .backgroundColor('#FFFFFF')
                          .borderWidth(1)
                          .borderColor('#FF3B30')
                          .fontColor('#FF3B30')
                          .borderRadius(16)
                          .onClick(() => {
                            this.deleteActivity(activity.id);
                          })
                      } else {
                        if (activity.status === 'upcoming') {
                          if (this.isRegistered(activity.id)) {
                            Button('已报名')
                              .fontSize(14)
                              .height(32)
                              .padding({ left: 20, right: 20 })
                              .backgroundColor('#FFFFFF')
                              .borderWidth(1)
                              .borderColor('#999999')
                              .fontColor('#666666')
                              .borderRadius(16)
                          } else {
                            Button('立即报名')
                              .fontSize(14)
                              .height(32)
                              .padding({ left: 20, right: 20 })
                              .backgroundColor('#D32F2F')
                              .fontColor('#FFFFFF')
                              .borderRadius(16)
                              .onClick(() => {
                                this.registerActivity(activity.id);
                              })
                          }
                        } else if (activity.status === 'ongoing' && this.isRegistered(activity.id)) {
                          if (this.isCheckedIn(activity.id)) {
                            Button('已签到')
                              .fontSize(14)
                              .height(32)
                              .padding({ left: 20, right: 20 })
                              .backgroundColor('#FFFFFF')
                              .borderWidth(1)
                              .borderColor('#999999')
                              .fontColor('#666666')
                              .borderRadius(16)
                          } else {
                            Button('立即签到')
                              .fontSize(14)
                              .height(32)
                              .padding({ left: 20, right: 20 })
                              .backgroundColor('#388E3C')
                              .fontColor('#FFFFFF')
                              .borderRadius(16)
                              .onClick(() => {
                                this.checkIn(activity.id);
                              })
                          }
                        } else if (activity.status === 'ongoing' && !this.isRegistered(activity.id)) {
                          Button('请先报名')
                            .fontSize(14)
                            .height(32)
                            .padding({ left: 20, right: 20 })
                            .backgroundColor('#FFFFFF')
                            .borderWidth(1)
                            .borderColor('#999999')
                            .fontColor('#666666')
                            .borderRadius(16)
                        } else {
                          Button('查看详情')
                            .fontSize(14)
                            .height(32)
                            .padding({ left: 20, right: 20 })
                            .backgroundColor('#FFFFFF')
                            .borderWidth(1)
                            .borderColor('#999999')
                            .fontColor('#666666')
                            .borderRadius(16)
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
                    .margin({ top: 16 })
                  }
                  .padding({ left: 16, right: 16, bottom: 16 })
                }
                .width('100%')
                .backgroundColor('#FFFFFF')
                .margin({ left: 0, right: 16, top: 16 })
                .borderRadius(12)
                .shadow({
                  radius: 8,
                  color: '#00000015',
                  offsetX: 0,
                  offsetY: 4
                })
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/ActivityDetailPage',
                    params: { activityId: activity.id }
                  });
                })
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F8F8F8')
          .padding({ top: 8, bottom: 20 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}
