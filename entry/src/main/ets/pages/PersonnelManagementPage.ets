import { UserInfo, User, UserService, ApiResponse } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AvatarComponent } from '../components/AvatarComponent';
import { pinyin } from 'pinyin-pro';

// 标准党旗红主色，符合党建应用规范
const PRIMARY_COLOR: string = '#C8102E';
const BG_COLOR: string = '#F5F7FA';
const CARD_BG: string = '#FFFFFF';
const TEXT_MAIN: string = '#181818';
const TEXT_SECOND: string = '#666666';
const TEXT_GRAY: string = '#999999';

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

    // 筛选
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

    // 排序
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
      // 调用后端API踢出成员
      const response = await this.userService.kickMember(userId);
      if (response.code === 200) {
        promptAction.showToast({ message: '踢出成员成功', duration: 2000 });
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

  getAge(birthDate: string): number {
    const birth = new Date(birthDate);
    const now = new Date();
    const diff = now.getTime() - birth.getTime();
    return Math.floor(diff / (1000 * 60 * 60 * 24 * 365.25));
  }

  // 获取姓名的拼音
  getFullPinyin(name: string): string {
    if (!name) return '';
    const r = pinyin(name, { toneType: 'none' });
    return Array.isArray(r) ? r.join('') : r;
  }

  @Builder
  UserCard(user: User) {
    Row() {
      AvatarComponent({
        user: {
          avatar: user.avatar,
          name: user.name
        },
        avatarSize: 60
      })

      Column() {
        Row() {
          Text(user.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_MAIN)
          Text(user.role === 'admin' ? '系统管理员' : user.role === 'branch_admin' ? '支部管理员' : '党员')
            .fontSize(12)
            .fontColor(PRIMARY_COLOR)
            .backgroundColor('#FFF8E1')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .margin({ left: 8 })
        }

        Text(`党号: ${user.partyId}`)
          .fontSize(14)
          .fontColor(TEXT_SECOND)
          .margin({ top: 4 })

        Text(`入党时间: ${user.joinDate || '未设置'}`)
          .fontSize(14)
          .fontColor(TEXT_SECOND)
          .margin({ top: 2 })

        if (user.joinDate) {
          Text(`党龄: ${this.getPartyAge(user.joinDate)}年`)
            .fontSize(14)
            .fontColor(TEXT_SECOND)
            .margin({ top: 2 })
        }
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('>')
        .fontSize(16)
        .fontColor(TEXT_GRAY)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(12)
    .shadow({
      radius: 6,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.selectedUser = user;
      this.showUserDetail = true;
    })
  }

  @Builder
  UserDetailDialog() {
    // 背景虚化
    Stack() {
      // 虚化背景
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.3)')
      .onClick(() => {
        // 点击背景关闭弹窗
        this.showUserDetail = false;
      })

      // 弹窗内容
      Column() {
        if (!this.selectedUser) {
          Text('无选中用户')
            .fontSize(16)
            .fontColor(TEXT_SECOND)
        } else {
          Row() {
            Button() {
              Image($rawfile('返回.png'))
                .width(20)
                .height(20)

            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.showUserDetail = false;
            })
            
            Text('成员详情')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
              .layoutWeight(1)

              .margin({left:74})
            Blank()
              .width(60)
          }
          .width('100%')
          .margin({ bottom: 20 })

        Scroll() {
          Column() {
            // 基本信息
            Row() {
              AvatarComponent({
                user: {
                  avatar: this.selectedUser.avatar,
                  name: this.selectedUser.name
                },
                avatarSize: 80
              })

              Column() {
                Text(this.selectedUser.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_MAIN)
                Text(this.selectedUser.role === 'admin' ? '系统管理员' : this.selectedUser.role === 'branch_admin' ? '支部管理员' : '党员')
                  .fontSize(14)
                  .fontColor(PRIMARY_COLOR)
                  .margin({ top: 4 })
              }
              .margin({ left: 16 })
            }
            .margin({ bottom: 20 })

            // 详细信息
            Column() {
              this.InfoRow('党号', this.selectedUser.partyId);
              this.InfoRow('所属支部', this.selectedUser.branch);
              this.InfoRow('入党时间', this.selectedUser.joinDate || '未设置');
              if (this.selectedUser.joinDate) {
                this.InfoRow('党龄', `${this.getPartyAge(this.selectedUser.joinDate)}年`);
              }
              this.InfoRow('联系方式', this.selectedUser.phone || '未设置');
              this.InfoRow('邮箱', this.selectedUser.email || '未设置');
              this.InfoRow('注册时间', this.selectedUser.registrationDate || '未设置');
            }
          }
          .width('100%')
        }
        .layoutWeight(1)

        // 操作按钮
        Column() {
          Row() {
            Button('编辑信息')
              .width('48%')
              .height(44)
              .fontSize(14)
              .fontColor(PRIMARY_COLOR)
              .backgroundColor('#FFF8E1')
              .borderRadius(22)
              .onClick(() => {
                this.showEditDialog = true;
                this.showUserDetail = false;
              })

            Button('重置密码')
              .width('48%')
              .height(44)
              .fontSize(14)
              .fontColor(PRIMARY_COLOR)
              .backgroundColor('#FFF8E1')
              .borderRadius(22)
              .margin({ left: '4%' })
              .onClick(() => {
                this.showResetPasswordDialog = true;
                this.showUserDetail = false;
              })
          }
          .width('100%')
          .margin({ top: 16 })

          Row() {
            Button('党费设置')
              .width('48%')
              .height(44)
              .fontSize(14)
              .fontColor(PRIMARY_COLOR)
              .backgroundColor('#FFF8E1')
              .borderRadius(22)
              .onClick(() => {
                this.showDuesAmountDialog = true;
                this.showUserDetail = false;
              })

            Button('踢出支部')
              .width('48%')
              .height(44)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF3B30')
              .borderRadius(22)
              .margin({ left: '4%' })
              .onClick(() => {
                this.showKickDialog = true;
                this.showUserDetail = false;
              })
          }
          .width('100%')
          .margin({ top: 12 })
        }
        .width('100%')
        .margin({ top: 20 })
        }
      }
      .width('80%')
      .height('80%')
      .padding(20)
      .backgroundColor(CARD_BG)
      .borderRadius(16)
      .shadow({
        radius: 10,
        color: '#00000020',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(9999)
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(TEXT_SECOND)
        .width(80)
      Text(value)
        .fontSize(14)
        .fontColor(TEXT_MAIN)
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  SortFilterBar() {
    Column() {
      // 搜索框
      Row() {
        Image($rawfile("搜索.png"))
          .width(20)
          .height(20)
          .margin({ left: 16 })
        TextInput({
          placeholder: '搜索成员姓名、党号、联系方式',
          text: this.searchText
        })
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .padding({ left: 8, right: 16 })
          .fontSize(15)
          .placeholderColor(TEXT_GRAY)
          .onChange((value: string) => {
            this.searchText = value;
            this.applyFilterAndSort();
          })
      }
      .width('100%')
      .height(44)
      .backgroundColor('#F5F7FA')
      .borderRadius(22)
      .margin({ bottom: 12 })

      // 筛选和排序
      Row() {
        // 角色筛选
        Button(this.filterRole === 'all' ? '全部角色' : 
               this.filterRole === 'admin' ? '系统管理员' : 
               this.filterRole === 'branch_admin' ? '支部管理员' : '党员')
          .width(130)
          .height(36)
          .fontSize(14)
          .fontColor(PRIMARY_COLOR)
          .backgroundColor('#FFF8E1')
          .borderRadius(18)
          .onClick(() => {
            this.filterRole = this.filterRole === 'all' ? 'admin' : 
                             this.filterRole === 'admin' ? 'branch_admin' : 
                             this.filterRole === 'branch_admin' ? 'member' : 'all';
            this.applyFilterAndSort();
          })

        // 排序
        Row() {
          Text('排序: ')
            .fontSize(14)
            .fontColor(TEXT_SECOND)
          Button(this.sortBy === 'name' ? '姓名' : 
                 this.sortBy === 'joinDate' ? '入党时间' : '角色')
            .width(100)
            .height(36)
            .fontSize(14)
            .fontColor(PRIMARY_COLOR)
            .backgroundColor('#FFF8E1')
            .borderRadius(18)
            .onClick(() => {
              this.sortBy = this.sortBy === 'name' ? 'joinDate' : 
                           this.sortBy === 'joinDate' ? 'role' : 'name';
              this.applyFilterAndSort();
            })
          Button(this.sortOrder === 'asc' ? '↑' : '↓')
            .width(40)
            .height(36)
            .fontSize(14)
            .fontColor(PRIMARY_COLOR)
            .backgroundColor('#FFF8E1')
            .borderRadius(18)
            .margin({ left: 8 })
            .onClick(() => {
              this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
              this.applyFilterAndSort();
            })
        }
        .margin({ left: 12 })

        Blank()


      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
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
        .backgroundColor(Color.Transparent)
        .onClick(() => router.back())

        Text('人员管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .layoutWeight(1)
          .margin({left:91})
        Blank()
        .width(44)
      }
      .width('100%')
      .height(64)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16 })
      .backgroundColor(CARD_BG)
      .shadow({
        radius: 4,
        color: '#0A000000',
        offsetX: 0,
        offsetY: 1
      })

      // 成员详情弹窗
      if (this.showUserDetail) {
        this.UserDetailDialog();
      }

      // 筛选排序栏
      this.SortFilterBar()

      // 成员列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(PRIMARY_COLOR)
          Text('加载中...')
            .fontSize(14)
            .fontColor(TEXT_GRAY)
            .margin({ top: 12 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredMembers.length === 0) {
        Column() {
          Text('暂无成员')
            .fontSize(16)
            .fontColor(TEXT_SECOND)
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filteredMembers, (member: User) => {
            ListItem() {
              this.UserCard(member)
            }
            .margin({ left: 16, right: 16, top: 12 })
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      // 踢出确认弹窗
      if (this.showKickDialog && this.selectedUser) {
        Column() {
          Text('确认踢出')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .margin({ bottom: 16 })

          Text(`确定要将 ${this.selectedUser.name} 踢出支部吗？`)
            .fontSize(16)
            .fontColor(TEXT_SECOND)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor(TEXT_SECOND)
              .backgroundColor('#F5F7FA')
              .borderRadius(22)
              .onClick(() => {
                this.showKickDialog = false;
              })

            Button('确认踢出')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF3B30')
              .borderRadius(22)
              .margin({ left: 12 })
              .onClick(async () => {
                if (this.selectedUser) {
                  await this.kickMember(this.selectedUser.id);
                  this.showKickDialog = false;
                }
              })
          }
          .width('100%')
        }
        .width('60%')
        .padding(20)
        .backgroundColor(CARD_BG)
        .borderRadius(16)
        .position({ x: '20%', y: '40%' })
      }

      // 密码重置弹窗
      if (this.showResetPasswordDialog && this.selectedUser) {
        Column() {
          Text('重置密码')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .margin({ bottom: 16 })

          Text(`确定要重置 ${this.selectedUser.name} 的密码吗？\n重置后密码将恢复为默认值。`)
            .fontSize(16)
            .fontColor(TEXT_SECOND)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor(TEXT_SECOND)
              .backgroundColor('#F5F7FA')
              .borderRadius(22)
              .onClick(() => {
                this.showResetPasswordDialog = false;
              })

            Button('确认重置')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(PRIMARY_COLOR)
              .borderRadius(22)
              .margin({ left: 12 })
              .onClick(async () => {
                if (this.selectedUser) {
                  await this.resetPassword(this.selectedUser.id);
                  this.showResetPasswordDialog = false;
                }
              })
          }
          .width('100%')
        }
        .width('60%')
        .padding(20)
        .backgroundColor(CARD_BG)
        .borderRadius(16)
        .position({ x: '20%', y: '40%' })
      }

      // 党费金额设置弹窗
      if (this.showDuesAmountDialog && this.selectedUser) {
        Column() {
          Text('设置党费金额')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .margin({ bottom: 16 })

          Text(`为 ${this.selectedUser.name} 设置每日党费金额`)
            .fontSize(16)
            .fontColor(TEXT_SECOND)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 20 })

          Row() {
            Text('每日金额: ¥')
              .fontSize(16)
              .fontColor(TEXT_MAIN)
            TextInput({
              placeholder: '请输入金额',
              text: this.newDuesAmount.toString()
            })
              .width(120)
              .height(44)
              .fontSize(16)
              .fontColor(TEXT_MAIN)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.newDuesAmount = parseFloat(value) || 0;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 24 })

          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor(TEXT_SECOND)
              .backgroundColor('#F5F7FA')
              .borderRadius(22)
              .onClick(() => {
                this.showDuesAmountDialog = false;
                this.newDuesAmount = 0;
              })

            Button('确认设置')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(PRIMARY_COLOR)
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
              })
          }
          .width('100%')
        }
        .width('60%')
        .padding(20)
        .backgroundColor(CARD_BG)
        .borderRadius(16)
        .position({ x: '20%', y: '40%' })
      }

      // 编辑信息弹窗
      if (this.showEditDialog && this.selectedUser) {
        Column() {
          Text('编辑成员信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .margin({ bottom: 20 })

          Scroll() {
            Column() {
              this.EditRow('姓名', this.selectedUser.name, (value: string) => {
                if (this.selectedUser) this.selectedUser.name = value;
              });
              this.EditRow('党号', this.selectedUser.partyId, (value: string) => {
                if (this.selectedUser) this.selectedUser.partyId = value;
              });
              this.EditRow('联系方式', this.selectedUser.phone || '', (value: string) => {
                if (this.selectedUser) this.selectedUser.phone = value;
              });
              this.EditRow('邮箱', this.selectedUser.email || '', (value: string) => {
                if (this.selectedUser) this.selectedUser.email = value;
              });
              this.EditRow('入党时间', this.selectedUser.joinDate || '', (value: string) => {
                if (this.selectedUser) this.selectedUser.joinDate = value;
              });
            }
            .width('100%')
          }
          .layoutWeight(1)

          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor(TEXT_SECOND)
              .backgroundColor('#F5F7FA')
              .borderRadius(22)
              .onClick(() => {
                this.showEditDialog = false;
              })

            Button('保存')
              .width('45%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(PRIMARY_COLOR)
              .borderRadius(22)
              .margin({ left: 12 })
              .onClick(async () => {
                if (this.selectedUser) {
                  await this.updateUserInfo(this.selectedUser);
                  this.showEditDialog = false;
                }
              })
          }
          .width('100%')
          .margin({ top: 20 })
        }
        .width('80%')
        .height('70%')
        .padding(20)
        .backgroundColor(CARD_BG)
        .borderRadius(16)
        .position({ x: '10%', y: '15%' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
  }

  @Builder
  EditRow(label: string, value: string, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(TEXT_SECOND)
        .margin({ bottom: 8 })
      TextInput({
        placeholder: `请输入${label}`,
        text: value
      })
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor(TEXT_MAIN)
        .backgroundColor('#F5F7FA')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange(onChange)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }
}
