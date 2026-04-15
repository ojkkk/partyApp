import { StudyResource, StudyService, ResourceProgress } from "../models/StudyModel";

import { ApiResponse } from "../models/UserModel";
import router from "@ohos.router";
import promptAction from "@ohos.promptAction";

interface ShareWant {
  action: string;
  type: string;
  parameters: Record<string, string>;
}

interface ShareContext {
  startAbility?(want: ShareWant): void;
}

interface ComponentWithContext {
  context?: ShareContext;
}

// ─────────────────────────────────────────────────────────────────────────────
// 设计规范（庄重红金正式风）
//  主色        #B51F2E  绛红
//  强调色      #D83A34  亮红
//  金色        #C9A45C  暖金
//  深金        #A67C2E  深金
//  背景        #F7F4EF  米白底
//  卡片背景    #FFFFFF  纯白
//  文字主色    #1F1F1F  深灰黑
//  文字副色    #666666  中灰
//  文字弱色    #999999  浅灰
//  分割线      #EFE7DB  暖灰金
// ─────────────────────────────────────────────────────────────────────────────

@Entry
@Component
struct StudyDetailPage {
  private studyService: StudyService = new StudyService();
  @State resource: StudyResource | null = null;
  private resourceId: string = "";
  @State currentProgress: number = 0;
  @State isLoading: boolean = false;
  @State studyDuration: number = 0;
  @State initialStudyDuration: number = 0;
  @State totalStudyDuration: number = 0;
  private timer: number | null = null;
  @State isShowShareDialog: boolean = false;
  @State isFavorite: boolean = false;

  async aboutToAppear() {
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params["resourceId"]) {
      this.resourceId = params["resourceId"];
      await this.loadResourceDetail();
      this.startTimer();
    }
  }

  aboutToDisappear() {
    this.stopTimer();
    this.updateProgress();
  }

  startTimer() {
    let seconds = 0;
    this.timer = setInterval(() => {
      this.studyDuration++;
      seconds++;
      if (seconds % 60 === 0) {
        this.updateLocalProgress();
      }
    }, 1000);
  }

  stopTimer() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async loadResourceDetail() {
    this.isLoading = true;
    try {
      const response: ApiResponse<StudyResource> = await this.studyService.getResourceDetail(this.resourceId);
      if (response.code === 200 && response.data) {
        this.resource = response.data;
        await this.loadResourceProgress();
        await this.checkFavoriteStatus();
      }
    } catch (error) {
      console.error("加载学习资源失败:", error);
      promptAction.showToast({
        message: "加载失败",
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async checkFavoriteStatus() {
    try {
      const favoritesResponse = await this.studyService.getFavorites();
      if (favoritesResponse.code === 200 && favoritesResponse.data) {
        this.isFavorite = favoritesResponse.data.some(resource => resource.id === this.resourceId);
      }
    } catch (error) {
      console.error("检查收藏状态失败:", error);
    }
  }

  async loadResourceProgress() {
    try {
      const response = await this.studyService.getResourceProgress(this.resourceId);
      if (response.code === 200 && response.data) {
        this.studyDuration = response.data.studyDuration;
        this.initialStudyDuration = response.data.studyDuration;
        this.currentProgress = response.data.progress;
      }
    } catch (error) {
      console.error("加载学习进度失败:", error);
    }
  }

  updateLocalProgress() {
    if (this.resource) {
      const expectedDuration = this.resource.duration * 60;
      if (expectedDuration > 0) {
        this.currentProgress = Math.min(100, Math.floor((this.studyDuration / expectedDuration) * 100));
      }
    }
  }

  async updateProgress() {
    try {
      this.updateLocalProgress();
      const sessionDuration = this.studyDuration - this.initialStudyDuration;
      await this.studyService.updateProgress(this.resourceId, this.currentProgress, sessionDuration > 0 ? sessionDuration : 0);
    } catch (error) {
      console.error("更新进度失败:", error);
    }
  }

  async toggleFavorite() {
    try {
      const response = await this.studyService.toggleFavorite(this.resourceId);
      if (response.code === 200) {
        this.isFavorite = response.data || false;
        promptAction.showToast({
          message: this.isFavorite ? "已收藏" : "已取消收藏",
          duration: 2000
        });
      }
    } catch (error) {
      console.error("收藏失败:", error);
      promptAction.showToast({
        message: "操作失败",
        duration: 2000
      });
    }
  }

  async shareResource() {
    try {
      if (!this.resource) return;

      const component = this as ComponentWithContext;
      const ctx = component.context;

      if (ctx && ctx.startAbility) {
        const shareText = `${this.resource.title}\n${this.resource.content.substring(0, 100)}...\n链接：https://partyapp.example.com/study/${this.resource.id}`;
        const want: ShareWant = {
          action: "ohos.intent.action.SEND",
          type: "text/plain",
          parameters: {
            "ohos.extra.text": shareText
          }
        };
        ctx.startAbility(want);
      } else {
        this.isShowShareDialog = true;
      }

    } catch (error) {
      this.isShowShareDialog = true;
    }
  }

  build() {
    Column() {
      // ===================== 【封面大图 + 渐变遮罩】 =====================
      Stack({ alignContent: Alignment.TopStart }) {
        // 封面图
        if (this.resource?.imageUrl) {
          Image(this.resource.imageUrl)
            .width('100%')
            .height(280)
            .objectFit(ImageFit.Contain);
        } else {
          Column()
            .width('100%')
            .height(280)
            .backgroundColor('#F7F4EF');
        }

        // 渐变遮罩
        Column()
          .width('100%')
          .height(280)
          .linearGradient({
            angle: 180,
            colors: [['#00000000', 0.0], ['#00000030', 0.5], ['#00000060', 1.0]]
          });

        // 返回/收藏/分享按钮浮层
        Row() {
          Text('‹')
            .fontSize(32)
            .fontColor('#FFFFFF')
            .margin({ bottom: 6 })
            .onClick(() => router.back());

          Blank();

          Row() {
            Image(this.isFavorite ? $rawfile('已收藏.png') : $rawfile('未收藏.png'))
              .width(22)
              .height(22)
              .onClick(() => this.toggleFavorite());

            Image($rawfile('分享.png'))
              .width(24)
              .height(24)
              .margin({ left: 20 })
              .onClick(() => this.shareResource());
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .position({ x: 0, y: 0 });

        // 底部标题区域
        Column() {
          // 类型标签
          Text(this.resource?.type || '视频')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#B51F2E')
            .borderRadius({ topLeft: 12, bottomRight: 12 })
            .margin({ bottom: 12 });

          // 标题
          Text(this.resource?.title || '')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 20 })
        .alignItems(HorizontalAlign.Start)
        .position({ x: 0, y: '100%' })
        .markAnchor({ x: 0, y: '100%' });
      }
      .width('100%')
      .height(280);

      // ===================== 【内容滚动区】 =====================
      Scroll() {
        Column() {
          // 学习信息卡片
          this.InfoCard()

          // 学习内容卡片
          this.ContentCard()

          // 视频学习卡片
          if (this.resource?.videoUrl) {
            this.VideoCard();
          }

          // 底部留白
          Blank().height(80);
        }
        .padding({ top: 12, bottom: 12 });
      }
      .layoutWeight(1)
      .backgroundColor('#F7F4EF');

      // ===================== 【底部进度条】 =====================
      Column() {
        Row() {
          Text('学习进度 ')
            .fontSize(14)
            .fontColor('#666666')
            .fontWeight(FontWeight.Medium);

          Text(`${this.currentProgress}%`)
            .fontSize(14)
            .fontColor('#B51F2E')
            .fontWeight(FontWeight.Bold)
            .margin({ left: 'auto' });
        }
        .width('100%')
        .margin({ bottom: 8 });

        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width('100%')
            .height(6)
            .backgroundColor('#EFE7DB')
            .borderRadius(3);

          Row()
            .width(`${this.currentProgress}%`)
            .height(6)
            .backgroundColor('#B51F2E')
            .borderRadius(3);
        }
        .width('100%')
        .height(6);

        Row() {
          Text(`预计: ${this.resource?.duration || 0}分钟`)
            .fontSize(12)
            .fontColor('#999999');

          Text(`已学: ${Math.floor(this.studyDuration / 60)}分钟`)
            .fontSize(12)
            .fontColor('#B51F2E')
            .margin({ left: 'auto' });
        }
        .width('100%')
        .margin({ top: 8 });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor('#FFFFFF')
      .borderWidth({ top: 1 })
      .borderColor({ top: '#EFE7DB' });

      // ===================== 【模拟分享面板】 =====================
      if (this.isShowShareDialog) {
        Stack() {
          // 半透明背景
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#00000050')
            .onClick(() => this.isShowShareDialog = false);

          // 分享面板
          Column() {
            Text('分享到')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F1F1F')
              .margin({ bottom: 24 });

            Row() {
              this.ShareOption('微信', '#07C160');
              this.ShareOption('QQ', '#12B7F5');
              this.ShareOption('朋友圈', '#07C160');
            }
            .margin({ bottom: 30 });

            Button('取消')
              .width('80%')
              .height(44)
              .fontSize(15)
              .fontColor('#666666')
              .backgroundColor('#F7F4EF')
              .borderRadius(22)
              .onClick(() => this.isShowShareDialog = false);
          }
          .width('85%')
          .padding({ top: 24, bottom: 24 })
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .position({ x: '7.5%', y: '35%' });
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(999);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }

  // ===================== 【学习信息卡片 Builder】 =====================
  @Builder
  InfoCard() {
    Column() {
      Row() {
        Row() {
          Row()
            .width(4)
            .height(18)
            .borderRadius(2)
            .backgroundColor('#B51F2E')
            .margin({ right: 10 });
          Text('学习信息')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F');
        }

        Blank();

        Text(this.resource?.type || '')
          .fontSize(12)
          .fontColor('#B51F2E')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#FFF1F1')
          .borderRadius(12);
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Column() {
          Text('预计时长')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ bottom: 4 });
          Text(`${this.resource?.duration || 0}分钟`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F1F1F');
        }
        .layoutWeight(1);

        Column() {
          Text('已学时长')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ bottom: 4 });
          Text(`${Math.floor(this.studyDuration / 60)}分钟`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#B51F2E');
        }
        .layoutWeight(1);

        Column() {
          Text('学习进度')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ bottom: 4 });
          Text(`${this.currentProgress}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#B51F2E');
        }
        .layoutWeight(1);
      }
      .width('100%');
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }

  // ===================== 【学习内容卡片 Builder】 =====================
  @Builder
  ContentCard() {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(18)
          .borderRadius(2)
          .backgroundColor('#B51F2E')
          .margin({ right: 10 });
        Text('学习内容')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F');
      }
      .width('100%')
      .margin({ bottom: 14 });

      Text(this.resource?.content || '暂无内容')
        .fontSize(15)
        .lineHeight(24)
        .fontColor('#666666')
        .width('100%');
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }

  // ===================== 【视频学习卡片 Builder】 =====================
  @Builder
  VideoCard() {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(18)
          .borderRadius(2)
          .backgroundColor('#B51F2E')
          .margin({ right: 10 });
        Text('视频学习')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F');
      }
      .width('100%')
      .margin({ bottom: 14 });

      Video({
        src: this.resource?.videoUrl || '',
        previewUri: this.resource?.imageUrl
      })
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Cover)
        .controls(true)
        .autoPlay(false)
        .borderRadius(12);
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .margin({ left: 12, right: 12, bottom: 12 });
  }

  // ===================== 【分享选项 Builder】 =====================
  @Builder
  ShareOption(platform: string, bgColor: string) {
    Column() {
      Column()
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(bgColor)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

      Text(platform)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 8 });
    }
    .width(70)
    .onClick(() => {
      this.isShowShareDialog = false;
      promptAction.showToast({ message: `已模拟分享到${platform}` });
    });
  }
}