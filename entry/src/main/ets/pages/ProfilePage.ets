import router from '@ohos.router';
import { StorageService } from '../services/StorageService';
import { UserService, UserInfo, ApiResponse, DuesStats, DuesPayment, LoginLog, UpdateInfo } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { AvatarComponent } from '../components/AvatarComponent';
import { emitter } from '@kit.BasicServicesKit';


@Component
export struct ProfilePage {
  @State user: UserInfo | null = null;
  @State isLoading: boolean = false;
  @State messageNotifications: boolean = true;
  @State activityNotifications: boolean = true;
  @State studyNotifications: boolean = true;
  @State duesNotifications: boolean = true;
  @State duesStats: DuesStats | null = null;
  @State isLoadingDues: boolean = false;

  async aboutToAppear() {
    await this.loadUserInfo();
    await this.loadDuesStats();
    
    // 添加事件监听器，监听个人信息更新
    emitter.on("refreshProfile", async () => {
      console.info("✅ 从个人信息编辑页返回，刷新个人信息");
      await this.loadUserInfo();
      await this.loadDuesStats();
    });
  }

  aboutToDisappear() {
    // 移除事件监听器
    emitter.off("refreshProfile");
  }

  // 页面显示时重新加载数据
  async onPageShow() {
    await this.loadUserInfo();
    await this.loadDuesStats();
  }

  async loadDuesStats() {
    this.isLoadingDues = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<DuesStats> = await userService.getDuesStats();
      if (response.code === 200 && response.data) {
        this.duesStats = response.data;
      }
    } catch (error) {
      console.error('加载党费统计失败:', error);
      promptAction.showToast({
        message: '加载党费统计失败',
        duration: 2000
      });
    } finally {
      this.isLoadingDues = false;
    }
  }

  async payDues(month: string, amount: number) {
    try {
      const userService = new UserService();
      const response: ApiResponse<boolean> = await userService.payDues(month, amount, 'online');
      if (response.code === 200 && response.data) {
        promptAction.showToast({
          message: '党费缴纳成功',
          duration: 2000
        });
        await this.loadDuesStats();
      } else {
        promptAction.showToast({
          message: '党费缴纳失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('缴纳党费失败:', error);
      promptAction.showToast({
        message: '缴纳党费失败',
        duration: 2000
      });
    }
  }

  async loadUserInfo() {
    this.isLoading = true;
    try {
      const cachedUser: UserInfo | null = StorageService.getItem<UserInfo>('user');
      if (cachedUser) {
        this.user = cachedUser;
      }
      
      const response: ApiResponse<UserInfo> = await new UserService().getCurrentUser();
      if (response.code === 200 && response.data) {
        this.user = response.data;
        await StorageService.setItem('user', response.data);
      }
    } catch (error) {
      console.error('获取用户信息失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async logout() {
    await StorageService.removeItem('user');
    await StorageService.removeItem('token');
    promptAction.showToast({
      message: '已退出登录',
      duration: 2000
    });
    router.replaceUrl({
      url: 'pages/LoginPage'
    });
  }

  async navigateToPersonalInfo() {
    try {
      const userService = new UserService();
      const response = await userService.getProfile();
      if (response.code === 200 && response.data) {
        // 导航到个人信息编辑页面
        router.pushUrl({
          url: 'pages/PersonalInfoEditPage'
        });
      }
    } catch (error) {
      console.error('获取个人信息失败:', error);
      promptAction.showToast({
        message: '获取个人信息失败',
        duration: 2000
      });
    }
  }

  async navigateToPasswordChange() {
    try {
      // 导航到密码修改页面
      router.pushUrl({
        url: 'pages/PasswordChangePage'
      });
    } catch (error) {
      console.error('导航失败:', error);
      promptAction.showToast({
        message: '导航失败',
        duration: 2000
      });
    }
  }

  async navigateToLoginLogs() {
    try {
      // 导航到登录日志页面
      router.pushUrl({
        url: 'pages/LoginLogsPage'
      });
    } catch (error) {
      console.error('导航失败:', error);
      promptAction.showToast({
        message: '导航失败',
        duration: 2000
      });
    }
  }

  async navigateToDuesPayment() {
    try {
      if (this.duesStats) {
        // 导航到党费缴纳页面
        router.pushUrl({
          url: 'pages/DuesPaymentPage'
        });
      }
    } catch (error) {
      console.error('导航失败:', error);
      promptAction.showToast({
        message: '导航失败',
        duration: 2000
      });
    }
  }

  async clearCache() {
    try {
      const userService = new UserService();
      const response: ApiResponse<boolean> = await userService.clearCache();
      if (response.code === 200 && response.data) {
        promptAction.showToast({
          message: '缓存已清理',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('清理缓存失败:', error);
      promptAction.showToast({
        message: '清理缓存失败',
        duration: 2000
      });
    }
  }

  async checkForUpdates() {
    try {
      const userService = new UserService();
      const response: ApiResponse<UpdateInfo> = await userService.checkUpdate();
      if (response.code === 200 && response.data) {
        if (response.data.isLatest) {
          promptAction.showToast({
            message: '当前已是最新版本',
            duration: 2000
          });
        } else {
          promptAction.showToast({
            message: '有新版本可用',
            duration: 2000
          });
        }
      }
    } catch (error) {
      console.error('检查更新失败:', error);
      promptAction.showToast({
        message: '检查更新失败',
        duration: 2000
      });
    }
  }

  async navigateToAbout() {
    try {
      // 这里可以导航到关于我们页面
      promptAction.showToast({
        message: '关于我们功能开发中',
        duration: 2000
      });
    } catch (error) {
      console.error('获取关于我们信息失败:', error);
      promptAction.showToast({
        message: '获取关于我们信息失败',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      // 顶部个人信息区域
      Column() {
        if (this.user) {
          AvatarComponent({
            user: {
              avatar: this.user.avatar,
              name: this.user.name
            },
            avatarSize: 100
          })
            .margin({ bottom: '16px' })
        } else {
          Text('党')
            .width(100)
            .height(100)
            .borderRadius(50)
            .backgroundColor('#D32F2F')
            .fontColor('#fff')
            .fontSize(40)
            .textAlign(TextAlign.Center)
            .margin({ bottom: '16px' })
        }
        Text(this.user?.name || '党员同志')
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#333333')
          .margin({ bottom: '8px' })
        Text(this.user?.role === 'admin' ? '系统管理员' : this.user?.role === 'branch_admin' ? '支部管理员' : '普通党员')
          .fontSize(14)
          .fontColor('#D32F2F')
      }
      .width('100%')
      .padding({ top: '40px', bottom: '32px' })
      .backgroundColor('#FFFFFF')
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: '#EEEEEE' })

      // 核心基础功能区域
      Column() {
        Text('核心功能')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: '20px', top: '20px', bottom: '12px' })

        List() {
          // 个人信息展示与编辑
          ListItem() {
            Row() {
              Text('个人信息')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
            .onClick(async () => {
              await this.navigateToPersonalInfo();
            })
          }

          // 党费缴纳相关
          ListItem() {
            Column() {
              Row() {
                Text('党费缴纳')
                  .fontSize(16)
                  .fontColor('#333333')
                Text('>')
                  .fontSize(16)
                  .fontColor('#999999')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              
              if (this.duesStats) {
                Column() {
                  Row() {
                    Text('待缴金额:')
                      .fontSize(14)
                      .fontColor('#666666')
                    Text(`¥${this.duesStats.pendingAmount || 0}`)
                      .fontSize(14)
                      .fontColor('#D32F2F')
                      .fontWeight(700)
                  }
                  .margin({ top: '8px' })
                  
                  Row() {
                    Text('已缴金额:')
                      .fontSize(14)
                      .fontColor('#666666')
                    Text(`¥${this.duesStats.paidAmount || 0}`)
                      .fontSize(14)
                      .fontColor('#4CAF50')
                      .fontWeight(700)
                  }
                  .margin({ top: '4px' })
                }
                .margin({ top: '8px' })
              }
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
            .onClick(async () => {
              await this.navigateToDuesPayment();
            })
          }
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ top: '4px' })

        // 账号安全管理
        Text('账号安全')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: '20px', top: '20px', bottom: '12px' })

        List() {
          ListItem() {
            Row() {
              Text('密码修改')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
            .onClick(async () => {
              await this.navigateToPasswordChange();
            })
          }

          ListItem() {
            Row() {
              Text('登录日志')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
            .onClick(async () => {
              await this.navigateToLoginLogs();
            })
          }
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ top: '4px' })

        // 系统设置
        Text('系统设置')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: '20px', top: '20px', bottom: '12px' })

        List() {
          ListItem() {
            Row() {
              Text('消息提醒')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
          }

          ListItem() {
            Row() {
              Text('活动通知')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
          }

          ListItem() {
            Row() {
              Text('学习提醒')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
          }

          ListItem() {
            Row() {
              Text('党费提醒')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
          }

          ListItem() {
            Row() {
              Text('缓存清理')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
            .onClick(async () => {
              await this.clearCache();
            })
          }

          ListItem() {
            Row() {
              Text('版本更新')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
            .onClick(async () => {
              await this.checkForUpdates();
            })
          }

          ListItem() {
            Row() {
              Text('关于我们')
                .fontSize(16)
                .fontColor('#333333')
              Text('>')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
            .onClick(async () => {
              await this.navigateToAbout();
            })
          }
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ top: '4px' })

        // 管理权限专属功能（仅管理员可见）
        if (this.user?.role === 'admin' || this.user?.role === 'branch_admin') {
          Text('管理功能')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: '20px', top: '20px', bottom: '12px' })

          List() {
            ListItem() {
              Row() {
                Text('用户管理')
                  .fontSize(16)
                  .fontColor('#333333')
                Text('>')
                  .fontSize(16)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
              .onClick(() => {
                promptAction.showToast({
                  message: '用户管理功能开发中',
                  duration: 2000
                });
              })
            }

            ListItem() {
              Row() {
                Text('数据统计')
                  .fontSize(16)
                  .fontColor('#333333')
                Text('>')
                  .fontSize(16)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ left: '20px', right: '20px', top: '16px', bottom: '16px' })
              .onClick(() => {
                promptAction.showToast({
                  message: '数据统计功能开发中',
                  duration: 2000
                });
              })
            }
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: '4px' })
        }
      }

      // 退出登录按钮
      Button('退出登录')
        .width('90%')
        .height('48px')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#D32F2F')
        .borderRadius('8px')
        .margin({ top: '40px', bottom: '30px' })
        .onClick(() => {
          this.logout();
        })

      // 版本信息
      Text('版本 1.0.0')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: '20px' })
    }
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}