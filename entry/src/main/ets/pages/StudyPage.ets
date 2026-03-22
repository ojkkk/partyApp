import { StudyResource, StudyService, StudyStats, ResourceProgress } from '../models/StudyModel';
import { ApiResponse } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct StudyPage {
  @State selectedTab: string = '党史学习';
  private tabs = ['党史学习', '专题学习', '我的收藏'];
  private studyService: StudyService = new StudyService();
  @State resources: StudyResource[] = [];
  @State studyStats: StudyStats | null = null;
  @State isLoading: boolean = false;
  @State isAdmin: boolean = false;
  @State resourceProgresses: Map<string, ResourceProgress> = new Map();
  private updateTimer: number | null = null;

  async aboutToAppear() {
    await this.checkUserRole();
    await this.loadStats();
    await this.loadResources();
    // 启动定时器，每30秒更新一次统计信息
    this.updateTimer = setInterval(() => {
      this.loadStats();
      // 同时更新每个资源的学习进度
      for (const resource of this.resources) {
        this.loadResourceProgress(resource.id);
      }
    }, 30000);
  }

  aboutToDisappear() {
    // 停止定时器
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
  }

  async checkUserRole() {
    interface UserInfo {
      role: string;
    }
    const userInfo = await StorageService.getItemAsync<UserInfo>('user');
    if (userInfo && (userInfo.role === 'admin' || userInfo.role === 'branch_admin')) {
      this.isAdmin = true;
    }
  }

  async loadStats() {
    try {
      const response = await this.studyService.getStudyStats();
      if (response.code === 200 && response.data) {
        this.studyStats = response.data;
      }
    } catch (error) {
      console.error('加载统计失败:', error);
    }
  }

  async loadResourceProgress(resourceId: string) {
    try {
      const response = await this.studyService.getResourceProgress(resourceId);
      if (response.code === 200 && response.data) {
        this.resourceProgresses.set(resourceId, response.data);
      }
    } catch (error) {
      console.error('加载资源进度失败:', error);
    }
  }

  async loadResources() {
    this.isLoading = true;
    try {
      let response: ApiResponse<StudyResource[]>;
      if (this.selectedTab === '我的收藏') {
        // 加载收藏的资源
        response = await this.studyService.getFavorites();
      } else {
        // 加载普通资源
        response = await this.studyService.getResources(this.selectedTab);
      }
      if (response.code === 200 && response.data) {
        this.resources = response.data;
        // 加载每个资源的学习进度
        for (const resource of this.resources) {
          await this.loadResourceProgress(resource.id);
        }
      }
    } catch (error) {
      console.error('加载资源失败:', error);
      promptAction.showToast({
        message: '加载资源失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async toggleFavorite(id: string) {
    try {
      const response = await this.studyService.toggleFavorite(id);
      if (response.code === 200) {
        promptAction.showToast({
          message: response.data ? '已收藏' : '已取消收藏',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('收藏失败:', error);
      promptAction.showToast({
        message: '操作失败',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      // 顶部统计信息
      Row() {
        Column() {
          Text('总课程')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: '4px' })
          Text(this.studyStats?.totalCourses?.toString() || '0')
            .fontSize(18)
            .fontWeight(700)
            .fontColor('#D32F2F')

        }
        .flexGrow(1)
        .alignItems(HorizontalAlign.Center)
        .margin({left:10})
        Column() {
          Text('已完成')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: '4px' })
          Text(this.studyStats?.completedCourses?.toString() || '0')
            .fontSize(18)
            .fontWeight(700)
            .fontColor('#D32F2F')
        }
        .flexGrow(1)
        .alignItems(HorizontalAlign.Center)
        .margin({left:4})
        Column() {
          Text('总时长')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: '4px' })
          Text(`${this.studyStats?.totalDuration || 0}分钟`)
            .fontSize(18)
            .fontWeight(700)
            .fontColor('#D32F2F')
        }          .flexGrow(1)          .alignItems(HorizontalAlign.Center)          .margin({left:10})
        if (this.isAdmin) {
          Row() {
            Button('上传')
              .width('200px')
              .height('100px')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#D32F2F')
              .borderRadius(8)
              .margin({ left:1,right: 10 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/StudyEditPage'
                });
              })
            Button('统计')
              .width('200px')
              .height('100px')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#D32F2F')
              .borderRadius(8)
              .margin({ right: 16})
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/StudyStatsPage'
                });
              })
          }
        }
      }
      .width('100%')
      .height('170px')
      .backgroundColor('#FFFFFF')
      .padding({ top: '16px' })
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: '#EEEEEE' })

      // 标签栏
      // 标签栏
      // 标签栏
      Scroll() {
        Row() {
          ForEach(this.tabs, (tab: string) => {
            Text(tab)
              .fontSize(16)
              .fontColor(this.selectedTab === tab ? '#D32F2F' : '#666666')
              .padding({ left: 30, right: 31, top: 12, bottom: 12 })
              .borderWidth({ bottom: 2 })
              .borderColor({ bottom: this.selectedTab === tab ? '#D32F2F' : 'transparent' })
              .onClick(async () => {
                this.selectedTab = tab;
                await this.loadResources();
              })
          }, (tab: string) => tab)
        }
        .margin({ left: 0 }) // 👈 核心：抵消第一个标签的左边距，实现完美顶格
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .width('100%') // 👈 用 width 替代 minWidth，兼容性更好
      }
      .scrollable(ScrollDirection.Horizontal)
      .align(Alignment.Start)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF')
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: '#EEEEEE' })




      // 资源列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }          .width('100%')          .height('100%')          .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.resources, (resource: StudyResource) => {
            ListItem() {
              Column() {
                Row() {
                  Image(resource.imageUrl)
                    .width('200px')
                    .height('200px')
                    .borderRadius(8)
                    .margin({ right: '16px' })
                  Column() {
                    Text(resource.title)
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor('#333333')
                      .margin({ bottom: '8px' })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row() {
                      Text(`预计: ${resource.duration}分钟`)
                        .fontSize(14)
                        .fontColor('#999999')
                      Text(`已学: ${Math.floor((this.resourceProgresses.get(resource.id)?.studyDuration || 0) / 60)}分钟`)
                        .fontSize(14)
                        .fontColor('#D32F2F')
                        .margin({ left: '16px' })
                    }
                    .margin({ bottom: '12px' })
                    Row() {
                      Button('学习')
                        .width('300px')
                        .height('100px')
                        .fontSize(14)
                        .fontColor('#FFFFFF')
                        .backgroundColor('#D32F2F')
                        .borderRadius(18)
                        .onClick(() => {
                          router.pushUrl({
                            url: 'pages/StudyDetailPage',
                            params: { resourceId: resource.id }
                          });
                        })
                      Image('https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=favorite%20icon%20gray&image_size=square')
                        .width('24px')
                        .height('24px')
                        .margin({ left: '16px' })
                        .onClick(() => {
                          this.toggleFavorite(resource.id);
                        })
                    }
                  }
                  .flexGrow(1)
                }
                .width('100%')
              }
              .width('100%')
              .padding({ left: '16px', right: '16px', top: '16px', bottom: '16px' })
              .backgroundColor('#FFFFFF')
              .margin({ bottom: '12px' })
              .borderRadius(8)
              .shadow({
                color: '#000000',
                radius: 4,
                offsetX: 0,
                offsetY: 2
              })
            }
          })
        }
        .width('100%')
        .backgroundColor('#F5F5F5')
        .padding({ top: '12px', left: '12px', right: '12px' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
