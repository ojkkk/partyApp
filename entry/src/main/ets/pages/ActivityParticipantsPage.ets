import { ActivityParticipant, ActivityService } from '../models/ActivityModel';
import { ApiResponse } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AvatarComponent } from '../components/AvatarComponent';

@Entry
@Component
export struct ActivityParticipantsPage {
  private activityService: ActivityService = new ActivityService();
  @State participants: Array<ActivityParticipant> = [];
  @State isLoading: boolean = false;
  private activityId: string = '';
  private type: 'all' | 'checked' = 'all';
  private activityTitle: string = '';

  async aboutToAppear() {
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params["activityId"]) {
      this.activityId = params["activityId"];
      this.type = params["type"] === 'checked' ? 'checked' : 'all';
      this.activityTitle = params["activityTitle"] || '';
      await this.loadParticipants();
    }
  }

  async loadParticipants() {
    this.isLoading = true;
    try {
      const response: ApiResponse<ActivityParticipant[]> = await this.activityService.getActivityParticipants(this.activityId);
      if (response.code === 200 && response.data) {
        if (this.type === 'checked') {
          this.participants = response.data.filter(p => p.isCheckedIn);
        } else {
          this.participants = response.data;
        }
      }
    } catch (error) {
      console.error('加载参与者失败:', error);
      promptAction.showToast({
        message: '加载失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  getTypeText(): string {
    return this.type === 'all' ? '参与人员' : '签到人员';
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($rawfile('返回.png'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })
        Text(`${this.activityTitle} - ${this.getTypeText()}列表`)
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 4,
        color: '#00000010',
        offsetX: 0,
        offsetY: 2
      })

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
        if (this.participants.length === 0) {
          Column() {
            Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=empty%20state%20illustration%20for%20participants&image_size=square')
              .width(120)
              .height(120)
              .margin({ bottom: 16 })
            Text(this.type === 'all' ? '暂无参与人员' : '暂无签到人员')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.participants, (participant: ActivityParticipant, index: number) => {
              ListItem() {
                Column() {
                  Row() {
                    AvatarComponent({
                      user: {
                        avatar: participant.avatar || '',
                        name: participant.name || participant.username || '未知'
                      },
                      avatarSize: 48
                    })
                    Column() {
                      Row() {
                        Text(participant.name || participant.username || '未知')
                          .fontSize(16)
                          .fontWeight(500)
                          .fontColor('#333333')
                        if (participant.isCheckedIn) {
                          Text('已签到')
                            .fontSize(12)
                            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                            .backgroundColor('#E8F5E9')
                            .fontColor('#388E3C')
                            .borderRadius(10)
                            .margin({ left: 12 })
                        }
                      }
                      .width('100%')
                      .margin({ bottom: 4 })
                      Row() {
                        Text(`支部: ${participant.branch || '未知'}`)
                          .fontSize(14)
                          .fontColor('#666666')
                          .margin({ right: 16 })
                        Text(`电话: ${participant.phone || '未知'}`)
                          .fontSize(14)
                          .fontColor('#666666')
                      }
                      .width('100%')
                      .margin({ bottom: 4 })
                      Row() {
                        Text(`报名时间: ${participant.registeredAt.replace('T', ' ')}`)
                          .fontSize(12)
                          .fontColor('#999999')
                      }
                      .width('100%')
                      .margin({ bottom: 4 })
                      if (participant.isCheckedIn && participant.checkInTime) {
                        Row() {
                          Text(`签到时间: ${participant.checkInTime.replace('T', ' ')}`)
                            .fontSize(12)
                            .fontColor('#999999')
                        }
                        .width('100%')
                      }
                    }
                    .width('100%')
                    .margin({ left: 12 })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                  .border({
                    width: { bottom: 1 },
                    color: { bottom: '#F0F0F0' }
                  })
                }
                .width('100%')
                .backgroundColor('#FFFFFF')
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F8F8F8')
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}
