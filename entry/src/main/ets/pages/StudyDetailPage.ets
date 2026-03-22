import { StudyResource, StudyService, ResourceProgress } from "../models/StudyModel";
import { ApiResponse } from "../models/UserModel";
import router from "@ohos.router";
import promptAction from "@ohos.promptAction";




// 放在所有 import 下面
// 定义我们需要的上下文类型（彻底避免 any）
// 1. 定义分享参数接口
interface ShareWant {
  action: string;
  type: string;
  parameters: Record<string, string>;
}

// 2. 定义上下文接口
interface ShareContext {
  startAbility?(want: ShareWant): void;
}

// 3. 定义组件接口
interface ComponentWithContext {
  context?: ShareContext;
}


//////
class RouterParams {
  resourceId: string;

  constructor(resourceId: string) {
    this.resourceId = resourceId;
  }
}

@Entry
@Component
struct StudyDetailPage {
  private studyService: StudyService = new StudyService();
  @State resource: StudyResource | null = null;
  private resourceId: string = "";
  @State currentProgress: number = 0;
  @State isLoading: boolean = false;
  @State studyDuration: number = 0; // 当前资源的学习时长（秒）
  @State initialStudyDuration: number = 0; // 初始学习时长（秒）
  @State totalStudyDuration: number = 0; // 总学习时长（秒）
  private timer: number | null = null;
  @State isShowShareDialog: boolean = false; // 控制模拟分享面板显示

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
    this.timer = setInterval(() => {
      this.studyDuration++;
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

  async updateProgress() {
    try {
      // 计算当前资源的学习进度，基于学习时长和预计时长
      if (this.resource) {
        const expectedDuration = this.resource.duration * 60; // 转换为秒
        if (expectedDuration > 0) {
          this.currentProgress = Math.min(100, Math.floor((this.studyDuration / expectedDuration) * 100));
        }
      }
      // 发送本次学习的时长增量，而不是累计时长
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
        promptAction.showToast({
          message: response.data ? "已收藏" : "已取消收藏",
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




  /*async shareResource() {
    try {
      if (!this.resource) {
        promptAction.showToast({ message: "资源未加载" });
        return;
      }

      // 1. 先弹个提示，证明按钮点击了
      promptAction.showToast({ message: "分享按钮已点击，正在启动..." });

      const component = this as ComponentWithContext;
      const ctx = component.context;

      // 2. 检查上下文是否存在
      if (!ctx) {
        promptAction.showToast({ message: "未获取到上下文（模拟器环境限制）" });
        return;
      }

      if (!ctx.startAbility) {
        promptAction.showToast({ message: "当前环境不支持系统分享（请用真机测试）" });
        return;
      }

      const shareText = `${this.resource.title}\n${this.resource.content.substring(0, 100)}...\n链接：https://partyapp.example.com/study/${this.resource.id}`;

      const want: ShareWant = {
        action: "ohos.intent.action.SEND",
        type: "text/plain",
        parameters: {
          "ohos.extra.text": shareText
        }
      };

      // 3. 调用分享
      ctx.startAbility(want);
      promptAction.showToast({ message: "系统分享已调用（真机可见面板）" });

    } catch (error) {
      console.error("分享错误:", error);
      promptAction.showToast({ message: "分享出错: " + JSON.stringify(error) });
    }
  }*/
  async shareResource() {
    try {
      if (!this.resource) return;

      const component = this as ComponentWithContext;
      const ctx = component.context;

      // 智能判断：有上下文且有 startAbility → 用真分享（真机）
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
        // 没有上下文 → 显示模拟分享面板（模拟器）
        this.isShowShareDialog = true;
      }

    } catch (error) {
      this.isShowShareDialog = true;
    }
  }
  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .width("100%")
        .height("100%")
        .justifyContent(1)
      } else if (!this.resource) {
        Column() {
          Text("加载失败")
            .fontSize(16)
            .fontColor("#666666")
        }
        .width("100%")
        .height("100%")
        .justifyContent(1)
      } else {
        Row() {
          Image($rawfile('返回.png'))
            .width(24)
            .height(24)
            .margin({top:15, left: 16, right: 16 })
            .onClick(() => {
              this.updateProgress();
              router.back();
            })
          Text("学习详情")
            .fontSize(18)
            .fontWeight(700)
            .margin({top:17})
          Row() {
            Image($rawfile("分享.png"))
              .width(24)
              .height(24)
              .margin({ top:15,left:170,right: 16 })
              .onClick(() => {
                this.shareResource();
              })
            Image($rawfile("收藏.png"))
              .width(24)
              .height(24)
              .margin({ top:15,right: 16 })
              .onClick(() => {
                this.toggleFavorite();
              })
          }
        }
        .width("100%")
        .height(56)
        .alignItems(1)
        .backgroundColor("#FFFFFF")
        .borderWidth({ bottom: 1 })
        .borderColor({ bottom: "#EEEEEE" })

        Scroll() {
          Column() {
            // 图片在最上方
            if (this.resource.imageUrl) {
              Image(this.resource.imageUrl)
                .width("100%")
                .height(200)
                .objectFit(3)
                .margin({ bottom: 20 })
            }

            // 标题
            Text(this.resource.title)
              .fontSize(22)
              .fontWeight(700)
              .fontColor("#333333")
              .margin({ left: 16, right: 16, bottom: 12 })
              .textOverflow({ overflow: TextOverflow.Clip })
              .maxLines(3)

            // 学习信息
            Row() {
              Text(`预计时长: ${this.resource.duration}分钟`)
                .fontSize(14)
                .fontColor("#999999")
              Text(`已学习: ${Math.floor(this.studyDuration / 60)}分钟`)
                .fontSize(14)
                .fontColor("#D32F2F")
                .margin({ left: 24 })
            }
            .width("100%")
            .margin({ left: 16, right: 16, bottom: 24 })

            // 内容标题
            Text("学习内容")
              .fontSize(18)
              .fontWeight(700)
              .fontColor("#333333")
              .margin({ left: 16, right: 16, bottom: 16 })

            // 内容（文章）
            Text(this.resource.content)
              .fontSize(16)
              .lineHeight(24)
              .fontColor("#333333")
              .margin({ left: 16, right: 16, bottom: 32 })
              .textOverflow({ overflow: TextOverflow.Clip })

            // 视频在最后
            if (this.resource.videoUrl) {
              Column() {
                Text("视频学习")
                  .fontSize(18)
                  .fontWeight(700)
                  .fontColor("#333333")
                  .margin({ left: 16, right: 16, bottom: 16 })
                Video({
                  src: this.resource.videoUrl,
                  currentProgressRate: 1.0,
                  previewUri: this.resource.imageUrl
                })
                  .width("100%")
                  .height(200)
                  .objectFit(3)
                  .margin({ left: 16, right: 16, bottom: 40 })
                  .controls(true)
                  .autoPlay(false)
                  .muted(false)
              }
            }
          }
        }
        .flexGrow(1)
        .backgroundColor("#F5F5F5")

        // 底部进度条
        Column() {
          Row() {
            Text("学习进度 ")
              .fontSize(14)
              .fontColor("#333333")
              .fontWeight(500)
            Text(`${this.currentProgress}%`) 
              .fontSize(14)
              .fontColor("#D32F2F")
              .fontWeight(500)
              .margin({ left: "auto" })
          }
          .width("100%")
          .margin({ bottom: 0 })
          .padding({ left: 16, right: 16 })

          Slider({
            value: this.currentProgress,
            min: 0,
            max: 100,
            step: 1
          })
          .width("100%")
          .height(30)
          .blockColor("#D32F2F")
          .trackColor("#F5F5F5")
          .selectedColor("#D32F2F")
          .enabled(false) // 禁用拖动功能
        }
        .width("100%")
        .backgroundColor("#FFFFFF")
        .borderWidth({ top: 1 })
        .borderColor({ top: "#EEEEEE" })
        .padding({ top: 10, bottom: 10 })
        .height(40)


      }
      // 👇 模拟分享面板（模拟器专用）
      if (this.isShowShareDialog) {
        Column() {
          // 半透明背景
          Column()
            .width("100%")
            .height("100%")
            .backgroundColor("rgba(0,0,0,0.5)")
            .onClick(() => {
              this.isShowShareDialog = false;
            })

          // 分享面板内容
          Column() {
            Text("分享到")
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20, top: 20 })

            Row() {
              // 微信
              Column() {
                Text("微信")
                  .fontSize(14)
                  .margin({ top: 8 })
              }
              .width(80)
              .onClick(() => {
                this.isShowShareDialog = false;
                promptAction.showToast({ message: "已模拟分享到微信" });
              })

              // QQ
              Column() {
                Text("QQ")
                  .fontSize(14)
                  .margin({ top: 8 })
              }
              .width(80)
              .margin({ left: 30 })
              .onClick(() => {
                this.isShowShareDialog = false;
                promptAction.showToast({ message: "已模拟分享到QQ" });
              })

              // 朋友圈
              Column() {
                Text("朋友圈")
                  .fontSize(14)
                  .margin({ top: 8 })
              }
              .width(80)
              .margin({ left: 30 })
              .onClick(() => {
                this.isShowShareDialog = false;
                promptAction.showToast({ message: "已模拟分享到朋友圈" });
              })
            }
            .justifyContent(FlexAlign.Center)
            .margin({ bottom: 30 })

            // 取消按钮
            Button("取消")
              .width("80%")
              .height(40)
              .backgroundColor("#F5F5F5")
              .fontColor("#333333")
              .onClick(() => {
                this.isShowShareDialog = false;
              })
          }
          .width("90%")
          .borderRadius(12)
          .backgroundColor("#FFFFFF")
          .position({ x: "5%", y: "30%" })
        }
        .width("100%")
        .height("100%")
        .position({ x: 0, y: 0 })
        .zIndex(999)
      }
    }
    .height("100%")

  }
}
