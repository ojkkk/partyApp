import router from '@ohos.router';
import { UserService, ApiResponse, LoginLog } from '../models/UserModel';
import promptAction from '@ohos.promptAction';

// ─────────────────────────────────────────────────────────────────────────────
// 设计规范（庄重红金正式风）
//  主色        #B51F2E  绛红
//  强调色      #D83A34  亮红
//  金色        #C9A45C  暖金
//  背景        #F7F4EF  米白底
//  卡片背景    #FFFFFF  纯白
//  文字主色    #1F1F1F  深灰黑
//  文字副色    #666666  中灰
//  文字弱色    #999999  浅灰
//  分割线      #EFE7DB  暖灰金
// ─────────────────────────────────────────────────────────────────────────────

@Entry
@Component
export struct LoginLogsPage {
  @State logs: LoginLog[] = [];
  @State isLoading: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadLoginLogs();
  }

  async loadLoginLogs(): Promise<void> {
    this.isLoading = true;
    try {
      const userService = new UserService();
      const response: ApiResponse<LoginLog[]> = await userService.getLoginLogs();
      if (response.code === 200 && response.data) {
        this.logs = response.data;
      }
    } catch (error) {
      console.error('获取登录日志失败:', error);
      promptAction.showToast({
        message: '获取登录日志失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  // 日志卡片构建器
  @Builder
  LogCard(log: LoginLog, isLast: boolean): void {
    Column() {
      // 登录时间
      Row() {
        Text('登录时间')
          .fontSize(14)
          .fontColor('#666666');
        Text(log.loginTime)
          .fontSize(14)
          .fontColor('#1F1F1F')
          .fontWeight(FontWeight.Medium);
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 });

      // 设备信息
      Row() {
        Text('登录设备')
          .fontSize(14)
          .fontColor('#666666');
        Text(log.device)
          .fontSize(14)
          .fontColor('#1F1F1F')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 });

      // 登录地点
      Row() {
        Text('登录地点')
          .fontSize(14)
          .fontColor('#666666');
        Text(log.location || '未知')
          .fontSize(14)
          .fontColor('#1F1F1F')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ left: 16, right: 16, bottom: 12 });
  }

  // 空状态构建器
  @Builder
  EmptyState(): void {
    Column() {
      Image($rawfile('统计.png'))
        .width(80)
        .height(80)
        .opacity(0.3)
        .margin({ bottom: 16 });
      Text('暂无登录记录')
        .fontSize(16)
        .fontColor('#999999');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  build(): void {
    Column() {
      // ==================== 顶部导航栏 ====================
      Row() {
        Button() {
          Image($rawfile('返回.png'))
            .width(24)
            .height(24);
        }
        .backgroundColor('transparent')
        .onClick((): void => {
          router.back();
        });

        Text('登录日志')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Text('').width(24);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 });

      // ==================== 日志列表 ====================
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666');
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center);
      } else if (this.logs.length === 0) {
        this.EmptyState();
      } else {
        Scroll() {
          Column() {
            // 统计信息
            Row() {
              Text(`共 ${this.logs.length} 条记录`)
                .fontSize(13)
                .fontColor('#999999');
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 8 });

            // 日志卡片列表
            ForEach(this.logs, (log: LoginLog, index: number) => {
              this.LogCard(log, index === this.logs.length - 1);
            }, (log: LoginLog) => log.loginTime + log.device);
          }
          .width('100%')
          .padding({ bottom: 20 });
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }
}