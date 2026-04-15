import router from '@ohos.router';
import { UserService, ApiResponse, Message } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import { AvatarComponent } from '../components/AvatarComponent';

interface UserStatusData {
  isOnline?: boolean;
  lastSeen?: string;
}

interface SendResultData {}

@Entry
@Component
export struct ChatPage {
  @State messages: Message[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State showEmojiPanel: boolean = false;
  @State isOnline: boolean = false;
  @State lastSeen: string = '';
  private userService: UserService = new UserService();
  private userId: string = '';
  private userName: string = '';
  private userAvatar: string = '';
  private currentUserId: string = '';
  private statusUpdateInterval: number = -1;
  private listScroller: ListScroller = new ListScroller();

  // ===================== 颜色配置 - 庄重红金正式风 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';      // 绛红
  private readonly COLOR_PRIMARY_LIGHT = '#D83A34'; // 亮红
  private readonly COLOR_GOLD = '#C9A45C';         // 暖金
  private readonly COLOR_BG = '#F7F4EF';           // 米白背景
  private readonly COLOR_CARD = '#FFFFFF';         // 卡片白
  private readonly COLOR_TEXT_PRIMARY = '#1F1F1F'; // 主文字
  private readonly COLOR_TEXT_SECONDARY = '#666666'; // 次要文字
  private readonly COLOR_TEXT_TERTIARY = '#999999';  // 辅助文字
  private readonly COLOR_DIVIDER = '#F0EBE3';      // 分割线

  private emojis: string[] = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😋', '😛', '😜', '🤪', '😝',
    '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐',
    '😑', '😶', '😏', '😒', '🙄', '😬', '🤥', '😌',
    '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢',
    '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠',
    '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁', '☹️',
    '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨',
    '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞',
    '😓', '😩', '😫', '🥱', '😤', '😡', '😠', '🤬',
    '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏',
    '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆',
    '🖕', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛',
    '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️',
    '💅', '🤳', '💪', '🦾', '🦿', '🦵', '🦶', '👂',
    '❤️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
    '🔥', '✨', '⭐', '🌟', '💫', '⚡', '☀️', '🌈'
  ];

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.userId && params.userName) {
      this.userId = params.userId;
      this.userName = params.userName;
      this.userAvatar = params.userAvatar || '';
      this.currentUserId = await StorageService.getItemAsync<string>('userId') || '';

      await this.loadMessages();
      await this.loadUserStatus();

      this.statusUpdateInterval = setInterval(async () => {
        await this.loadUserStatus();
      }, 30000);
    } else {
      promptAction.showToast({ message: '参数错误', duration: 2000 });
      router.back();
    }
  }

  aboutToDisappear() {
    if (this.statusUpdateInterval !== -1) {
      clearInterval(this.statusUpdateInterval);
    }
  }

  async loadUserStatus(): Promise<void> {
    try {
      const response: ApiResponse<UserStatusData> = await this.userService.getUserStatus(this.userId);
      if (response.code === 200 && response.data) {
        if (response.data.isOnline !== undefined) {
          this.isOnline = response.data.isOnline;
        }
        if (response.data.lastSeen !== undefined) {
          this.lastSeen = response.data.lastSeen;
        }
      }
    } catch (error) {
      console.error('获取状态失败:', error);
    }
  }

  async loadMessages(): Promise<void> {
    this.isLoading = true;
    try {
      await this.userService.markChatMessageAsRead(this.userId);

      const response: ApiResponse<Message[]> = await this.userService.getMessages(this.userId);
      if (response.code === 200 && response.data) {
        const rawList: Message[] = response.data;
        const newList: Message[] = [];

        for (let i = 0; i < rawList.length; i++) {
          const msg: Message = rawList[i];
          let newMsg: Message = {
            id: msg.id,
            content: msg.content,
            senderId: msg.senderId,
            recipientId: msg.recipientId,
            createdAt: msg.createdAt,
            isSent: msg.senderId === this.currentUserId,
            status: msg.senderId === this.currentUserId ? (msg.isRead ? 'read' : 'sent') : undefined,
            isRead: msg.isRead || false
          };
          newList.push(newMsg);
        }
        this.messages = newList;

        setTimeout(() => {
          this.scrollToBottom(false);
        }, 100);
      }
    } catch (error) {
      console.error('加载失败:', error);
      promptAction.showToast({ message: '加载消息失败' });
    } finally {
      this.isLoading = false;
    }
  }

  scrollToBottom(animate: boolean = true): void {
    if (this.messages.length > 0) {
      this.listScroller.scrollToIndex(this.messages.length - 1, animate);
    }
  }

  async sendMessage(): Promise<void> {
    const content: string = this.inputText.trim();
    if (!content) return;

    const tempId: string = 'temp_' + Date.now();
    const tempMsg: Message = {
      id: tempId,
      content: content,
      senderId: this.currentUserId,
      recipientId: this.userId,
      createdAt: new Date().toISOString(),
      isSent: true,
      status: 'sent',
      isRead: false
    };

    let newMsgs: Message[] = this.messages.concat([tempMsg]);
    this.messages = newMsgs;
    this.inputText = '';
    this.showEmojiPanel = false;
    setTimeout(() => this.scrollToBottom(), 50);

    try {
      const response: ApiResponse<SendResultData> = await this.userService.sendMessage(this.userId, content);
      if (response.code === 200) {
        this.updateMsgStatus(tempId, 'sent');

        if (this.isOnline) {
          setTimeout(() => {
            this.updateMsgStatus(tempId, 'read');
          }, 1000);
        }
      } else {
        throw new Error('发送失败');
      }
    } catch (error) {
      console.error('发送失败:', error);
      promptAction.showToast({ message: '网络异常' });
    }
  }

  updateMsgStatus(id: string, status: 'sent' | 'read'): void {
    const idx: number = this.findMsgIndexById(id);
    if (idx !== -1) {
      let newMsgs: Message[] = this.messages.slice();
      newMsgs[idx].status = status;
      if (status === 'read') {
        newMsgs[idx].isRead = true;
      }
      this.messages = newMsgs;
    }
  }

  findMsgIndexById(id: string): number {
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].id === id) {
        return i;
      }
    }
    return -1;
  }

  formatTime(timestamp: string): string {
    if (!timestamp) return '';
    const date: Date = new Date(timestamp);
    const h: string = (date.getHours() < 10 ? '0' : '') + date.getHours();
    const m: string = (date.getMinutes() < 10 ? '0' : '') + date.getMinutes();
    return h + ':' + m;
  }

  formatDate(timestamp: string): string {
    if (!timestamp) return '';
    const date: Date = new Date(timestamp);
    const now: Date = new Date();
    const year: number = date.getFullYear();
    const month: number = date.getMonth() + 1;
    const day: number = date.getDate();

    if (year === now.getFullYear()) {
      return `${month}月${day}日`;
    } else {
      return `${year}年${month}月${day}日`;
    }
  }

  shouldShowDateDivider(currentMsg: Message, previousMsg?: Message): boolean {
    if (!previousMsg) return true;

    const currentDate: Date = new Date(currentMsg.createdAt);
    const prevDate: Date = new Date(previousMsg.createdAt);

    return currentDate.toDateString() !== prevDate.toDateString();
  }

  getStatusDisplay(status?: 'sent' | 'read'): string {
    if (status === 'read') return '已读';
    return '已发送';
  }

  getStatusColor(status?: 'sent' | 'read'): ResourceColor {
    if (status === 'read') return this.COLOR_GOLD;
    return this.COLOR_TEXT_TERTIARY;
  }

  build() {
    Column() {
      this.buildHeader();
      if (this.isLoading) {
        this.buildLoading();
      } else {
        this.buildMsgList();
      }

      Column() {
        if (this.showEmojiPanel) {
          this.buildEmojiPanel();
        }
        this.buildInputBar();
      }
      .width('100%')
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

        Column() {
          Text(this.userName)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF');

          Row() {
            Row()
              .width(6)
              .height(6)
              .backgroundColor(this.isOnline ? '#4CAF50' : this.COLOR_TEXT_TERTIARY)
              .borderRadius(3)
              .margin({ right: 4 });

            Text(this.isOnline ? '在线' : '离线')
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.8)');
          }
          .margin({ top: 2 });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);

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
  buildLoading() {
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
  }

  @Builder
  buildMsgList() {
    List({ scroller: this.listScroller }) {
      ForEach(this.messages, (msg: Message, index: number) => {
        ListItem() {
          Column() {
            if (index === 0 || this.shouldShowDateDivider(msg, this.messages[index - 1])) {
              this.buildDateDivider(msg.createdAt);
            }
            if (msg.isSent) {
              this.buildRightBubble(msg);
            } else {
              this.buildLeftBubble(msg);
            }
          }
        }
      }, (msg: Message) => msg.id);
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(this.COLOR_BG)
    .alignListItem(ListItemAlign.Start);
  }

  @Builder
  buildDateDivider(timestamp: string) {
    Row() {
      Text(this.formatDate(timestamp))
        .fontSize(11)
        .fontColor(this.COLOR_TEXT_TERTIARY)
        .backgroundColor('rgba(0,0,0,0.05)')
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .borderRadius(10);
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 8 });
  }

  @Builder
  buildLeftBubble(msg: Message) {
    Row() {
      AvatarComponent({
        user: {
          avatar: this.userAvatar,
          name: this.userName
        },
        avatarSize: 40
      })
        .margin({ right: 10, left: 12 })
        .alignSelf(ItemAlign.Start);

      Column() {
        Text(msg.content)
          .fontSize(15)
          .fontColor(this.COLOR_TEXT_PRIMARY)
          .padding(12)
          .backgroundColor(this.COLOR_CARD)
          .borderRadius({
            topLeft: 4,
            topRight: 16,
            bottomLeft: 16,
            bottomRight: 16
          })
          .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 })
          .constraintSize({ maxWidth: '68%' });

        Text(this.formatTime(msg.createdAt))
          .fontSize(10)
          .fontColor(this.COLOR_TEXT_TERTIARY)
          .margin({ top: 4, left: 4 });
      }
      .alignItems(HorizontalAlign.Start)
      .alignSelf(ItemAlign.Start);

      Blank();
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 });
  }

  @Builder
  buildRightBubble(msg: Message) {
    Row() {
      Blank();

      Column() {
        // 消息气泡
        Text(msg.content)
          .fontSize(15)
          .padding(12)
          .backgroundColor(this.COLOR_PRIMARY)
          .fontColor('#FFFFFF')
          .borderRadius({
            topLeft: 16,
            topRight: 4,
            bottomLeft: 16,
            bottomRight: 16
          })
          .constraintSize({ maxWidth: '68%' });

        // 时间和状态 - 放在气泡下方
        Row() {
          Text(this.formatTime(msg.createdAt))
            .fontSize(10)
            .fontColor(this.COLOR_TEXT_TERTIARY);

          if (msg.status === 'read') {
            Text(' · ' + this.getStatusDisplay(msg.status))
              .fontSize(10)
              .fontColor(this.getStatusColor(msg.status));
          }
        }
        .margin({ top: 4, right: 4 });
      }
      .alignItems(HorizontalAlign.End)
      .alignSelf(ItemAlign.Start);

      Text('我')
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.COLOR_PRIMARY)
        .fontColor('#FFFFFF')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .margin({ left: 10, right: 12 });
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 });
  }

  @Builder
  buildEmojiPanel() {
    Column() {
      Scroll() {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
          ForEach(this.emojis, (emoji: string) => {
            Text(emoji)
              .fontSize(26)
              .width('12.5%')
              .height(44)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.inputText = this.inputText + emoji;
              });
          });
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      }
      .width('100%')
      .height(240)
      .scrollBar(BarState.Auto)
      .backgroundColor(this.COLOR_CARD);

      Divider()
        .color(this.COLOR_DIVIDER)
        .strokeWidth(0.5);
    }
    .width('100%');
  }

  @Builder
  buildInputBar() {
    Row() {
      Button('😀')
        .fontSize(18)
        .backgroundColor(Color.Transparent)
        .width(44)
        .height(44)
        .padding(0)
        .onClick(() => {
          this.showEmojiPanel = !this.showEmojiPanel;
        });

      TextInput({ placeholder: '输入消息...', text: this.inputText })
        .placeholderColor(this.COLOR_TEXT_TERTIARY)
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((val: string) => {
          this.inputText = val;
        })
        .onFocus(() => {
          this.showEmojiPanel = false;
        });

      Button('发送')
        .width(64)
        .height(36)
        .margin({ left: 8 })
        .backgroundColor(this.inputText.trim() ? this.COLOR_PRIMARY : '#CCCCCC')
        .fontColor('#FFFFFF')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .borderRadius(18)
        .enabled(this.inputText.trim().length > 0)
        .onClick(() => {
          this.sendMessage();
        });
    }
    .width('100%')
    .padding({ left: 8, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.COLOR_CARD);
  }
}
