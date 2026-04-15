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
      // ── 顶部导航栏 ──────────────────────────────────────
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

        Column() {
          Text(this.activityTitle)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.getTypeText() + '列表')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.75)')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
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

      // ── 人员数量摘要条 ──────────────────────────────────
      if (!this.isLoading && this.participants.length > 0) {
        Row() {
          Row() {
            Text('共')
              .fontSize(13)
              .fontColor('#7A6040')
            Text(` ${this.participants.length} `)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#B51F2E')
            Text('人')
              .fontSize(13)
              .fontColor('#7A6040')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor('#FFF7E8')
        .border({ width: { bottom: 1 }, color: { bottom: '#EFE7DB' } })
      }

      // ── 内容区域 ────────────────────────────────────────
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
      } else if (this.participants.length === 0) {
        Column() {
          Text('暂无数据')
            .fontSize(15)
            .fontColor('#BBBBBB')
            .margin({ bottom: 8 })
          Text(this.type === 'all' ? '还没有人报名' : '还没有人签到')
            .fontSize(13)
            .fontColor('#CCCCCC')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F7F4EF')
      } else {
        List() {
          ForEach(this.participants, (participant: ActivityParticipant, index: number) => {
            ListItem() {
              Row() {
                // 头像
                AvatarComponent({
                  user: {
                    avatar: participant.avatar || '',
                    name: participant.name || participant.username || '未知'
                  },
                  avatarSize: 46
                })

                // 信息区
                Column() {
                  // 姓名 + 签到标签
                  Row() {
                    Text(participant.name || participant.username || '未知')
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1F1F1F')
                      .layoutWeight(1)
                    if (participant.isCheckedIn) {
                      Text('已签到')
                        .fontSize(11)
                        .fontColor('#2E7D32')
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .backgroundColor('#E6F4EA')
                        .borderRadius(10)
                    } else {
                      Text('未签到')
                        .fontSize(11)
                        .fontColor('#999999')
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .backgroundColor('#F0F0F0')
                        .borderRadius(10)
                    }
                  }
                  .width('100%')
                  .margin({ bottom: 4 })

                  // 支部 + 电话
                  Row() {
                    Text(participant.branch ? `支部：${participant.branch}` : '支部：未知')
                      .fontSize(12)
                      .fontColor('#666666')
                      .layoutWeight(1)
                    Text(participant.phone ? `${participant.phone}` : '')
                      .fontSize(12)
                      .fontColor('#666666')
                  }
                  .width('100%')
                  .margin({ bottom: 3 })

                  // 报名时间
                  Text(`报名：${participant.registeredAt.replace('T', ' ').substring(0, 16)}`)
                    .fontSize(11)
                    .fontColor('#AAAAAA')
                    .width('100%')

                  // 签到时间（已签到时显示）
                  if (participant.isCheckedIn && participant.checkInTime) {
                    Text(`签到：${participant.checkInTime.replace('T', ' ').substring(0, 16)}`)
                      .fontSize(11)
                      .fontColor('#AAAAAA')
                      .width('100%')
                      .margin({ top: 2 })
                  }
                }
                .layoutWeight(1)
                .margin({ left: 12 })
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .backgroundColor('#FFFFFF')
              .border({ width: { bottom: 1 }, color: { bottom: '#F0EAE0' } })
            }
          })

          // 底部留白
          ListItem() {
            Column()
              .height(24)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F7F4EF')
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF')
  }
}
