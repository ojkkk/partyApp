import { ChatSession, ChatService } from '../models/ChatModel';
import { Message as UserMessage } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';
import { AvatarComponent } from '../components/AvatarComponent';

@Entry
@Component
export struct ChatListPage {
  @State sessions: ChatSession[] = [];
  @State isLoading: boolean = true;

  private chatService: ChatService = new ChatService();

  // ===================== 颜色配置 - 庄重红金正式风 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';      // 绛红
  private readonly COLOR_PRIMARY_LIGHT = '#D83A34'; // 亮红
  private readonly COLOR_GOLD = '#C9A45C';         // 暖金
  private readonly COLOR_BG = '#F7F4EF';           // 米白背景
  private readonly COLOR_CARD = '#FFFFFF';         // 卡片白
  private readonly COLOR_TEXT_PRIMARY = '#1F1F1F'; // 主文字
  private readonly COLOR_TEXT_SECONDARY = '#666666'; // 次要文字
  private readonly COLOR_TEXT_TERTIARY = '#999999';  // 辅助文字
  private readonly COLOR_BORDER = '#EFE7DB';       // 金色边框
  private readonly COLOR_DIVIDER = '#F0EBE3';      // 分割线

  async aboutToAppear() {
    await this.loadSessions();
  }

  async onPageShow() {
    await this.loadSessions();
  }

  async loadSessions() {
    this.isLoading = true;
    try {
      const response = await this.chatService.getSessions();
      if (response.code === 200 && response.data) {
        this.sessions = response.data;
      }
    } catch (error) {
      console.error('加载聊天会话失败:', error);
      promptAction.showToast({
        message: '加载聊天会话失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  formatTime(timestamp: string): string {
    const now = Date.now();
    const timestampMs = new Date(timestamp).getTime();
    const diff = now - timestampMs;

    if (diff < 60000) {
      return '刚刚';
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`;
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`;
    } else {
      const date = new Date(timestamp);
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    }
  }

  @Builder
  ChatSessionCard(session: ChatSession) {
    Row() {
      // 头像
      AvatarComponent({
        user: {
          avatar: session.userAvatar,
          name: session.userName
        },
        avatarSize: 52
      })

      // 会话信息
      Column() {
        Row() {
          Text(session.userName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .layoutWeight(1);

          Text(this.formatTime(session.lastMessage.createdAt))
            .fontSize(12)
            .fontColor(this.COLOR_TEXT_TERTIARY);
        }
        .width('100%')
        .margin({ top: 2 });

        Row() {
          Text(session.lastMessage.content)
            .fontSize(14)
            .fontColor(session.unreadCount > 0 ? this.COLOR_PRIMARY : this.COLOR_TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1);

          if (session.unreadCount > 0) {
            Text(session.unreadCount > 99 ? '99+' : session.unreadCount.toString())
              .fontSize(11)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.COLOR_PRIMARY)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(10)
              .margin({ left: 8 });
          }
        }
        .width('100%')
        .margin({ top: 6 });
      }
      .layoutWeight(1)
      .margin({ left: 12 });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.COLOR_CARD)
    .onClick(async () => {
      await this.chatService.markSessionAsRead(session.id);
      await router.pushUrl({
        url: 'pages/ChatPage',
        params: {
          userId: session.userId,
          userName: session.userName,
          userAvatar: session.userAvatar
        }
      });
    });
  }

  @Builder
  EmptyView() {
    Column() {
      // 金色装饰圆环
      Row() {
        Text('💬')
          .fontSize(40);
      }
      .width(80)
      .height(80)
      .backgroundColor('#FDF9F3')
      .borderRadius(40)
      .border({ width: 2, color: this.COLOR_BORDER })
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 });

      Text('暂无消息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.COLOR_TEXT_SECONDARY);

      Text('开始与其他党员同志交流吧')
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_TERTIARY)
        .margin({ top: 8 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.COLOR_BG);
  }

  build() {
    Column() {
      // 顶部导航栏 - 绛红渐变背景
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
                emitter.emit("refreshUnread", null);
              });
          }
          .width(56)
          .height('100%')
          .justifyContent(FlexAlign.Center);

          Text('消息')
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

      // 聊天列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.COLOR_PRIMARY);

          Text('正在加载消息...')
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_TERTIARY)
            .margin({ top: 12 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.COLOR_BG);
      } else {
        if (this.sessions.length === 0) {
          this.EmptyView();
        } else {
          List() {
            ForEach(this.sessions, (session: ChatSession) => {
              ListItem() {
                this.ChatSessionCard(session);
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(this.COLOR_BG)
          .divider({
            strokeWidth: 0.5,
            color: this.COLOR_DIVIDER,
            startMargin: 80,
            endMargin: 16
          });
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.COLOR_BG);
  }
}
