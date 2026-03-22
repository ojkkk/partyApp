import { UserInfo, UserService, Branch, BranchApplication, BranchApplicationMessage } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { emitter } from '@kit.BasicServicesKit';
// 修复1：重新定义显式接口
interface SelectOption {
  value: string;
}

// 标准党旗红主色，符合党建应用规范
const PRIMARY_COLOR: string = '#C8102E';
const BG_COLOR: string = '#F5F7FA';
const CARD_BG: string = '#FFFFFF';
const TEXT_MAIN: string = '#181818';
const TEXT_SECOND: string = '#666666';
const TEXT_GRAY: string = '#999999';

@Entry
@Component
export struct BranchManagementPage {
  @State user: UserInfo | null = null;
  @State branches: Branch[] = [];
  @State selectedBranchId: string = '';
  @State applications: BranchApplication[] = [];
  @State messages: BranchApplicationMessage[] = [];
  @State userMap: Record<string, UserInfo> = {};
  @State unreadCount: number = 0;
  @State isLoading: boolean = false;

  private userService: UserService = new UserService();

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadBranches();
    await this.loadUnreadCount();
    await this.loadUserMessages();
    // 标记所有未读消息为已读
    await this.markAllMessagesAsRead();
    if (this.user?.role === 'branch_admin') {
      await this.loadPendingApplications();
    }
  }

  async markAllMessagesAsRead() {
    try {
      const messages = this.messages.filter(msg => !msg.isRead);
      for (const message of messages) {
        await this.userService.markBranchMessageAsRead(message.id);
      }
      // 重新加载消息列表以更新状态
      await this.loadUserMessages();
    } catch (error) {
      console.error('标记消息为已读失败:', error);
    }
  }

  async loadBranches() {
    this.isLoading = true;
    try {
      const response = await this.userService.getBranches();
      if (response.code === 200 && response.data) {
        this.branches = response.data;
        if (this.branches.length > 0) {
          this.selectedBranchId = this.branches[0].id;
        }
      }
    } catch (error) {
      console.error('加载支部列表失败:', error);
      promptAction.showToast({ message: '加载支部列表失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async loadPendingApplications() {
    this.isLoading = true;
    try {
      const response = await this.userService.getPendingApplications();
      if (response.code === 200 && response.data) {
        this.applications = response.data;
        // 获取每个申请人的信息
        await this.loadApplicantInfo();
      }
    } catch (error) {
      console.error('加载申请列表失败:', error);
      promptAction.showToast({ message: '加载申请列表失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async loadApplicantInfo() {
    try {
      for (const application of this.applications) {
        if (!this.userMap[application.userId]) {
          const userResponse = await this.userService.getUserById(application.userId);
          if (userResponse.code === 200 && userResponse.data) {
            this.userMap[application.userId] = userResponse.data;
          }
        }
      }
    } catch (error) {
      console.error('加载申请人信息失败:', error);
    }
  }

  async loadUnreadCount() {
    try {
      const response = await this.userService.getUnreadMessageCount();
      if (response.code === 200 && response.data !== undefined) {
        this.unreadCount = response.data;
      }
    } catch (error) {
      console.error('加载未读消息数失败:', error);
    }
  }

  async loadUserMessages() {
    try {
      const response = await this.userService.getUserMessages();
      if (response.code === 200 && response.data) {
        this.messages = response.data.slice(0, 3); // 只显示最近三条
      }
    } catch (error) {
      console.error('加载消息列表失败:', error);
    }
  }

  async applyForBranch() {
    if (!this.selectedBranchId) {
      promptAction.showToast({ message: '请选择要申请的支部', duration: 2000 });
      return;
    }

    this.isLoading = true;
    try {
      const response = await this.userService.applyForBranch(this.selectedBranchId);
      if (response.code === 200) {
        promptAction.showToast({ message: '申请已提交，请等待审批', duration: 2000 });
        setTimeout(() => {
          router.back();
        }, 1000);
      } else {
        promptAction.showToast({ message: response.message || '申请失败', duration: 2000 });
      }
    } catch (error) {
      console.error('提交申请失败:', error);
      promptAction.showToast({ message: '提交申请失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async approveApplication(applicationId: string, approved: boolean) {
    this.isLoading = true;
    try {
      const response = await this.userService.approveApplication(applicationId, approved);
      if (response.code === 200) {
        promptAction.showToast({ message: approved ? '审批通过' : '审批拒绝', duration: 2000 });
        await this.loadPendingApplications();
      } else {
        promptAction.showToast({ message: response.message || '审批失败', duration: 2000 });
      }
    } catch (error) {
      console.error('审批申请失败:', error);
      promptAction.showToast({ message: '审批申请失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  isBranchAdmin(): boolean {
    return this.user?.role === 'branch_admin';
  }

  isMember(): boolean {
    return this.user?.role === 'member';
  }

  getBranchName(branchId: string): string {
    const branch = this.branches.find(b => b.id === branchId);
    return branch ? branch.name : '';
  }

  getSelectedBranchName(): string {
    return this.getBranchName(this.selectedBranchId);
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Image($rawfile("返回.png"))
            .width(24)
            .height(24)
        }
        .width(44)
        .height(44)
        .backgroundColor('transparent')
        .onClick((): void =>{
          router.back();
          emitter.emit("refreshBranchUnread", null);
        } )

        Text('支部管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(CARD_BG)
      .shadow({
        radius: 4,
        color: '#0A000000',
        offsetX: 0,
        offsetY: 1
      })

      // 内容区域
      Scroll() {
        Column() {
          // 显示最近三条审批消息
          if (this.messages.length > 0) {
            Text('审批消息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
              .margin({ top: 20, left: 0, bottom: 12 })

            ForEach(this.messages, (message: BranchApplicationMessage): void => {
              Column() {
                Text(message.content)
                  .fontSize(14)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .margin({ bottom: 4 })
                Text(message.createdAt)
                  .fontSize(12)
                  .fontColor(TEXT_GRAY)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor(CARD_BG)
              .borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 8 })
            })
          }

          if (this.isMember()) {
            if (!this.user?.branch || this.user.branch.trim() === '') {
              // 普通党员没有支部 - 申请加入支部
              Text('申请加入支部')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
                .margin({ top: 20, left: 16, bottom: 20 })

              Column() {
                Text('选择支部')
                  .fontSize(16)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
                  .margin({ bottom: 10 })

                // 使用显式类型的SelectOption
                Select(this.branches.map((branch: Branch): SelectOption => {
                  return { value: branch.name };
                }))
                  .selected(this.branches.findIndex(b => b.id === this.selectedBranchId))
                  .value(this.getSelectedBranchName() || '请选择支部')
                  .width('100%')
                  .height(48)
                  .backgroundColor('#F5F7FA')
                  .borderRadius(8)
                  .font({ size: 16 })
                  .onSelect((index: number, value: string): void => {
                    if (index >= 0 && index < this.branches.length) {
                      this.selectedBranchId = this.branches[index].id;
                    }
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor(CARD_BG)
              .borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 20 })

              Button('提交申请')
                .width('100%')
                .height(48)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor(PRIMARY_COLOR)
                .borderRadius(24)
                .margin({ left: 16, right: 16, bottom: 20 })
                .enabled(!this.isLoading)
                .onClick(() => {
                  void this.applyForBranch();
                })
            } else {
              // 普通党员已有支部 - 显示当前所属支部
              Text('当前所属支部')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
                .margin({ top: 20, left: 0, bottom: 20 })

              Column() {
                Text('支部名称')
                  .fontSize(16)
                  .fontColor(TEXT_SECOND)
                  .width('100%')
                  .margin({ bottom: 10 })
                Text(this.user.branch)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(TEXT_MAIN)
                  .width('100%')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 20, bottom: 20 })
              .backgroundColor(CARD_BG)
              .borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 20 })
            }
          } else if (this.isBranchAdmin()) {
            // 支部管理员页面 - 审批申请
            Text('支部申请审批')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
              .margin({ top: 20, left: 16, bottom: 20 })

            if (this.isLoading) {
              LoadingProgress()
                .width(40)
                .height(40)
                .color(PRIMARY_COLOR)
                .margin({ top: 40 })
            } else if (this.applications.length === 0) {
              Column() {
                Text('📋')
                  .fontSize(48)
                  .margin({ bottom: 16 })
                Text('暂无审批消息提醒')
                  .fontSize(16)
                  .fontColor(TEXT_SECOND)
              }
              .width('100%')
              .padding({ top: 60 })
            } else {
              ForEach(this.applications, (application: BranchApplication): void => {
                Column() {
                  Row() {
                    Column() {
                      Text(`申请人: ${this.userMap[application.userId]?.name || '未知'}`)
                        .fontSize(14)
                        .fontColor(TEXT_MAIN)
                        .fontWeight(FontWeight.Medium)
                      Text(`支部: ${this.getBranchName(application.branchId)}`)
                        .fontSize(14)
                        .fontColor(TEXT_SECOND)
                        .margin({ top: 4 })
                      Text(`申请日期: ${application.applyDate}`)
                        .fontSize(12)
                        .fontColor(TEXT_GRAY)
                        .margin({ top: 4 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Row() {
                      Button('拒绝')
                        .width(80)
                        .height(36)
                        .fontSize(14)
                        .fontColor(TEXT_MAIN)
                        .backgroundColor('#F5F7FA')
                        .borderRadius(18)
                        .enabled(!this.isLoading)
                        .margin({ right: 10 })
                        .onClick(() => {
                          void this.approveApplication(application.id, false);
                        })

                      Button('通过')
                        .width(80)
                        .height(36)
                        .fontSize(14)
                        .fontColor('#FFFFFF')
                        .backgroundColor(PRIMARY_COLOR)
                        .borderRadius(18)
                        .enabled(!this.isLoading)
                        .onClick(() => {
                          void this.approveApplication(application.id, true);
                        })
                    }
                  }
                  .width('100%')
                  .padding(16)
                }
                .width('100%')
                .margin({ left: 16, right: 16, bottom: 12 })
                .backgroundColor(CARD_BG)
                .borderRadius(12)
                .shadow({
                  radius: 4,
                  color: '#0D000000',
                  offsetX: 0,
                  offsetY: 2
                })
              })
            }
          }

          if (this.isLoading) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(PRIMARY_COLOR)
              .margin({ top: 20 })
          }
        }
        .padding({ bottom: 40 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(BG_COLOR)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
  }

  async aboutToDisappear() {
    // 通知首页更新未读消息数
    try {


      emitter.emit("refreshBranchUnread", null);
    } catch (error) {
      console.error('发送事件失败:', error);
    }
  }
}