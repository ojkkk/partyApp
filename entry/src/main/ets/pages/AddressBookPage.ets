import router from '@ohos.router';
import { UserService, ApiResponse, User } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { pinyin } from 'pinyin-pro';
import { AvatarComponent } from '../components/AvatarComponent';

// 严格类型定义（无功能改动，仅提升安全性）
interface ViewItem {
  id: string;
  type: 'header' | 'contact';
  letter?: string;
  user?: User;
}

@Entry
@Component
export struct AddressBookPage {
  // 所有状态变量 100% 保留原定义
  @State users: User[] = [];
  @State filteredUsers: User[] = [];
  @State recentContacts: User[] = [];
  @State viewList: ViewItem[] = [];
  @State isLoading: boolean = false;
  @State searchText: string = '';
  @State selectedIndex: number = 0;

  private userService: UserService = new UserService();
  private alphabet: string[] = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'];

  // API20 标准类型，保留原定义
  private listScroller: Scroller = new Scroller();
  private isClickScroll: boolean = false;
  // 新增：滚动防抖标记，避免频繁触发（无功能影响，仅优化流畅度）
  private scrollDebounceTimer: number | null = null;

  // ===================== 颜色配置 - 庄重红金正式风 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';      // 绛红
  private readonly COLOR_PRIMARY_LIGHT = '#D83A34'; // 亮红
  private readonly COLOR_GOLD = '#C9A45C';         // 暖金
  private readonly COLOR_GOLD_DARK = '#A67C2E';    // 深金
  private readonly COLOR_BG = '#F7F4EF';           // 米白背景
  private readonly COLOR_CARD = '#FFFFFF';         // 卡片白
  private readonly COLOR_TEXT_PRIMARY = '#1F1F1F'; // 主文字
  private readonly COLOR_TEXT_SECONDARY = '#666666'; // 次要文字
  private readonly COLOR_TEXT_TERTIARY = '#999999';  // 辅助文字
  private readonly COLOR_BORDER = '#EFE7DB';       // 金色边框
  private readonly COLOR_DIVIDER = '#F0EBE3';      // 分割线

  // ===================== 拼音工具方法（完全保留） =====================
  getFullPinyin(name: string): string {
    if (!name) return '';
    const r = pinyin(name, { toneType: 'none' });
    return Array.isArray(r) ? r.join('') : r;
  }

  getFirstLetter(name: string): string {
    if (!name) return '#';
    const ch = name.charAt(0);
    if (/^[a-zA-Z]$/.test(ch)) {
      return ch.toUpperCase();
    }
    if (ch >= '\u4e00' && ch <= '\u9fa5') {
      const py = pinyin(ch, { toneType: 'none' });
      return py ? py.charAt(0).toUpperCase() : '#';
    }
    return '#';
  }

  // ===================== UI 构建器（庄重红金风格） =====================
  @Builder
  ContactItem(user: User) {
    Row() {
      AvatarComponent({
        user: {
          avatar: user.avatar,
          name: user.name
        },
        avatarSize: 48
      })

      Column() {
        Text(user.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY)
          .margin({ bottom: 4 });
        Text(user.branch)
          .fontSize(13)
          .fontColor(this.COLOR_TEXT_SECONDARY);
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ left: 12 });

      // 右箭头使用绛红色
      Text('›')
        .fontSize(24)
        .fontColor(this.COLOR_GOLD)
        .fontWeight(FontWeight.Regular);
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/UserDetailPage',
        params: { userId: user.id }
      });
    });
  }

  @Builder
  HeaderItem(title: string) {
    Row() {
      // 左侧红色装饰条
      Row()
        .width(3)
        .height(14)
        .backgroundColor(this.COLOR_PRIMARY)
        .borderRadius(1.5)
        .margin({ right: 8 });

      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.COLOR_PRIMARY);
    }
    .width('100%')
    .padding({ left: 16, top: 12, bottom: 8 })
    .backgroundColor(this.COLOR_BG);
  }

  // ===================== 生命周期 & 数据加载（完全保留） =====================
  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const response: ApiResponse<User[]> = await this.userService.getBranchMembers();
      if (response.code === 200 && response.data) {
        this.users = response.data.sort((a: User, b: User) => {
          return this.getFullPinyin(a.name).localeCompare(this.getFullPinyin(b.name));
        });
        this.filteredUsers = [...this.users];
        this.recentContacts = this.users.slice(0, 3);
        this.generateViewList();
      }
    } catch (error) {
      console.error('加载失败:', error);
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  // ===================== 列表数据生成（完全保留逻辑） =====================
  generateViewList() {
    const list: ViewItem[] = [];

    // 最近联系人
    if (this.recentContacts.length > 0 && !this.searchText) {
      list.push({ id: 'header_recent', type: 'header', letter: '最近' });
      this.recentContacts.forEach((user: User) => {
        list.push({ id: `recent_${user.id}`, type: 'contact', user: user });
      });
    }

    // 字母分组
    const groupsMap = new Map<string, User[]>();
    this.alphabet.forEach(letter => groupsMap.set(letter, []));

    this.filteredUsers.forEach((user: User) => {
      const letter = this.getFirstLetter(user.name);
      groupsMap.get(letter)?.push(user);
    });

    this.alphabet.forEach((letter: string) => {
      const users = groupsMap.get(letter);
      if (users?.length) {
        list.push({ id: `header_${letter}`, type: 'header', letter: letter });
        users.forEach((user: User) => {
          list.push({ id: `item_${user.id}`, type: 'contact', user: user, letter: letter });
        });
      }
    });

    this.viewList = list;
  }

  // ===================== 搜索逻辑（完全保留） =====================
  onSearch(value: string) {
    this.searchText = value;
    this.filteredUsers = value
      ? this.users.filter((user: User) =>
      user.name.toLowerCase().includes(value.toLowerCase()) ||
      user.branch.toLowerCase().includes(value.toLowerCase())
      )
      : [...this.users];
    this.generateViewList();
  }

  // ===================== 核心联动逻辑（修复bug，无功能改动） =====================
  onLetterSelect(index: number) {
    if (this.isClickScroll) return;
    this.selectedIndex = index;
    const targetLetter = this.alphabet[index];

    const targetIndex = this.viewList.findIndex(
      item => item.type === 'header' && item.letter === targetLetter
    );

    if (targetIndex === -1) return;

    this.isClickScroll = true;
    this.listScroller.scrollToIndex(targetIndex, true);

    setTimeout(() => {
      this.isClickScroll = false;
    }, 300);
  }

  onListScroll(start: number) {
    if (this.scrollDebounceTimer) clearTimeout(this.scrollDebounceTimer);
    this.scrollDebounceTimer = setTimeout(() => {
      if (this.isClickScroll || start < 0 || start >= this.viewList.length) return;

      let currentLetter = '';
      for (let i = start; i >= 0; i--) {
        const tempItem = this.viewList[i];
        if (tempItem.type === 'header') {
          currentLetter = tempItem.letter || '';
          break;
        }
      }

      if (currentLetter && currentLetter !== '最近') {
        const idx = this.alphabet.indexOf(currentLetter);
        if (idx !== -1 && this.selectedIndex !== idx) {
          this.selectedIndex = idx;
        }
      }
    }, 50);
  }

  // ===================== 页面布局（庄重红金正式风） =====================
  build() {
    Column() {
      // 顶部导航栏 - 绛红渐变背景
      Stack({ alignContent: Alignment.Bottom }) {
        // 渐变背景层
        Row()
          .width('100%')
          .height('100%')
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [['#B51F2E', 0], ['#D83A34', 1]]
          });

        // 导航内容
        Row() {
          // 返回按钮 - 固定宽度容器
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

          // 标题
          Text('通讯录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .textAlign(TextAlign.Center);

          // 右侧占位 - 与左侧同宽
          Row()
            .width(56)
            .height('100%');
        }
        .width('100%')
        .height(56)
        .padding({ top: 8 });

        // 底部金色装饰线
        Row()
          .width('100%')
          .height(1)
          .backgroundColor('rgba(201, 164, 92, 0.4)');
      }
      .width('100%')
      .height(56);

      // 搜索栏 - 统一搜索样式
      Row() {
        Row() {
          Image($rawfile('搜索.png'))
            .width(18)
            .height(18)
            .margin({ left: 12, right: 8 })
            .fillColor(this.COLOR_PRIMARY);

          TextInput({ placeholder: '搜索联系人', text: this.searchText })
            .placeholderColor(this.COLOR_TEXT_TERTIARY)
            .fontSize(14)
            .width('100%')
            .height(40)
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => this.onSearch(value));
        }
        .width('100%')
        .height(40)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .border({ width: 1, color: this.COLOR_BORDER });
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.COLOR_BG);

      // 成员列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.COLOR_PRIMARY);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.COLOR_BG);
      } else {
        Stack({ alignContent: Alignment.TopEnd }) {
          // 联系人列表
          List({ scroller: this.listScroller }) {
            ForEach(this.viewList, (item: ViewItem) => {
              ListItem() {
                if (item.type === 'header') {
                  this.HeaderItem(item.letter || '');
                } else if (item.type === 'contact' && item.user) {
                  this.ContactItem(item.user);
                }
              }
            }, (item: ViewItem) => item.id);
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.COLOR_BG)
          .cachedCount(20)
          .divider({ strokeWidth: 0.5, color: this.COLOR_DIVIDER })
          .onScrollIndex((start: number) => {
            this.onListScroll(start);
          });

          // 字母索引条 - 绛红选中色
          AlphabetIndexer({
            arrayValue: this.alphabet,
            selected: this.selectedIndex
          })
            .width(28)
            .height('75%')
            .margin({ right: 4 })
            .selectedColor(this.COLOR_PRIMARY)
            .color(this.COLOR_TEXT_TERTIARY)
            .font({ size: 11 })
            .selectedFont({ size: 12, weight: FontWeight.Medium })
            .onSelected((index: number) => {
              this.onLetterSelect(index);
            });
        }
        .width('100%')
        .layoutWeight(1);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.COLOR_BG);
  }
}
