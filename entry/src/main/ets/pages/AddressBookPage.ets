import router from '@ohos.router';
import { UserService, ApiResponse, User } from '../models/UserModel';
import promptAction from '@ohos.promptAction';
import { pinyin } from 'pinyin-pro';

// 🔧 优化1：使用严格的联合类型，提升代码安全性
interface ViewItem {
  id: string;
  type: 'header' | 'contact'; // 明确类型，避免拼写错误
  letter?: string;
  user?: User;
}

@Entry
@Component
export struct AddressBookPage {
  @State users: User[] = [];
  @State filteredUsers: User[] = [];
  @State recentContacts: User[] = [];
  @State viewList: ViewItem[] = [];
  @State isLoading: boolean = false;
  @State searchText: string = '';
  @State selectedIndex: number = 0;

  private userService: UserService = new UserService();
  private alphabet: string[] = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'];

  // 🔧 优化2：修正类型为 Scroller (API标准类型)
  private listScroller: Scroller = new Scroller();
  private isClickScroll: boolean = false;

  // --- 拼音工具逻辑保持不变 ---
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
      if (py && py.length > 0) {
        return py.charAt(0).toUpperCase();
      }
    }
    return '#';
  }

  // --- UI 构建 ---
  @Builder
  ContactItem(user: User) {
    Row() {
      if (user.avatar) {
        Image(user.avatar)
          .width(60)
          .height(60)
          .borderRadius(30)
          .margin({ right: 12 })
          .objectFit(ImageFit.Cover);
      } else {
        Text(user.name.charAt(0))
          .width(60)
          .height(60)
          .borderRadius(30)
          .backgroundColor('#D32F2F')
          .fontColor('#fff')
          .fontSize(24)
          .textAlign(TextAlign.Center)
          .margin({ right: 12 });
      }
      Column() {
        Text(user.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 });
        Text(user.branch)
          .fontSize(14)
          .fontColor('#999999');
      }
      .width('100%')
      .layoutWeight(1);

      Text('>')
        .width(20)
        .height(20)
        .fontColor('#666666')
        .textAlign(TextAlign.Center);
    }
    .padding(20)
    .backgroundColor('#fff')
    .onClick(() => {
      router.pushUrl({
        url: 'pages/UserDetailPage',
        params: { userId: user.id }
      });
    });
  }

  @Builder
  HeaderItem(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor('#999999')
      .padding({ left: 20, top: 16, bottom: 8 })
      .width('100%')
      .backgroundColor('#F5F5F5');
  }

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const response = await this.userService.getBranchMembers();
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
      promptAction.showToast({
        message: '加载失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  generateViewList() {
    const list: ViewItem[] = [];

    // 1. 最近联系人
    if (this.recentContacts.length > 0 && !this.searchText) {
      list.push({ id: 'header_recent', type: 'header', letter: '最近' });
      this.recentContacts.forEach((user: User) => {
        list.push({ id: `recent_${user.id}`, type: 'contact', user: user });
      });
    }

    // 2. 字母分组
    const groupsMap = new Map<string, User[]>();
    this.alphabet.forEach((letter: string) => groupsMap.set(letter, []));

    this.filteredUsers.forEach((user: User) => {
      const letter = this.getFirstLetter(user.name);
      groupsMap.get(letter)?.push(user);
    });

    this.alphabet.forEach((letter: string) => {
      const users = groupsMap.get(letter);
      if (users && users.length > 0) {
        list.push({ id: `header_${letter}`, type: 'header', letter: letter });
        users.forEach((user: User) => {
          list.push({ id: `item_${user.id}`, type: 'contact', user: user, letter: letter });
        });
      }
    });

    this.viewList = list;
  }

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

  // --- 核心联动逻辑 (已优化稳定性) ---

  // 1. 点击字母 -> 列表滚动
  // 1. 点击字母 -> 列表滚动 (修复版)
  onLetterSelect(index: number) {
    this.selectedIndex = index;
    const targetLetter = this.alphabet[index];

    // 查找目标索引
    const targetIndex = this.viewList.findIndex(
      item => item.type === 'header' && item.letter === targetLetter
    );

    if (targetIndex !== -1) {
      this.isClickScroll = true;

      // 🔧 修复：API 20 仅支持 (index, smooth) 两个参数
      this.listScroller.scrollToIndex(targetIndex, true);

      // 恢复锁状态
      setTimeout(() => {
        this.isClickScroll = false;
      }, 500);
    }
  }
  // 2. 列表滚动 -> 字母高亮
  onListScroll(start: number) {
    if (this.isClickScroll || start < 0 || start >= this.viewList.length) {
      return;
    }

    // 向前查找最近的 Header
    let currentLetter: string = '';
    for (let i = start; i >= 0; i--) {
      const tempItem = this.viewList[i];
      if (tempItem.type === 'header') {
        currentLetter = tempItem.letter || '';
        break;
      }
    }

    // 更新索引 (排除"最近"分组)
    if (currentLetter && currentLetter !== '最近') {
      const idx = this.alphabet.indexOf(currentLetter);
      if (idx !== -1 && this.selectedIndex !== idx) {
        this.selectedIndex = idx;
      }
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .backgroundColor(Color.Transparent)
          .fontColor('#D32F2F')
          .onClick(() => router.back());

        Text('通讯录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Button('更多')
          .backgroundColor(Color.Transparent)
          .fontColor('#666666')
          .fontSize(14)
          .onClick(() => {
            promptAction.showToast({ message: '更多功能开发中', duration: 2000 });
          });
      }
      .width('100%')
      .height(56)
      .backgroundColor('#fff')
      .shadow({ radius: 2, color: '#00000010', offsetX: 0, offsetY: 2 });

      // 搜索栏
      Row() {
        Row() {
          Text('🔍')
            .width(20)
            .height(20)
            .margin({ left: 16, right: 8 });
          TextInput({ placeholder: '搜索联系人', text: this.searchText })
            .width('100%')
            .height(40)
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => this.onSearch(value));
        }
        .width('90%')
        .height(40)
        .backgroundColor('#F0F0F0')
        .borderRadius(20);
      }
      .width('100%')
      .height(60)
      .backgroundColor('#fff')
      .alignItems(VerticalAlign.Center)
      .padding({ bottom: 10 });

      // 成员列表
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40);
        }
        .width('100%')
        .layoutWeight(1) // 🔧 优化5：撑满剩余空间
        .justifyContent(FlexAlign.Center);
      } else {
        // 🔧 优化6：Stack 配置对齐方式，替代绝对定位
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
          .height('100%') // 🔧 优化7：Stack 内使用 height 替代 layoutWeight
          .backgroundColor('#F5F5F5')
          .cachedCount(20) // 🔧 优化8：性能优化，缓存列表项
          .onScrollIndex((start: number) => {
            this.onListScroll(start);
          });

          // 字母索引
          AlphabetIndexer({
            arrayValue: this.alphabet,
            selected: this.selectedIndex
          })
            .width(30)
            .height('80%')
            .margin({ right: 10 }) // 🔧 优化9：使用 margin 替代 position
            .selectedColor('#D32F2F')
            .color('#666666')
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
    .backgroundColor('#F5F5F5');
  }
}