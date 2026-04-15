import { StudyService } from '../models/StudyModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

interface UserStudyStats {
  userId: string;
  username: string;
  name: string;
  role: string;
  branch: string;
  totalCourses: number;
  completedCourses: number;
  totalDuration: number;
  totalProgress: number;
  studyDuration: number;
}

@Entry
@Component
export struct BranchStatsPage {
  private studyService: StudyService = new StudyService();
  @State allUserStats: UserStudyStats[] = [];
  @State isLoading: boolean = false;
  @State userRole: string = '';
  @State userBranch: string = '';

  // 总统计数据
  @State totalCourses: number = 0;
  @State completedCourses: number = 0;
  @State totalDuration: number = 0;
  @State avgProgress: number = 0;

  aboutToAppear() {
    this.checkUserRole();
  }

  async checkUserRole() {
    const userInfo = await StorageService.getItemAsync<UserInfo>('user');
    if (userInfo) {
      this.userRole = userInfo.role;
      this.userBranch = userInfo.branch;
      this.loadAllUserStats();
    }
  }

  async loadAllUserStats() {
    this.isLoading = true;
    try {
      const response = await this.studyService.getAllUserStudyStats();
      if (response.code === 200 && response.data) {
        let stats = response.data as UserStudyStats[];
        // branch_admin 只能看自己支部的普通成员统计
        if (this.userRole === 'branch_admin') {
          stats = stats.filter(user => user.role === 'member' && user.branch === this.userBranch);
        }
        this.allUserStats = stats;
        // 计算总统计
        this.totalCourses = this.allUserStats.reduce((sum, u) => sum + u.totalCourses, 0);
        this.completedCourses = this.allUserStats.reduce((sum, u) => sum + u.completedCourses, 0);
        this.totalDuration = this.allUserStats.reduce((sum, u) => sum + (u.studyDuration || 0), 0);
        this.avgProgress = this.allUserStats.length > 0
          ? Math.round(this.allUserStats.reduce((sum, u) => sum + u.totalProgress, 0) / this.allUserStats.length)
          : 0;
      } else {
        promptAction.showToast({
          message: '加载失败: ' + response.message,
          duration: 2000
        });
      }
    } catch (error) {
      console.error('加载所有用户学习统计失败:', error);
      promptAction.showToast({
        message: '加载失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // ===================== 【顶栏】 =====================
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .margin({ right: 8, bottom: 6 })
          .onClick(() => router.back());

        Text('支部学习统计')
          .fontSize(18)
          .fontWeight(700)
          .fontColor('#FFFFFF');

        Blank();

        if (this.allUserStats.length > 0) {
          Text(`共 ${this.allUserStats.length} 人`)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#C85049')
            .borderRadius(12);
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#B51F2E')
      .alignItems(VerticalAlign.Center);

      // ===================== 【内容区】 =====================
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#B51F2E');
        }
        .width('100%')
        .flexGrow(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.allUserStats.length === 0) {
        // 空状态
        Column() {
          Text('📊')
            .fontSize(48);
          Text('暂无学习统计数据')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 });
        }
        .width('100%')
        .flexGrow(1)
        .justifyContent(FlexAlign.Center);
      } else {
        // 有数据时：总体概况 + 用户列表
        Column() {
          Row() {
            Row() {
              Row()
                .width(4)
                .height(14)
                .borderRadius(2)
                .backgroundColor('#B51F2E')
                .margin({ right: 8 });
              Text('总体概况')
                .fontSize(15)
                .fontWeight(700)
                .fontColor('#1F1F1F');
            }
            .flexGrow(1);

            Text(this.userBranch)
              .fontSize(11)
              .fontColor('#B51F2E')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor('#FFF1F1')
              .borderRadius(10);
          }
          .width('100%')
          .margin({ bottom: 12 });

          Row() {
            Column() {
              Text(this.totalCourses.toString())
                .fontSize(20)
                .fontWeight(700)
                .fontColor('#B51F2E');
              Text('总课程')
                .fontSize(11)
                .fontColor('#999999');
            }
            .flexGrow(1);

            Column() {
              Text(this.completedCourses.toString())
                .fontSize(20)
                .fontWeight(700)
                .fontColor('#B51F2E');
              Text('已完成')
                .fontSize(11)
                .fontColor('#999999');
            }
            .flexGrow(1);

            Column() {
              Text(this.totalDuration.toString())
                .fontSize(20)
                .fontWeight(700)
                .fontColor('#B51F2E');
              Text('总时长')
                .fontSize(11)
                .fontColor('#999999');
            }
            .flexGrow(1);

            Column() {
              Text(this.avgProgress + '%')
                .fontSize(20)
                .fontWeight(700)
                .fontColor('#B51F2E');
              Text('平均进度')
                .fontSize(11)
                .fontColor('#999999');
            }
            .flexGrow(1);
          }
          .width('100%');
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .margin({ left: 12, right: 12, top: 12, bottom: 12 })
        .borderRadius(10)
        .border({ width: 1, color: '#EFE7DB' });

        Scroll() {
          Column() {
            // 成员列表标题
            Row() {
              Row()
                .width(4)
                .height(14)
                .borderRadius(2)
                .backgroundColor('#C9A45C')
                .margin({ right: 8 });
              Text('支部成员')
                .fontSize(15)
                .fontWeight(700)
                .fontColor('#1F1F1F');
            }
            .width('100%')
            .margin({ left: 12, right: 12, bottom: 10 });

            ForEach(this.allUserStats, (user: UserStudyStats) => {
              Column() {
                Row() {
                  Text(user.name)
                    .fontSize(16)
                    .fontWeight(500)
                    .fontColor('#333333')
                    .flexGrow(1);
                  Text(user.role === 'member' ? '党员' : user.role === 'branch_admin' ? '支书' : '管理员')
                    .fontSize(12)
                    .fontColor(user.role === 'admin' || user.role === 'branch_admin' ? '#FFFFFF' : '#666666')
                    .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                    .backgroundColor(user.role === 'admin' ? '#B51F2E' : user.role === 'branch_admin' ? '#D83A34' : '#F5F5F5')
                    .borderRadius(10);
                }
                .width('100%')
                .margin({ bottom: 8 });

                // 进度条
                Column() {
                  Row() {
                    Column()
                      .width(user.totalProgress + '%')
                      .height(6)
                      .backgroundColor('#B51F2E')
                      .borderRadius(3);
                    Blank();
                  }
                  .width('100%');
                }
                .margin({ bottom: 10 });

                Row({ space: 16 }) {
                  Column() {
                    Text('总课程')
                      .fontSize(10)
                      .fontColor('#999999')
                      .margin({ bottom: 2 });
                    Text(user.totalCourses.toString())
                      .fontSize(13)
                      .fontWeight(500)
                      .fontColor('#333333');
                  }
                  .alignItems(HorizontalAlign.Start);

                  Column() {
                    Text('已完成')
                      .fontSize(10)
                      .fontColor('#999999')
                      .margin({ bottom: 2 });
                    Text(user.completedCourses.toString())
                      .fontSize(13)
                      .fontWeight(500)
                      .fontColor('#B51F2E');
                  }
                  .alignItems(HorizontalAlign.Start);

                  Column() {
                    Text('学习时长')
                      .fontSize(10)
                      .fontColor('#999999')
                      .margin({ bottom: 2 });
                    Text(user.studyDuration + '分钟')
                      .fontSize(13)
                      .fontWeight(500)
                      .fontColor('#333333');
                  }
                  .alignItems(HorizontalAlign.Start);

                  Column() {
                    Text('进度')
                      .fontSize(10)
                      .fontColor('#999999')
                      .margin({ bottom: 2 });
                    Text(user.totalProgress + '%')
                      .fontSize(13)
                      .fontWeight(500)
                      .fontColor('#B51F2E');
                  }
                  .alignItems(HorizontalAlign.Start);
                }
                .width('100%');
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#FFFFFF')
              .margin({ left: 12, right: 12, bottom: 10 })
              .borderRadius(8)
              .border({ width: 1, color: '#EFE7DB' });
            });

            Blank().height(20);
          }
          .padding({ top: 10, bottom: 20 });
        }
        .width('100%')
        .flexGrow(1)
        .backgroundColor('#F7F4EF')
        .align(Alignment.TopStart);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }
}
