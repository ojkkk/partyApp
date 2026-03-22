import { ChatSession, ChatService } from '../models/ChatModel';
import { Message as UserMessage } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';
// 标准党旗红主色，符合党建应用规范
const PRIMARY_COLOR: string = '#C8102E';
const BG_COLOR: string = '#F5F7FA';
const CARD_BG: string = '#FFFFFF';
const TEXT_MAIN: string = '#181818';
const TEXT_SECOND: string = '#666666';
const TEXT_GRAY: string = '#999999';
// 定义底部导航栏高度
const NAV_BAR_HEIGHT: number = 64;

@Entry
@Component
export struct ChatListPage {
  @State sessions: ChatSession[] = [];
  @State isLoading: boolean = true;

  private chatService: ChatService = new ChatService();

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

  // 格式化时间
  formatTime(timestamp: string): string {
    const now = Date.now();
    const timestampMs = new Date(timestamp).getTime();
    const diff = now - timestampMs;

    if (diff < 60000) { // 1分钟内
      return '刚刚';
    } else if (diff < 3600000) { // 1小时内
      return `${Math.floor(diff / 60000)}分钟前`;
    } else if (diff < 86400000) { // 24小时内
      return `${Math.floor(diff / 3600000)}小时前`;
    } else {
      const date = new Date(timestamp);
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    }
  }

  // 聊天会话卡片
  @Builder
  ChatSessionCard(session: ChatSession) {
    Row() {
      // 头像
      if (session.userAvatar) {
        Image(session.userAvatar)
          .width(56)
          .height(56)
          .borderRadius(28)
          .objectFit(ImageFit.Cover)
      } else {
        Text(session.userName.charAt(0))
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor(PRIMARY_COLOR)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
      }

      // 会话信息
      Column() {
        Row() {
          Text(session.userName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_MAIN)
          Blank()
          Text(this.formatTime(session.lastMessage.createdAt))
            .fontSize(12)
            .fontColor(TEXT_GRAY)
        }
        .width('100%')
        .margin({ top: 4 })

        Row() {
          Text(session.lastMessage.content)
            .fontSize(14)
            .fontColor(session.unreadCount > 0 ? PRIMARY_COLOR : TEXT_SECOND)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (session.unreadCount > 0) {
            Text(session.unreadCount.toString())
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor(PRIMARY_COLOR)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(10)
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(CARD_BG)
    .onClick(async () => {
      // 标记为已读
      await this.chatService.markSessionAsRead(session.id);
      // 跳转到聊天详情页
      await router.pushUrl({
        url: 'pages/ChatPage',
        params: {
          userId: session.userId,
          userName: session.userName,
          userAvatar: session.userAvatar
        }
      });
    })
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=back%20icon%20black&image_size=square')
            .width(24)
            .height(24)
        }
        .width(44)
        .height(44)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
          emitter.emit("refreshUnread", null);
        })

        Text('消息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)

        Blank()
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16 })
      .backgroundColor(CARD_BG)
      .shadow({
        radius: 4,
        color: '#0A000000',
        offsetX: 0,
        offsetY: 1
      })

      // 聊天列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(PRIMARY_COLOR)
          Text('正在加载消息...')
            .fontSize(14)
            .fontColor(TEXT_GRAY)
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        if (this.sessions.length === 0) {
          Column() {
            Text('💬')
              .fontSize(48)
              .margin({ bottom: 16 })
            Text('暂无消息')
              .fontSize(16)
              .fontColor(TEXT_SECOND)
            Text('开始与其他党员同志交流吧')
              .fontSize(14)
              .fontColor(TEXT_GRAY)
              .margin({ top: 4 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.sessions, (session: ChatSession) => {
              ListItem() {
                this.ChatSessionCard(session)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(BG_COLOR)
          .divider({
            strokeWidth: 1,
            color: '#F0F0F0',
            startMargin: 84,
            endMargin: 16
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_COLOR)
  }
}