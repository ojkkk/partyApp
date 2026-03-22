import { StudyService } from '../models/StudyModel';
import { ApiResponse } from '../models/UserModel';
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
  studyDuration: number; // 真实学习时长（分钟）
}

@Entry
@Component
export struct StudyStatsPage {
  private studyService: StudyService = new StudyService();
  @State allUserStats: UserStudyStats[] = [];
  @State isLoading: boolean = false;
  @State userRole: string = '';
  @State userBranch: string = '';

  async aboutToAppear() {
    await this.checkUserRole();
    await this.loadAllUserStats();
  }

  async checkUserRole() {
    interface UserInfo {
      role: string;
      branch: string;
    }
    const userInfo = await StorageService.getItemAsync<UserInfo>('user');
    if (userInfo) {
      this.userRole = userInfo.role;
      this.userBranch = userInfo.branch;
    }
  }

  async loadAllUserStats() {
    this.isLoading = true;
    try {
      // 调用后端API获取所有用户的学习统计
      const response = await this.studyService.getAllUserStudyStats();
      if (response.code === 200 && response.data) {
        let stats = response.data as UserStudyStats[];
        
        // 根据用户角色过滤数据
        if (this.userRole === 'branch_admin') {
          // 支部管理员只能看到普通党员的学习统计
          stats = stats.filter(user => user.role === 'member' && user.branch === this.userBranch);
        } else if (this.userRole === 'admin') {
          // 系统管理员可以看到所有人的学习统计
          // 不需要过滤
        }
        
        this.allUserStats = stats;
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
      Row() {
        Image($rawfile('返回.png'))
          .width(24)
          .height(24)
          .margin({ top:15,left: 16, right: 16 })
          .onClick(() => {
            router.back();
          })
        Text(this.userRole === 'admin' ? '所有用户学习统计' : '支部学习统计')
          .fontSize(18)
          .fontWeight(700)
          .margin({top:17})
      }
      .width('100%')
      .height(56)
      .alignItems(1)
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
        .justifyContent(1)
      } else {
        Scroll() {
          Column() {
            ForEach(this.allUserStats, (user: UserStudyStats) => {
              Column() {
                Row() {
                  Text(user.name)
                    .fontSize(16)
                    .fontColor('#333333')
                    .fontWeight(500)
                    .flexGrow(1)
                  Text(user.role === 'admin' ? '管理员' : user.role === 'branch_admin' ? '支部管理员' : '普通成员')
                    .fontSize(14)
                    .fontColor('#666666')
                    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                    .borderRadius(12)
                    .backgroundColor(user.role === 'admin' ? '#D32F2F' : user.role === 'branch_admin' ? '#FF8A80' : '#F5F5F5')
                    .fontColor(user.role === 'admin' || user.role === 'branch_admin' ? '#FFFFFF' : '#333333')
                }
                .width('100%')
                .margin({ bottom: 8 })
                
                Row() {
                  Text(`支部: ${user.branch}`)
                    .fontSize(14)
                    .fontColor('#666666')
                    .flexGrow(1)
                }
                .width('100%')
                .margin({ bottom: 16 })
                
                Row() {
                  Column() {
                    Text('总课程')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ bottom: 4 })
                    Text(user.totalCourses.toString())
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor('#D32F2F')
                  }
                  .flexGrow(1)
                  .alignItems(1)
                  Column() {
                    Text('已完成')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ bottom: 4 })
                    Text(user.completedCourses.toString())
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor('#D32F2F')
                  }
                  .flexGrow(1)
                  .alignItems(1)
                  Column() {
                    Text('学习时长')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ bottom: 4 })
                    Text(`${user.studyDuration || 0}分钟`)
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor('#D32F2F')
                  }
                  .flexGrow(1)
                  .alignItems(1)
                  Column() {
                    Text('进度')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ bottom: 4 })
                    Text(`${user.totalProgress}%`)
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor('#D32F2F')
                  }
                  .flexGrow(1)
                  .alignItems(1)
                }
                .width('100%')
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .margin({ bottom: 12 })
              .borderRadius(8)
              .shadow({
                radius: 4,
                color: '#00000010',
                offsetX: 0,
                offsetY: 2
              })
            })
            
            if (this.allUserStats.length === 0) {
              Column() {
                Text('暂无学习统计数据')
                  .fontSize(16)
                  .fontColor('#999999')
              }
              .width('100%')
              .height(200)
              .justifyContent(1)
            }
          }
          .padding({ top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}