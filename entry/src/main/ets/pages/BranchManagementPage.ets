import { UserInfo, UserService, Branch, BranchApplication, BranchApplicationMessage } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { emitter } from '@kit.BasicServicesKit';

interface SelectOption {
  value: string;
}

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

  // ===================== 颜色配置 - 庄重红金正式风 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';
  private readonly COLOR_PRIMARY_LIGHT = '#D83A34';
  private readonly COLOR_GOLD = '#C9A45C';
  private readonly COLOR_BG = '#F7F4EF';
  private readonly COLOR_CARD = '#FFFFFF';
  private readonly COLOR_TEXT_PRIMARY = '#1F1F1F';
  private readonly COLOR_TEXT_SECONDARY = '#666666';
  private readonly COLOR_TEXT_TERTIARY = '#999999';
  private readonly COLOR_DIVIDER = '#F0EBE3';

  private userService: UserService = new UserService();

  async aboutToAppear() {
    this.user = await StorageService.getItemAsync<UserInfo>('user');
    await this.loadBranches();
    await this.loadUnreadCount();
    await this.loadUserMessages();
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
        this.messages = response.data.slice(0, 3);
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
      this.buildHeader();

      Scroll() {
        Column() {
          if (this.messages.length > 0) {
            this.buildMessagesSection();
          }

          if (this.isMember()) {
            this.buildMemberView();
          } else if (this.isBranchAdmin()) {
            this.buildAdminView();
          }

          if (this.isLoading && this.applications.length === 0 && this.messages.length === 0) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(this.COLOR_PRIMARY)
              .margin({ top: 40 });
          }
        }
        .padding({ bottom: 40 });
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(this.COLOR_BG)
      .align(Alignment.TopStart);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.COLOR_BG);
  }

  @Builder
  buildHeader() {
    Stack({ alignContent: Alignment.Bottom }) {
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#B51F2E', 0], ['#D83A34', 1]]
        });

      Row() {
        Row() {
          Text('‹')
            .fontSize(32)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Regular)
            .margin({ bottom: 6 })
            .onClick(() => {
              router.back();
              emitter.emit("refreshBranchUnread", null);
            });
        }
        .width(56)
        .height('100%')
        .justifyContent(FlexAlign.Center);

        Text('支部管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Row()
          .width(56)
          .height('100%');
      }
      .width('100%')
      .height(56)
      .padding({ top: 8 });

      Row()
        .width('100%')
        .height(1)
        .backgroundColor('rgba(201, 164, 92, 0.4)');
    }
    .width('100%')
    .height(56);
  }

  @Builder
  buildMessagesSection() {
    Column() {
      Row() {
        Row()
          .width(3)
          .height(14)
          .backgroundColor(this.COLOR_PRIMARY)
          .borderRadius(2)
          .margin({ right: 8 });

        Text('审批消息')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
      }
      .width('100%')
      .margin({ bottom: 12 });

      ForEach(this.messages, (message: BranchApplicationMessage): void => {
        Column() {
          Text(message.content)
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: 4 });
          Text(message.createdAt.replace('T', ' '))
            .fontSize(12)
            .fontColor(this.COLOR_TEXT_TERTIARY);
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.COLOR_CARD)
        .borderRadius(12)
        .margin({ bottom: 8 })
        .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 1 });
      });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16 });
  }

  @Builder
  buildMemberView() {
    if (!this.user?.branch || this.user.branch.trim() === '') {
      Column() {
        Row() {
          Row()
            .width(3)
            .height(14)
            .backgroundColor(this.COLOR_PRIMARY)
            .borderRadius(2)
            .margin({ right: 8 });

          Text('申请加入支部')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY);
        }
        .width('100%')
        .margin({ bottom: 16 });

        Column() {
          Text('选择支部')
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .width('100%')
            .margin({ bottom: 10 });

          Select(this.branches.map((branch: Branch): SelectOption => {
            return { value: branch.name };
          }))
            .selected(this.branches.findIndex(b => b.id === this.selectedBranchId))
            .value(this.getSelectedBranchName() || '请选择支部')
            .width('100%')
            .height(48)
            .backgroundColor(this.COLOR_BG)
            .borderRadius(8)
            .font({ size: 16 })
            .onSelect((index: number, value: string): void => {
              if (index >= 0 && index < this.branches.length) {
                this.selectedBranchId = this.branches[index].id;
              }
            });
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.COLOR_CARD)
        .borderRadius(12)
        .margin({ bottom: 20 })
        .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 1 });

        Button('提交申请')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.COLOR_PRIMARY)
          .borderRadius(24)
          .enabled(!this.isLoading)
          .onClick(() => {
            void this.applyForBranch();
          });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 });
    } else {
      Column() {
        Row() {
          Row()
            .width(3)
            .height(14)
            .backgroundColor(this.COLOR_PRIMARY)
            .borderRadius(2)
            .margin({ right: 8 });

          Text('当前所属支部')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY);
        }
        .width('100%')
        .margin({ bottom: 16 });

        Column() {
          Text('支部名称')
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .width('100%')
            .margin({ bottom: 10 });
          Text(this.user.branch)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .width('100%');
        }
        .width('100%')
        .padding(20)
        .backgroundColor(this.COLOR_CARD)
        .borderRadius(12)
        .border({ width: 1, color: this.COLOR_GOLD })
        .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 1 });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 });
    }
  }

  @Builder
  buildAdminView() {
    Column() {
      Row() {
        Row()
          .width(3)
          .height(14)
          .backgroundColor(this.COLOR_PRIMARY)
          .borderRadius(2)
          .margin({ right: 8 });

        Text('支部申请审批')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
      }
      .width('100%')
      .margin({ bottom: 16 });

      if (this.isLoading && this.applications.length === 0) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(this.COLOR_PRIMARY)
          .margin({ top: 40 });
      } else if (this.applications.length === 0) {
        Column() {
          Column() {
            Text('📋')
              .fontSize(40)
              .fontColor(this.COLOR_GOLD)
              .margin({ bottom: 12 });
          }
          .width(72)
          .height(72)
          .border({ width: 2, color: this.COLOR_GOLD })
          .borderRadius(36)
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 16 });

          Text('暂无审批消息提醒')
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_TERTIARY);
        }
        .width('100%')
        .padding({ top: 60 });
      } else {
        ForEach(this.applications, (application: BranchApplication): void => {
          Column() {
            Row() {
              Column() {
                Text(`申请人: ${this.userMap[application.userId]?.name || '未知'}`)
                  .fontSize(14)
                  .fontColor(this.COLOR_TEXT_PRIMARY)
                  .fontWeight(FontWeight.Medium);
                Text(`支部: ${this.getBranchName(application.branchId)}`)
                  .fontSize(14)
                  .fontColor(this.COLOR_TEXT_SECONDARY)
                  .margin({ top: 4 });
                Text(`申请日期: ${application.applyDate}`)
                  .fontSize(12)
                  .fontColor(this.COLOR_TEXT_TERTIARY)
                  .margin({ top: 4 });
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);

              Row() {
                Button('拒绝')
                  .width(72)
                  .height(36)
                  .fontSize(13)
                  .fontColor(this.COLOR_TEXT_SECONDARY)
                  .backgroundColor(this.COLOR_BG)
                  .borderRadius(18)
                  .enabled(!this.isLoading)
                  .margin({ right: 10 })
                  .onClick(() => {
                    void this.approveApplication(application.id, false);
                  });

                Button('通过')
                  .width(72)
                  .height(36)
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .backgroundColor(this.COLOR_PRIMARY)
                  .borderRadius(18)
                  .enabled(!this.isLoading)
                  .onClick(() => {
                    void this.approveApplication(application.id, true);
                  });
              }
            }
            .width('100%')
            .padding(16);
          }
          .width('100%')
          .margin({ bottom: 12 })
          .backgroundColor(this.COLOR_CARD)
          .borderRadius(12)
          .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 1 });
        });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16 });
  }

  async aboutToDisappear() {
    try {
      emitter.emit("refreshBranchUnread", null);
    } catch (error) {
      console.error('发送事件失败:', error);
    }
  }
}
