import { UserInfo, User, UserService, ApiResponse } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AvatarComponent } from '../components/AvatarComponent';
import { pinyin } from 'pinyin-pro';

@Entry
@Component
export struct PersonnelManagementPage {
  @State user: UserInfo | null = null;
  @State branchMembers: User[] = [];
  @State filteredMembers: User[] = [];
  @State isLoading: boolean = false;
  @State showUserDetail: boolean = false;
  @State selectedUser: User | null = null;
  @State showEditDialog: boolean = false;
  @State showKickDialog: boolean = false;
  @State showResetPasswordDialog: boolean = false;
  @State showDuesAmountDialog: boolean = false;
  @State newDuesAmount: number = 0;
  @State searchText: string = '';
  @State sortBy: string = 'name';
  @State sortOrder: 'asc' | 'desc' = 'asc';
  @State filterRole: string = 'all';
  @State editUser: User | null = null;

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
    await this.loadBranchMembers();
  }

  async loadBranchMembers() {
    this.isLoading = true;
    try {
      const response = await this.userService.getBranchMembers();
      if (response.code === 200 && response.data) {
        this.branchMembers = response.data;
        this.applyFilterAndSort();
      }
    } catch (error) {
      console.error('加载支部成员失败:', error);
      promptAction.showToast({ message: '加载支部成员失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  applyFilterAndSort() {
    let filtered = this.branchMembers;

    if (this.filterRole !== 'all') {
      filtered = filtered.filter(member => member.role === this.filterRole);
    }

    if (this.searchText) {
      const keyword = this.searchText.toLowerCase();
      filtered = filtered.filter(member =>
        member.name.toLowerCase().includes(keyword) ||
        member.partyId.toLowerCase().includes(keyword) ||
        member.phone?.toLowerCase().includes(keyword) ||
        member.email?.toLowerCase().includes(keyword)
      );
    }

    filtered.sort((a, b) => {
      let comparison = 0;
      switch (this.sortBy) {
        case 'name':
          comparison = this.getFullPinyin(a.name).localeCompare(this.getFullPinyin(b.name));
          break;
        case 'joinDate':
          comparison = new Date(a.joinDate || '').getTime() - new Date(b.joinDate || '').getTime();
          break;
        case 'role':
          comparison = a.role.localeCompare(b.role);
          break;
      }
      return this.sortOrder === 'asc' ? comparison : -comparison;
    });

    this.filteredMembers = filtered;
  }

  async kickMember(userId: string) {
    try {
      const response = await this.userService.kickMember(userId);
      if (response.code === 200) {
        promptAction.showToast({ message: '移出成员成功', duration: 2000 });
        await this.loadBranchMembers();
      } else {
        promptAction.showToast({ message: '踢出成员失败', duration: 2000 });
      }
    } catch (error) {
      console.error('踢出成员失败:', error);
      promptAction.showToast({ message: '踢出成员失败', duration: 2000 });
    }
  }

  async resetPassword(userId: string) {
    try {
      const response = await this.userService.resetPassword(userId);
      if (response.code === 200) {
        promptAction.showToast({ message: '密码重置成功', duration: 2000 });
      } else {
        promptAction.showToast({ message: '密码重置失败', duration: 2000 });
      }
    } catch (error) {
      console.error('密码重置失败:', error);
      promptAction.showToast({ message: '密码重置失败', duration: 2000 });
    }
  }

  async updateDuesAmount(userId: string, amount: number) {
    try {
      const response: ApiResponse<boolean> = await this.userService.updateDuesAmount(userId, amount);
      if (response.code === 200) {
        promptAction.showToast({ message: '党费金额设置成功', duration: 2000 });
      } else {
        promptAction.showToast({ message: '党费金额设置失败', duration: 2000 });
      }
    } catch (error) {
      console.error('设置党费金额失败:', error);
      promptAction.showToast({ message: '设置党费金额失败', duration: 2000 });
    }
  }

  async updateUserInfo(user: User) {
    try {
      const response: ApiResponse<User> = await this.userService.updateUser(user.id, user);
      if (response.code === 200) {
        promptAction.showToast({ message: '用户信息更新成功', duration: 2000 });
        await this.loadBranchMembers();
      } else {
        promptAction.showToast({ message: '用户信息更新失败', duration: 2000 });
      }
    } catch (error) {
      console.error('更新用户信息失败:', error);
      promptAction.showToast({ message: '更新用户信息失败', duration: 2000 });
    }
  }

  getPartyAge(joinDate: string): number {
    const join = new Date(joinDate);
    const now = new Date();
    const diff = now.getTime() - join.getTime();
    return Math.floor(diff / (1000 * 60 * 60 * 24 * 365.25));
  }

  getFullPinyin(name: string): string {
    if (!name) return '';
    const r = pinyin(name, { toneType: 'none' });
    return Array.isArray(r) ? r.join('') : r;
  }

  build() {
    Column() {
      this.buildHeader();

      if (this.showUserDetail) {
        this.UserDetailDialog();
      }

      this.SortFilterBar();

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.COLOR_PRIMARY);
          Text('加载中...')
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_TERTIARY)
            .margin({ top: 12 });
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center);
      } else if (this.filteredMembers.length === 0) {
        Column() {
          Text('暂无成员')
            .fontSize(16)
            .fontColor(this.COLOR_TEXT_SECONDARY);
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.filteredMembers, (member: User) => {
            ListItem() {
              this.UserCard(member);
            }
            .margin({ left: 16, right: 16, top: 12 });
          });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }

      this.buildDialogs();
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
            .onClick(() => router.back());
        }
        .width(56)
        .height('100%')
        .justifyContent(FlexAlign.Center);

        Text('人员管理')
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
  UserCard(user: User) {
    Row() {
      AvatarComponent({
        user: {
          avatar: user.avatar,
          name: user.name
        },
        avatarSize: 48
      });

      Column() {
        Row() {
          Text(user.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY);

          Text(user.role === 'admin' ? '系统管理员' : user.role === 'branch_admin' ? '支部管理员' : '党员')
            .fontSize(11)
            .fontColor(this.COLOR_PRIMARY)
            .backgroundColor('#FEF2F2')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .margin({ left: 8 });
        }

        Text(`党号: ${user.partyId}`)
          .fontSize(13)
          .fontColor(this.COLOR_TEXT_SECONDARY)
          .margin({ top: 4 });

        Text(`入党时间: ${user.joinDate || '未设置'}`)
          .fontSize(13)
          .fontColor(this.COLOR_TEXT_SECONDARY)
          .margin({ top: 2 });

        if (user.joinDate) {
          Text(`党龄: ${this.getPartyAge(user.joinDate)}年`)
            .fontSize(13)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .margin({ top: 2 });
        }
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Text('›')
        .fontSize(24)
        .fontColor(this.COLOR_GOLD)
        .fontWeight(FontWeight.Regular);
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 1 })
    .onClick(() => {
      this.selectedUser = user;
      this.showUserDetail = true;
    });
  }

  @Builder
  UserDetailDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(() => {
          this.showUserDetail = false;
        });

      Column() {
        // 顶部装饰条
        Row()
          .width('95%')
          .height(3)
          .backgroundColor(this.COLOR_GOLD);

        if (!this.selectedUser) {
          Column() {
            Text('无选中用户')
              .fontSize(16)
              .fontColor(this.COLOR_TEXT_SECONDARY);
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          Column() {
            // 头部
            Row() {
              Row() {
                Text('‹')
                  .fontSize(28)
                  .fontColor(this.COLOR_TEXT_PRIMARY)
                  .margin({ bottom: 6 })
                  .onClick(() => {
                    this.showUserDetail = false;
                  });
              }
              .width(44)
              .height(44)
              .justifyContent(FlexAlign.Center);

              Text('成员详情')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.COLOR_TEXT_PRIMARY)
                .layoutWeight(1)
                .textAlign(TextAlign.Center);

              Row()
                .width(44)
                .height(44);
            }
            .width('100%')
            .margin({ top: 16, bottom: 20 });

            Scroll() {
              Column() {
                // 头像区域
                Column() {
                  AvatarComponent({
                    user: {
                      avatar: this.selectedUser.avatar,
                      name: this.selectedUser.name
                    },
                    avatarSize: 80
                  });

                  Text(this.selectedUser.name)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.COLOR_TEXT_PRIMARY)
                    .margin({ top: 16 });

                  Text(this.selectedUser.role === 'admin' ? '系统管理员' : this.selectedUser.role === 'branch_admin' ? '支部管理员' : '党员')
                    .fontSize(13)
                    .fontColor(this.COLOR_PRIMARY)
                    .backgroundColor('#FEF2F2')
                    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                    .borderRadius(14)
                    .margin({ top: 10 });
                }
                .width('100%')
                .margin({ bottom: 24 });

                // 信息卡片
                Column() {
                  Text('基本信息')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.COLOR_TEXT_PRIMARY)
                    .margin({ bottom: 12, left: 4 });

                  Column() {
                    this.InfoRow('党号', this.selectedUser.partyId);
                    Divider().color(this.COLOR_DIVIDER).margin({ left: 16, right: 16 });
                    this.InfoRow('所属支部', this.selectedUser.branch);
                    Divider().color(this.COLOR_DIVIDER).margin({ left: 16, right: 16 });
                    this.InfoRow('入党时间', this.selectedUser.joinDate || '未设置');
                    if (this.selectedUser.joinDate) {
                      Divider().color(this.COLOR_DIVIDER).margin({ left: 16, right: 16 });
                      this.InfoRow('党龄', `${this.getPartyAge(this.selectedUser.joinDate)}年`);
                    }
                  }
                  .width('100%')
                  .backgroundColor(this.COLOR_CARD)
                  .borderRadius(12)
                  .border({ width: 1, color: this.COLOR_DIVIDER });
                }
                .width('100%')
                .margin({ bottom: 16 });

                // 联系信息卡片
                Column() {
                  Text('联系信息')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.COLOR_TEXT_PRIMARY)
                    .margin({ bottom: 12, left: 4 });

                  Column() {
                    this.InfoRow('联系方式', this.selectedUser.phone || '未设置');
                    Divider().color(this.COLOR_DIVIDER).margin({ left: 16, right: 16 });
                    this.InfoRow('邮箱', this.selectedUser.email || '未设置');
                    Divider().color(this.COLOR_DIVIDER).margin({ left: 16, right: 16 });
                    this.InfoRow('注册时间', this.selectedUser.registrationDate || '未设置');
                  }
                  .width('100%')
                  .backgroundColor(this.COLOR_CARD)
                  .borderRadius(12)
                  .border({ width: 1, color: this.COLOR_DIVIDER });
                }
                .width('100%')
                .margin({ bottom: 24 });
            }
            .width('100%')
            .padding({ bottom: 20 });
          }
            .layoutWeight(1)
            .scrollBar(BarState.Off);

            // 操作按钮区
            Column() {
              Row() {
                Button('编辑信息')
                  .width('48%')
                  .height(44)
                  .fontSize(14)
                  .fontColor(this.COLOR_PRIMARY)
                  .backgroundColor('#FEF2F2')
                  .borderRadius(22)
                  .onClick(() => {
                    this.showEditDialog = true;
                    this.showUserDetail = false;
                  });

                Button('重置密码')
                  .width('48%')
                  .height(44)
                  .fontSize(14)
                  .fontColor(this.COLOR_PRIMARY)
                  .backgroundColor('#FEF2F2')
                  .borderRadius(22)
                  .margin({ left: '4%' })
                  .onClick(() => {
                    this.showResetPasswordDialog = true;
                    this.showUserDetail = false;
                  });
              }
              .width('100%');

              Row() {
                Button('党费设置')
                  .width('48%')
                  .height(44)
                  .fontSize(14)
                  .fontColor(this.COLOR_PRIMARY)
                  .backgroundColor('#FEF2F2')
                  .borderRadius(22)
                  .onClick(() => {
                    this.showDuesAmountDialog = true;
                    this.showUserDetail = false;
                  });

                Button('移出支部')
                  .width('48%')
                  .height(44)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .backgroundColor(this.COLOR_PRIMARY)
                  .borderRadius(22)
                  .margin({ left: '4%' })
                  .onClick(() => {
                    this.showKickDialog = true;
                    this.showUserDetail = false;
                  });
              }
              .width('100%')
              .margin({ top: 12 });
            }
            .width('100%')
            .margin({ bottom: 20 });
          }
          .width('100%')
          .padding({ left: 20, right: 20 });
        }
      }
      .width('84%')
      .height('82%')
      .backgroundColor(this.COLOR_BG)
      .borderRadius(16)
      .shadow({ radius: 12, color: '#00000030', offsetX: 0, offsetY: 4 });
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(9999);
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_SECONDARY)
        .width(70);

      Text(value)
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 });
  }

  @Builder
  SortFilterBar() {
    Column() {
      Row() {
        Image($rawfile("搜索.png"))
          .width(20)
          .height(20)
          .margin({ left: 16 })
          .fillColor(this.COLOR_PRIMARY);

        TextInput({
          placeholder: '搜索成员姓名、党号、联系方式',
          text: this.searchText
        })
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .padding({ left: 8, right: 16 })
          .fontSize(15)
          .placeholderColor(this.COLOR_TEXT_TERTIARY)
          .onChange((value: string) => {
            this.searchText = value;
            this.applyFilterAndSort();
          });
      }
      .width('100%')
      .height(44)
      .backgroundColor(this.COLOR_CARD)
      .border({ width: 1, color: this.COLOR_GOLD })
      .borderRadius(22)
      .margin({ bottom: 12 });

      Row() {
        Button(this.filterRole === 'all' ? '全部角色' :
               this.filterRole === 'admin' ? '系统管理员' :
               this.filterRole === 'branch_admin' ? '支部管理员' : '党员')
          .width(130)
          .height(36)
          .fontSize(13)
          .fontColor(this.COLOR_PRIMARY)
          .backgroundColor('#FEF2F2')
          .borderRadius(18)
          .onClick(() => {
            this.filterRole = this.filterRole === 'all' ? 'admin' :
                             this.filterRole === 'admin' ? 'branch_admin' :
                             this.filterRole === 'branch_admin' ? 'member' : 'all';
            this.applyFilterAndSort();
          });

        Row() {
          Text('排序: ')
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_SECONDARY);

          Button(this.sortBy === 'name' ? '姓名' :
                 this.sortBy === 'joinDate' ? '入党时间' : '角色')
            .width(90)
            .height(36)
            .fontSize(13)
            .fontColor(this.COLOR_PRIMARY)
            .backgroundColor('#FEF2F2')
            .borderRadius(18)
            .onClick(() => {
              this.sortBy = this.sortBy === 'name' ? 'joinDate' :
                           this.sortBy === 'joinDate' ? 'role' : 'name';
              this.applyFilterAndSort();
            });

          Button(this.sortOrder === 'asc' ? '↑' : '↓')
            .width(52)
            .height(44)
            .fontSize(18)
            .fontColor(this.COLOR_PRIMARY)
            .backgroundColor('#FEF2F2')
            .borderRadius(22)
            .margin({ left: 8 })
            .onClick(() => {
              this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
              this.applyFilterAndSort();
            });
        }
        .margin({ left: 12 });

        Blank();
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .shadow({ radius: 4, color: '#00000006', offsetX: 0, offsetY: 1 });
  }

  @Builder
  buildDialogs() {
    if (this.showKickDialog && this.selectedUser) {
      this.buildConfirmDialog('确认移出', `确定要将 ${this.selectedUser.name} 移出支部吗？`, async () => {
        if (this.selectedUser) {
          await this.kickMember(this.selectedUser.id);
          this.showKickDialog = false;
        }
      }, () => {
        this.showKickDialog = false;
      }, true);
    }

    if (this.showResetPasswordDialog && this.selectedUser) {
      this.buildConfirmDialog('重置密码', `确定要重置 ${this.selectedUser.name} 的密码吗？\n重置后密码将恢复为默认值。`, async () => {
        if (this.selectedUser) {
          await this.resetPassword(this.selectedUser.id);
          this.showResetPasswordDialog = false;
        }
      }, () => {
        this.showResetPasswordDialog = false;
      }, false);
    }

    if (this.showDuesAmountDialog && this.selectedUser) {
      this.buildDuesAmountDialog();
    }

    if (this.showEditDialog && this.selectedUser) {
      this.buildEditDialog();
    }
  }

  @Builder
  buildConfirmDialog(title: string, message: string, onConfirm: () => void, onCancel: () => void, isDanger: boolean) {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(onCancel);

      Column() {
        // 顶部装饰条
        Row()
          .width('95%')
          .height(3)
          .backgroundColor(isDanger ? this.COLOR_PRIMARY : this.COLOR_GOLD);

        Column() {
          // 图标
          Text(isDanger ? '⚠' : 'ℹ')
            .fontSize(48)
            .fontColor(isDanger ? this.COLOR_PRIMARY : this.COLOR_GOLD)
            .margin({ top: 24, bottom: 16 });

          Text(title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .margin({ bottom: 12 });

          Text(message)
            .fontSize(15)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })
            .padding({ left: 8, right: 8 });

          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor(this.COLOR_TEXT_SECONDARY)
              .backgroundColor(this.COLOR_BG)
              .borderRadius(22)
              .onClick(onCancel);

            Button(isDanger ? '确认踢出' : '确认重置')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(isDanger ? this.COLOR_PRIMARY : this.COLOR_PRIMARY)
              .borderRadius(22)
              .margin({ left: 12 })
              .onClick(onConfirm);
          }
          .width('100%')
          .margin({ bottom: 24 });
        }
        .width('100%')
        .padding({ left: 20, right: 20 });
      }
      .width('76%')
      .backgroundColor(this.COLOR_CARD)
      .borderRadius(16)
      .shadow({ radius: 12, color: '#00000030', offsetX: 0, offsetY: 4 });
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(10000);
  }

  @Builder
  buildDuesAmountDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(() => {
          this.showDuesAmountDialog = false;
          this.newDuesAmount = 0;
        });

      Column() {
        // 顶部装饰条
        Row()
          .width('95%')
          .height(3)
          .backgroundColor(this.COLOR_GOLD);

        Column() {
          // 图标
          Text('¥')
            .fontSize(40)
            .fontColor(this.COLOR_GOLD)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 24, bottom: 12 });

          Text('设置党费金额')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .margin({ bottom: 8 });

          Text(`为 ${this.selectedUser?.name} 设置每日党费金额`)
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 });

          // 金额输入区
          Column() {
            Text('每日金额')
              .fontSize(13)
              .fontColor(this.COLOR_TEXT_SECONDARY)
              .margin({ bottom: 8 });

            Row() {
              Text('¥')
                .fontSize(24)
                .fontColor(this.COLOR_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .margin({ right: 8 });

              TextInput({
                placeholder: '0.00',
                text: this.newDuesAmount > 0 ? this.newDuesAmount.toString() : ''
              })
                .width(140)
                .height(52)
                .fontSize(22)
                .fontColor(this.COLOR_TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .backgroundColor(this.COLOR_BG)
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .onChange((value: string) => {
                  this.newDuesAmount = parseFloat(value) || 0;
                });
            }
            .width('100%')
            .justifyContent(FlexAlign.Center);
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.COLOR_BG)
          .borderRadius(12)
          .margin({ bottom: 24 });

          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor(this.COLOR_TEXT_SECONDARY)
              .backgroundColor(this.COLOR_BG)
              .borderRadius(22)
              .onClick(() => {
                this.showDuesAmountDialog = false;
                this.newDuesAmount = 0;
              });

            Button('确认设置')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(this.COLOR_PRIMARY)
              .borderRadius(22)
              .margin({ left: 12 })
              .onClick(async () => {
                if (this.selectedUser && this.newDuesAmount > 0) {
                  await this.updateDuesAmount(this.selectedUser.id, this.newDuesAmount);
                  this.showDuesAmountDialog = false;
                  this.newDuesAmount = 0;
                } else {
                  promptAction.showToast({ message: '请输入有效的金额', duration: 2000 });
                }
              });
          }
          .width('100%')
          .margin({ bottom: 24 });
        }
        .width('100%')
        .padding({ left: 20, right: 20 });
      }
      .width('76%')
      .backgroundColor(this.COLOR_CARD)
      .borderRadius(16)
      .shadow({ radius: 12, color: '#00000030', offsetX: 0, offsetY: 4 });
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(10000);
  }

  @Builder
  buildEditDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(() => {
          this.showEditDialog = false;
        });

      Column() {
        // 顶部装饰条
        Row()
          .width('95%')
          .height(3)
          .backgroundColor(this.COLOR_GOLD);

        Column() {
          // 头部
          Row() {
            Row() {
              Text('‹')
                .fontSize(28)
                .fontColor(this.COLOR_TEXT_PRIMARY)
                .margin({ bottom: 6 })
                .onClick(() => {
                  this.showEditDialog = false;
                });
            }
            .width(44)
            .height(44)
            .justifyContent(FlexAlign.Center);

            Text('编辑成员信息')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.COLOR_TEXT_PRIMARY)
              .layoutWeight(1)
              .textAlign(TextAlign.Center);

            Row()
              .width(44)
              .height(44);
          }
          .width('100%')
          .margin({ top: 16, bottom: 20 });

          Scroll() {
            Column() {
              this.EditRow('姓名', this.selectedUser!.name, (value: string) => {
                if (this.selectedUser) this.selectedUser.name = value;
              });
              this.EditRow('党号', this.selectedUser!.partyId, (value: string) => {
                if (this.selectedUser) this.selectedUser.partyId = value;
              });
              this.EditRow('联系方式', this.selectedUser!.phone || '', (value: string) => {
                if (this.selectedUser) this.selectedUser.phone = value;
              });
              this.EditRow('邮箱', this.selectedUser!.email || '', (value: string) => {
                if (this.selectedUser) this.selectedUser.email = value;
              });
              this.EditRow('入党时间', this.selectedUser!.joinDate || '', (value: string) => {
                if (this.selectedUser) this.selectedUser.joinDate = value;
              });
            }
            .width('100%')
            .padding({ bottom: 20 });
          }
            .layoutWeight(1)
            .scrollBar(BarState.Off);

          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor(this.COLOR_TEXT_SECONDARY)
              .backgroundColor(this.COLOR_BG)
              .borderRadius(22)
              .onClick(() => {
                this.showEditDialog = false;
              });

            Button('保存')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(this.COLOR_PRIMARY)
              .borderRadius(22)
              .margin({ left: 12 })
              .onClick(async () => {
                if (this.selectedUser) {
                  await this.updateUserInfo(this.selectedUser);
                  this.showEditDialog = false;
                }
              });
          }
          .width('100%')
          .margin({ bottom: 20 });
        }
        .width('100%')
        .padding({ left: 20, right: 20 });
      }
      .width('84%')
      .height('72%')
      .backgroundColor(this.COLOR_CARD)
      .borderRadius(16)
      .shadow({ radius: 12, color: '#00000030', offsetX: 0, offsetY: 4 });
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(10000);
  }

  @Builder
  EditRow(label: string, value: string, onChange: (value: string) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor(this.COLOR_TEXT_SECONDARY);

        Text('*')
          .fontSize(14)
          .fontColor(this.COLOR_PRIMARY)
          .visibility(label === '姓名' || label === '党号' ? Visibility.Visible : Visibility.Hidden);
      }
      .margin({ bottom: 8 });

      TextInput({
        placeholder: `请输入${label}`,
        text: value
      })
        .width('100%')
        .height(48)
        .fontSize(15)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .backgroundColor(this.COLOR_BG)
        .borderRadius(10)
        .border({ width: 1, color: this.COLOR_DIVIDER })
        .padding({ left: 16, right: 16 })
        .onChange(onChange);
    }
    .width('100%')
    .margin({ bottom: 16 });
  }
}
