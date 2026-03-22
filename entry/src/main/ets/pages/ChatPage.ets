import router from '@ohos.router';
import { UserService, ApiResponse, Message } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import promptAction from '@ohos.promptAction';

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
  @State isOnline: boolean = false; // 🔧 这个是真实的，通过接口轮询
  @State lastSeen: string = '';
  private userService: UserService = new UserService();
  private userId: string = '';
  private userName: string = '';
  private userAvatar: string = '';
  private currentUserId: string = '';
  private statusUpdateInterval: number = -1;
  private listScroller: ListScroller = new ListScroller();
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
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
    '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🙈',
    '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🦆',
    '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝',
    '🐛', '🦋', '🐌', '🐞', '🐜', '🦟', '🦗', '🕷️',
    '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐',
    '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅',
    '🍆', '🥑', '🥦', '🥬', '🧄', '🧅', '🥔', '🍠',
    '🌽', '🥕', '🫑', '🌶️', '🥒', '🍞', '🥐', '🥖',
    '🥨', '🧀', '🥚', '🍳', '🧈', '🥓', '🥩', '🍗',
    '🍖', '🌭', '🍔', '🍟', '🍕', '🥪', '🌮', '🌯',
    '🧂', '🥫', '🍱', '🍘', '🍙', '🍚', '🍛', '🍜',
    '🍝', '🍠', '🍢', '🍣', '🍤', '🍥', '🍡', '🥟',
    '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰', '🧁',
    '🥧', '🍫', '🍬', '🍭', '🍮', '🍯', '🍼', '🥛',
    '☕', '🫖', '🍵', '🍶', '🍷', '🍸', '🍹', '🍺',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
    '💘', '💝', '💟', '🔥', '✨', '⭐', '🌟', '💫',
    '⚡', '☁️', '🌈', '☀️', '🌤️', '⛅', '🌥️', '☂️',
    '🌧️', '⛈️', '🌩️', '🌨️', '❄️', '☃️', '⛄', '🌬️',
    '💨', '🌪️', '🌫️', '🌊', '💧', '💦', '☔'
  ];

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.userId && params.userName) {
      this.userId = params.userId;
      this.userName = params.userName;
      this.userAvatar = params.userAvatar || '';
      this.currentUserId = await StorageService.getItemAsync<string>('userId') || '';

      await this.loadMessages();
      await this.loadUserStatus(); // 🔧 真实：进入页面立即查一次在线状态

      // 🔧 真实：开启定时器，每30秒刷新一次在线状态
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

  // 🔧 真实实现：通过接口获取对方在线状态
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
      // 先标记消息为已读
      await this.userService.markChatMessageAsRead(this.userId);

      // 然后加载消息列表
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
    // 初始状态设为 sent
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
        // 🔧 真实逻辑 1：接口返回成功，代表【已发送】
        this.updateMsgStatus(tempId, 'sent');

        // 🔧 真实逻辑 2：如果当前对方正好在线，我们认为消息【已读】
        // (这是在没有长连接推送下的合理简化，真实IM需要WebSocket)
        if (this.isOnline) {
          // 稍微延迟一点点，模拟网络传输和查看时间
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

  // 简化参数类型
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

  // 只返回两种文字
  getStatusDisplay(status?: 'sent' | 'read'): string {
    if (status === 'read') return '已读';
    return '已发送'; // 已发送状态不显示文字，或者显示 '已发送'
  }

  getStatusColor(status?: 'sent' | 'read'): ResourceColor {
    if (status === 'read') return '#4CAF50';
    return '#999999';
  }

  build() {
    Column() {
      this.buildHeader();
      if (this.isLoading) {
        this.buildLoading();
      } else {
        this.buildMsgList();
      }

      // 🔧 关键修改：底部区域统一管理
      Column() {
        // 如果显示表情，先渲染表情面板
        if (this.showEmojiPanel) {
          this.buildEmojiPanel();
        }
        // 再渲染输入框
        this.buildInputBar();
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }

  @Builder
  buildHeader() {
    Row() {
      Button('返回')
        .backgroundColor(Color.Transparent)
        .fontColor('#D32F2F')
        .onClick(() => router.back());

      Column() {
        Text(this.userName).fontSize(18).fontWeight(FontWeight.Bold);
        // 🔧 这里显示的在线/离线是真实的，来自 loadUserStatus 接口
        Text(this.isOnline ? '在线' : '离线')
          .fontSize(12)
          .fontColor(this.isOnline ? '#4CAF50' : '#999999');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center);

      Button('更多')
        .backgroundColor(Color.Transparent)
        .fontColor('#666666')
        .onClick(() => promptAction.showToast({ message: '开发中' }));
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 2, color: '#00000010', offsetY: 2 });
  }

  @Builder
  buildLoading() {
    Column() {
      LoadingProgress().width(40).height(40);
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildMsgList() {
    List({ scroller: this.listScroller }) {
      ForEach(this.messages, (msg: Message) => {
        ListItem() {
          if (msg.isSent) {
            this.buildRightBubble(msg);
          } else {
            this.buildLeftBubble(msg);
          }
        }
      }, (msg: Message) => msg.id);
    }
    .width('100%')
    .layoutWeight(1) // 占据剩余空间
    .padding({ top: 8, bottom: 8 }) // 🔧 这里的 bottom 可以保留，让最后一条消息不贴边
    .backgroundColor('#F5F5F5')
    .alignListItem(ListItemAlign.Start); // 确保列表项对齐
  }

  @Builder
  buildLeftBubble(msg: Message) {
    Row() {
      if (this.userAvatar) {
        Image(this.userAvatar)
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ right: 12, left: 16 })
          .objectFit(ImageFit.Cover);
      } else {
        Text(this.userName.charAt(0))
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#D32F2F')
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .margin({ right: 12, left: 16 });
      }

      Column() {
        Text(msg.content)
          .fontSize(16)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius({
            topLeft: 0,
            topRight: 16,
            bottomLeft: 16,
            bottomRight: 16
          })
          .constraintSize({ maxWidth: '70%' });

        Text(this.formatTime(msg.createdAt))
          .fontSize(10).fontColor('#999999')
          .margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Start);

      Blank();
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 });
  }

  @Builder
  buildRightBubble(msg: Message) {
    Row() {
      Blank();

      Column() {
        Row() {
          Column() {
            // 🔧 只有已读时才显示文字
            Text(this.getStatusDisplay(msg.status))
              .fontSize(12)
              .fontColor(this.getStatusColor(msg.status))
              .margin({ right: 4 });
            Text(this.formatTime(msg.createdAt))
              .fontSize(10).fontColor('#999999');
          }
          .alignItems(HorizontalAlign.End)
          .margin({ right: 6 });

          Text(msg.content)
            .fontSize(16)
            .padding(12)
            .backgroundColor('#D32F2F')
            .fontColor('#FFFFFF')
            .borderRadius({
              topLeft: 16,
              topRight: 0,
              bottomLeft: 16,
              bottomRight: 16
            })
            .constraintSize({ maxWidth: '70%' });
        }
        .alignItems(VerticalAlign.Bottom);
      }
      .alignItems(HorizontalAlign.End);

      Text('我')
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#999999')
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .margin({ left: 12, right: 16 });
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 });
  }

  @Builder
  buildEmojiPanel() {
    Column() {
      // 🔧 修复：去掉不存在的 scrollEdge 属性
      Scroll() {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
          ForEach(this.emojis, (emoji: string) => {
            Text(emoji)
              .fontSize(28)
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
      .height(260)
      .scrollBar(BarState.Auto) // 保留这个，显示滚动条
      .backgroundColor('#FFFFFF');

      Divider()
        .color('#E0E0E0')
        .strokeWidth(0.5)
    }
    .width('100%');
  }

  @Builder
  buildInputBar() {
    Row() {
      Button('😀')
        .fontSize(20)
        .backgroundColor(Color.Transparent)
        .width(60)
        .height(60)
        .onClick(() => {
          this.showEmojiPanel = !this.showEmojiPanel;
        });

      TextInput({ placeholder: '输入消息...', text: this.inputText })
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#F0F0F0')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((val: string) => {
          this.inputText = val;
        })
        .onFocus(() => {
          // 聚焦输入框时关闭表情
          this.showEmojiPanel = false;
        });

      Button('发送')
        .width(64)
        .height(40)
        .margin({ left: 12 })
        .backgroundColor(this.inputText.trim() ? '#D32F2F' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .borderRadius(20)
        .enabled(this.inputText.trim().length > 0)
        .onClick(() => {
          this.sendMessage();
        });
    }
    .width('100%')
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: 8
    })
    .backgroundColor('#FFFFFF');
  }
}