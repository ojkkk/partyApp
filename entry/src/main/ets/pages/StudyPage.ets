import { StudyResource, StudyTopic, StudyService, StudyStats, ResourceProgress } from '../models/StudyModel';
import { ApiResponse } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

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
export struct StudyPage {
  @State selectedTab: string = '党史学习';
  private tabs = ['党史学习', '专题学习', '我的收藏'];
  private studyService: StudyService = new StudyService();
  // 每个标签页独立的资源列表
  @State resourcesList: StudyResource[][] = [[], [], []];
  @State studyStats: StudyStats | null = null;
  @State isLoading: boolean = false;
  @State isAdmin: boolean = false;
  @State resourceProgresses: Map<string, ResourceProgress> = new Map();
  @State isRefreshing: boolean = false;
  @State topics: StudyTopic[] = [];              // 专题学习目录列表
  @State expandedTopics: Set<string> = new Set(); // 已展开的专题ID集合
  @State expandedHeights: Map<string, number> = new Map(); // 各专题子资源列表展开高度
  @State topicEditMode: boolean = false;          // 专题学习编辑模式
  private updateTimer: number | null = null;

  // Swiper 相关
  private swiperController: SwiperController = new SwiperController();
  @State currentIndex: number = 0;

  // 筛选状态: 'all' | 'completed' | 'in_progress'
  @State filterType: string = 'all';

  // 获取筛选后的专题列表
  getFilteredTopics(): StudyTopic[] {
    if (this.filterType === 'all') {
      return this.topics;
    }
    
    const result: StudyTopic[] = [];
    for (const topic of this.topics) {
      if (!topic.children || topic.children.length === 0) continue;
      
      const filteredChildren = topic.children.filter((r: StudyResource) => {
        const progress = this.calculateProgress(r);
        if (this.filterType === 'completed') return progress === 100;
        if (this.filterType === 'in_progress') return progress > 0 && progress < 100;
        return true;
      });
      
      if (filteredChildren.length > 0) {
        // 创建新的专题对象，包含过滤后的子资源
        result.push({
          id: topic.id,
          title: topic.title,
          content: topic.content,
          imageUrl: topic.imageUrl,
          childCount: filteredChildren.length,
          children: filteredChildren
        });
        // 自动展开该专题
        if (!this.expandedTopics.has(topic.id)) {
          this.expandedTopics.add(topic.id);
          const expandHeight = filteredChildren.length * 70 + 20;
          this.expandedHeights.set(topic.id, expandHeight);
        }
      }
    }
    return result;
  }

  async aboutToAppear() {
    await this.checkUserRole();
    await this.loadStats();
    await this.loadResources(0);
    // 监听专题刷新事件
    emitter.on('refreshTopics', () => {
      this.loadResources(1);
    });
    this.updateTimer = setInterval(() => {
      this.loadStats();
      for (const resources of this.resourcesList) {
        for (const resource of resources) {
          this.loadResourceProgress(resource.id);
        }
      }
      // 也刷新专题学习子资源的进度
      this.topics.forEach((topic: StudyTopic) => {
        if (topic.children) {
          topic.children.forEach((resource: StudyResource) => {
            this.loadResourceProgress(resource.id);
          });
        }
      });
    }, 30000);
  }

  aboutToDisappear() {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
    emitter.off('refreshTopics');
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

  async loadResources(index: number = this.currentIndex) {
    this.isLoading = true;
    try {
      if (index === 1) {
        // 专题学习：加载目录嵌套结构
        const response = await this.studyService.getTopics();
        if (response.code === 200 && response.data) {
          // 按专题自身的 createdAt 从早到晚排序
          this.topics = response.data.sort((a: StudyTopic, b: StudyTopic) => {
            const aTime = new Date(a.createdAt || 0).getTime();
            const bTime = new Date(b.createdAt || 0).getTime();
            return aTime - bTime;
          });
          // 每个专题的子资源也按 createdAt 从早到晚排序
          this.topics.forEach((topic: StudyTopic) => {
            if (topic.children && topic.children.length > 0) {
              topic.children.sort((a: StudyResource, b: StudyResource) => {
                return new Date(a.createdAt || 0).getTime() - new Date(b.createdAt || 0).getTime();
              });
              // 加载每个子资源的进度
              topic.children.forEach((resource: StudyResource) => {
                this.loadResourceProgress(resource.id);
              });
            }
          });
        }
      } else {
        const tabName = this.tabs[index];
        let response: ApiResponse<StudyResource[]>;
        if (tabName === '我的收藏') {
          response = await this.studyService.getFavorites();
        } else {
          response = await this.studyService.getResources(tabName);
        }
        if (response.code === 200 && response.data) {
          this.resourcesList[index] = response.data;
          this.resourcesList = [...this.resourcesList];
          for (const resource of response.data) {
            await this.loadResourceProgress(resource.id);
          }
        }
      }
    } catch (error) {
      console.error('加载资源失败:', error);
      promptAction.showToast({ message: '加载资源失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async toggleFavorite(id: string) {
    try {
      const response = await this.studyService.toggleFavorite(id);
      if (response.code === 200) {
        promptAction.showToast({ message: response.data ? '已收藏' : '已取消收藏', duration: 2000 });
      }
    } catch (error) {
      console.error('收藏失败:', error);
      promptAction.showToast({ message: '操作失败', duration: 2000 });
    }
  }

  // 切换专题目录展开/收起
  toggleTopic(topicId: string) {
    const isExpanding = !this.expandedTopics.has(topicId);
    if (isExpanding) {
      // 计算展开高度：每个子项约70px
      const topic = this.topics.find(t => t.id === topicId);
      const childCount = (topic?.children?.length || 0);
      const expandHeight = childCount * 70 + 20;
      this.expandedHeights.set(topicId, expandHeight);
      this.expandedHeights = new Map(this.expandedHeights);
    }
    animateTo({
      duration: 300,
      curve: Curve.EaseInOut,
      tempo: 1.2,
    }, () => {
      if (isExpanding) {
        this.expandedTopics.add(topicId);
      } else {
        this.expandedTopics.delete(topicId);
      }
      this.expandedTopics = new Set(this.expandedTopics);
    });
  }

  // ===================== 【切换标签】 =====================
  private changeTab(index: number) {
    this.swiperController.changeIndex(index);
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.currentIndex = index;
      this.selectedTab = this.tabs[index];
    });
    // 只有该标签未加载过数据时才刷新
    if (this.resourcesList[index].length === 0) {
      this.loadResources(index);
    }
  }

  // ===================== 【设置筛选】 =====================
  private setFilter(type: string) {
    this.filterType = type;
  }

  // ===================== 【获取学习中数量】 =====================
  private getInProgressCount(): number {
    // 如果是专题学习标签，统计专题的子资源
    if (this.currentIndex === 1) {
      let count = 0;
      for (const topic of this.topics) {
        if (topic.children) {
          count += topic.children.filter(r => {
            const progress = this.calculateProgress(r);
            return progress > 0 && progress < 100;
          }).length;
        }
      }
      return count;
    }
    
    // 党史学习标签
    const resources = this.resourcesList[this.currentIndex];
    if (!resources) return 0;
    return resources.filter(r => {
      const progress = this.calculateProgress(r);
      return progress > 0 && progress < 100;
    }).length;
  }

  // ===================== 【获取已完成数量】 =====================
  private getCompletedCount(): number {
    // 如果是专题学习标签，统计专题的子资源
    if (this.currentIndex === 1) {
      let count = 0;
      for (const topic of this.topics) {
        if (topic.children) {
          count += topic.children.filter(r => this.calculateProgress(r) === 100).length;
        }
      }
      return count;
    }
    
    // 党史学习标签
    const resources = this.resourcesList[this.currentIndex];
    if (!resources) return 0;
    return resources.filter(r => this.calculateProgress(r) === 100).length;
  }

  // ===================== 【获取筛选后的资源列表】 =====================
  private getFilteredResources(index: number): StudyResource[] {
    const resources = this.resourcesList[index];
    if (!resources) return [];
    if (this.filterType === 'all') return resources;
    if (this.filterType === 'completed') {
      return resources.filter(r => this.calculateProgress(r) === 100);
    }
    if (this.filterType === 'in_progress') {
      return resources.filter(r => {
        const progress = this.calculateProgress(r);
        return progress > 0 && progress < 100;
      });
    }
    return resources;
  }

  build() {
    Column() {
      // ===================== 【沉浸式渐变 Header】 =====================
      Stack({ alignContent: Alignment.TopStart }) {
        // 渐变背景
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 155,
            colors: [['#D83A34', 0.0], ['#B51F2E', 0.56], ['#8E1824', 1.0]]
          });

        // 顶部白色装饰线
        Column()
          .width('100%')
          .height(3)
          .backgroundColor('#FFFFFF')
          .opacity(0.5)
          .position({ x: 0, y: 0 });

        // 装饰圆形
        Column()
          .width(180)
          .height(180)
          .borderRadius(90)
          .backgroundColor('#FFFFFF')
          .opacity(0.06)
          .position({ x: 260, y: -60 });

        Column()
          .width(100)
          .height(100)
          .borderRadius(50)
          .backgroundColor('#FFFFFF')
          .opacity(0.10)
          .position({ x: 320, y: 20 });

        // 内容区
        Column() {
          // 标题栏
          Row() {
            Column() {
              Text('学习中心')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF');

              Text('党建学习 · 提升自我')
                .fontSize(12)
                .fontColor('#FFFFFF70')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start);

            Blank();

            // 管理员按钮
            if (this.isAdmin) {
              Row() {
                Button() {
                  Row() {
                    Image($rawfile('统计-黄.png'))
                      .width(14)
                      .height(14)
                      .margin({ right: 3 });
                    Text('统计')
                      .fontSize(11)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#F5D76E');
                  }
                }
                .height(28)
                .padding({ left: 10, right: 10 })
                .backgroundColor('#C85049')
                .border({ width: 1, color: '#8E1824' })
                .borderRadius(14)
                .onClick(() => router.pushUrl({ url: 'pages/StudyStatsPage' }));
              }
            }
          }
          .width('100%')
          .height(44);

          // 统计卡片区
          Row() {
            // 总课程
            Column() {
              Text(this.studyStats?.totalCourses?.toString() || '0')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.filterType === 'all' ? '#FFFFFF' : '#F7E9C7');
              Text('总课程')
                .fontSize(11)
                .fontColor(this.filterType === 'all' ? '#FFFFFF' : '#F7E9C7')
                .margin({ top: 2 });
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.filterType === 'all' ? '#C96A6B' : '#00000000')
            .borderRadius(8)
            .padding({ top: 8, bottom: 8 })
            .onClick(() => this.setFilter('all'));

            // 分隔线
            Column()
              .width(1)
              .height(32)
              .backgroundColor('#FFFFFF25')
              .margin({ left: 6, right: 6 });

            // 已完成
            Column() {
              Text(`${this.getCompletedCount()}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.filterType === 'completed' ? '#FFFFFF' : '#F7E9C7');
              Text('已完成')
                .fontSize(11)
                .fontColor(this.filterType === 'completed' ? '#FFFFFF' : '#F7E9C7')
                .margin({ top: 2 });
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.filterType === 'completed' ? '#C96A6B' : '#00000000')
            .borderRadius(8)
            .padding({ top: 8, bottom: 8 })
            .onClick(() => this.setFilter('completed'));

            // 分隔线
            Column()
              .width(1)
              .height(32)
              .backgroundColor('#FFFFFF25')
              .margin({ left: 6, right: 6 });

            // 学习中
            Column() {
              Text(`${this.getInProgressCount()}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.filterType === 'in_progress' ? '#FFFFFF' : '#F7E9C7');
              Text('学习中')
                .fontSize(11)
                .fontColor(this.filterType === 'in_progress' ? '#FFFFFF' : '#F7E9C7')
                .margin({ top: 2 });
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.filterType === 'in_progress' ? '#C96A6B' : '#00000000')
            .borderRadius(8)
            .padding({ top: 8, bottom: 8 })
            .onClick(() => this.setFilter('in_progress'));
          }
          .width('100%')
          .height(60)
          .backgroundColor('#00000012')
          .borderRadius(10)
          .padding({ left: 10, right: 10 })
          .margin({ top: 8 });
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 20,
          bottom: 6
        });
      }
      .width('100%')
      .height(150);

      // ==================================================================

      // ===================== 【标签栏 + Swiper 翻页】 =====================
      // 标签栏 - 参考 PolicyPage 风格，每个标签有自己的小红条
      Row() {
        ForEach(this.tabs, (tab: string, index: number) => {
          Column() {
            Text(tab)
              .fontSize(15)
              .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentIndex === index ? '#B51F2E' : '#666666')
              .padding({ left: 12, right: 12, top: 10, bottom: 8 });

            // 每个标签自己的小红条
            Row()
              .width(this.currentIndex === index ? 28 : 0)
              .height(3)
              .borderRadius(3)
              .backgroundColor('#B51F2E')
              .animation({ duration: 250, curve: Curve.EaseInOut });
          }
          .padding({ bottom: 6 })
          .layoutWeight(1)
          .backgroundColor(this.currentIndex === index ? '#FFF8F3' : '#FFFFFF')
          .borderRadius(10)
          .onClick(() => this.changeTab(index));
        }, (tab: string) => tab)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 0 })
      .backgroundColor('#FFFFFF')
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: '#EFE7DB' })
      .justifyContent(FlexAlign.SpaceBetween);

      // Swiper 内容区
      Column() {
        Refresh({
          refreshing: this.isRefreshing,
          offset: 100,
          friction: 100
        }) {
          Swiper(this.swiperController) {
            ForEach(this.tabs, (tab: string, index: number) => {
              if (index === 1) {
                this.buildTopicList();
              } else {
                this.buildResourceList(index);
              }
            }, (tab: string) => tab)
          }
          .index(this.currentIndex)
          .loop(false)
          .autoPlay(false)
          .indicator(false)
          .onChange((index: number) => {
            this.currentIndex = index;
            this.selectedTab = this.tabs[index];
            if (this.resourcesList[index].length === 0 && index !== 1) {
              this.loadResources(index);
            }
            if (this.resourcesList[index].length === 0) {
              this.loadResources(index);
            }
          });
        }
        .onRefreshing(async () => {
          this.isRefreshing = true;
          await this.loadStats();
          await this.loadResources(this.currentIndex);
          this.isRefreshing = false;
        })
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F7F4EF');
      }
      .layoutWeight(1)
      // ==================================================================
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }

  // ===================== 【计算进度】 =====================
  private calculateProgress(resource: StudyResource): number {
    const progress = this.resourceProgresses.get(resource.id);
    if (!progress) return 0;
    const expectedDuration = resource.duration * 60; // 转换为秒
    if (expectedDuration <= 0) return 0;
    return Math.min(100, Math.floor((progress.studyDuration / expectedDuration) * 100));
  }

  // ===================== 【专题学习列表 Builder】 =====================
  @Builder
  buildTopicList() {
    List() {
      // 列表标题
      ListItem() {
        Row() {
          Row() {
            Row()
              .width(4)
              .height(16)
              .borderRadius(2)
              .backgroundColor('#B51F2E')
              .margin({ right: 8 });
            Text(`专题学习 · ${this.topics.length} 个专题`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#666666');
          };

          Blank();

          if (this.isAdmin) {
            Button() {
              Text(this.topicEditMode ? '完成编辑' : '新建专题')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF');
            }
            .height(30)
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.topicEditMode ? '#A67C2E' : '#B51F2E')
            .borderRadius(15)
            .onClick(() => {
              if (this.topicEditMode) {
                this.topicEditMode = false;
              } else {
                router.pushUrl({ url: 'pages/StudyTopicEditPage', params: {} });
              }
            });

            if (this.topics.length > 0) {
              Button() {
                Text(this.topicEditMode ? '取消编辑' : '编辑专题')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.topicEditMode ? '#666666' : '#FFFFFF');
              }
              .height(30)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.topicEditMode ? '#F0EBE3' : '#B51F2E')
              .borderRadius(15)
              .margin({ left: 8 })
              .onClick(() => {
                this.topicEditMode = !this.topicEditMode;
              });
            }
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 });
      };

      if (this.isLoading && this.topics.length === 0) {
        ListItem() {
          Column() {
            LoadingProgress()
              .width(42)
              .height(42)
              .color('#B51F2E');
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12 });
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center);
        };
      } else if (this.topics.length === 0) {
        // 空态
        ListItem() {
          Column() {
            Stack({ alignContent: Alignment.Center }) {
              Column()
                .width(140)
                .height(140)
                .borderRadius(70)
                .backgroundColor('#FFFFFF');
              Column()
                .width(120)
                .height(120)
                .borderRadius(60)
                .border({ width: 2, color: '#EFE7DB', style: BorderStyle.Dashed });
              Image($rawfile('学习.png'))
                .width(56)
                .height(56)
                .opacity(0.6);
            }
            .margin({ bottom: 24 });

            Text('暂无专题')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F1F1F')
              .margin({ bottom: 8 });

            Text('管理员可创建专题学习目录，组织系列学习资源')
              .fontSize(13)
              .fontColor('#999999')
              .textAlign(TextAlign.Center)
              .padding({ left: 40, right: 40 })
              .margin({ bottom: 32 });
          }
          .width('100%')
          .height(400)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        };
      } else {
        ForEach(this.getFilteredTopics(), (topic: StudyTopic) => {
          ListItem() {
            this.TopicCard(topic);
          }
          .margin({ left: 12, right: 12, bottom: 12 });
        })

        // 底部留白
        ListItem() {
          Row().height(20);
        };
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor('#F7F4EF')
    .padding({ top: 4 });
  }

  // ===================== 【专题目录卡片 Builder】 =====================
  @Builder
  TopicCard(topic: StudyTopic) {
    Column() {
      // 目录头部
      Row() {
        // 左侧封面
        Image(topic.imageUrl || $rawfile('学习.png'))
          .width(80)
          .height(80)
          .objectFit(ImageFit.Cover)
          .borderRadius(10);

        Column() {
          Text(topic.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 6 });

          if (topic.content) {
            Text(topic.content)
              .fontSize(12)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ bottom: 4 });
          }

          Text(`${topic.childCount} 个资源`)
            .fontSize(11)
            .fontColor('#C9A45C')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#F5F0E8')
            .borderRadius(4);
        }
        .layoutWeight(1)
        .margin({ left: 12 });

        // 展开收起图标（固定宽度 24，避免文字跳动）
        Column() {
          SymbolGlyph(this.expandedTopics.has(topic.id) ? $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor(this.topicEditMode ? ['#B51F2E'] : ['#666666']);
        }
        .width(24)
        .height(40)
        .justifyContent(FlexAlign.Center);
      }
      .width('100%')
      .onClick(() => {
        if (this.topicEditMode) {
          router.pushUrl({ url: 'pages/StudyTopicEditPage', params: { topicId: topic.id } });
        } else {
          // 如果有筛选条件，切换后自动展开
          this.toggleTopic(topic.id);
          // 筛选状态下自动展开
          if (this.filterType !== 'all' && !this.expandedTopics.has(topic.id)) {
            // 延迟展开，等 toggle 完成后
            setTimeout(() => {
              if (!this.expandedTopics.has(topic.id)) {
                const topicData = this.topics.find(t => t.id === topic.id);
                const childCount = (topicData?.children?.length || 0);
                const expandHeight = childCount * 70 + 20;
                this.expandedHeights.set(topic.id, expandHeight);
                this.expandedHeights = new Map(this.expandedHeights);
                this.expandedTopics.add(topic.id);
                this.expandedTopics = new Set(this.expandedTopics);
              }
            }, 10);
          }
        }
      });

      // 子资源列表（动画展开，非编辑模式下）
      if (!this.topicEditMode && topic.children && topic.children.length > 0) {
        Column() {
          Divider().color('#F3EBDD').strokeWidth(1).margin({ top: 10, bottom: 10 });
          ForEach(topic.children, (resource: StudyResource) => {
            this.TopicChildItem(resource);
          });
        }
        .width('100%')
        .clip(true)
        .height(this.expandedTopics.has(topic.id) ? this.expandedHeights.get(topic.id) ?? 'auto' : 0)
        .transition(TransitionEffect.OPACITY);
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.topicEditMode ? '#FFFBF5' : '#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: this.topicEditMode ? '#F5DDBB' : '#EFE7DB' })
    .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 3 });
  }

  // ===================== 【专题子资源项 Builder】 =====================
  @Builder
  TopicChildItem(resource: StudyResource) {
    Row() {
      Image(resource.imageUrl || $rawfile('学习.png'))
        .width(50)
        .height(50)
        .objectFit(ImageFit.Cover)
        .borderRadius(8);

      Column() {
        Text(resource.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 });

        Text(resource.duration > 0 ? `${resource.duration} 分钟` : '图文')
          .fontSize(11)
          .fontColor('#999999');
      }
      .layoutWeight(1)
      .margin({ left: 10, right: 10 })
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/StudyDetailPage', params: { resourceId: resource.id } });
    });
  }

  // ===================== 【资源列表 Builder】 =====================
  @Builder
  buildResourceList(index: number) {
    List() {
      // 列表标题
      ListItem() {
          Row() {
            Row() {
              Row()
                .width(4)
                .height(16)
                .borderRadius(2)
                .backgroundColor('#B51F2E')
                .margin({ right: 8 });
              Text(`${this.tabs[index]} · ${this.getFilteredResources(index).length} 个资源`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#666666');
            };

            Blank();

            if (this.filterType !== 'all') {
              Text(`已筛选: ${this.filterType === 'completed' ? '已完成' : '学习中'}`)
                .fontSize(12)
                .fontColor('#8B4513')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor('#F5F0E8')
                .borderRadius(10)
                .margin({ right: 8 })
                .onClick(() => this.setFilter('all'));
            }

            // 党史学习列表右上角上传按钮（仅管理员可见）
            if (this.isAdmin && index === 0) {
              Button() {
                Text('上传资源')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF');
              }
              .height(30)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#B51F2E')
              .borderRadius(15)
              .onClick(() => router.pushUrl({ url: 'pages/StudyEditPage' }));
            }

          }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 16,
          bottom: 8
        });
      };

      if (this.isLoading && this.resourcesList[index].length === 0) {
        ListItem() {
          Column() {
            LoadingProgress()
              .width(42)
              .height(42)
              .color('#B51F2E');
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12 });
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center);
        };
      } else if (this.resourcesList[index].length === 0) {
        // 空态
        ListItem() {
          Column() {
            Stack({ alignContent: Alignment.Center }) {
              Column()
                .width(140)
                .height(140)
                .borderRadius(70)
                .backgroundColor('#FFFFFF');

              Column()
                .width(120)
                .height(120)
                .borderRadius(60)
                .border({ width: 2, color: '#EFE7DB', style: BorderStyle.Dashed });

              Image($rawfile('学习.png'))
                .width(56)
                .height(56)
                .opacity(0.6);
            }
            .margin({ bottom: 24 });

            Text(this.tabs[index] === '我的收藏' ? '暂无收藏' : '暂无资源')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F1F1F')
              .margin({ bottom: 8 });

            Text(this.tabs[index] === '我的收藏' ? '点击收藏图标保存感兴趣的资源' : '暂无学习资源，敬请期待')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ bottom: 32 });

            if (this.tabs[index] === '我的收藏') {
              Button() {
                Row() {
                  Text('去浏览资源')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#FFFFFF');
                }
              }
              .width(160)
              .height(46)
              .linearGradient({
                angle: 90,
                colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
              })
              .borderRadius(23)
              .shadow({
                radius: 12,
                color: '#B51F2E35',
                offsetX: 0,
                offsetY: 4
              })
              .onClick(() => {
                this.changeTab(0);
              });
            }
          }
          .width('100%')
          .height(400)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        };
      } else {
        ForEach(this.getFilteredResources(index), (resource: StudyResource) => {
          ListItem() {
            this.ResourceCard(resource)
          }
          .margin({ left: 12, right: 12, bottom: 12 });
        })

        // 底部留白
        ListItem() {
          Row().height(20);
        };
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor('#F7F4EF')
    .padding({ top: 4 });
  }

  // ===================== 【资源卡片 Builder】 =====================
  @Builder
  ResourceCard(resource: StudyResource) {
    Row() {
      // 左侧封面
      Stack({ alignContent: Alignment.Center }) {
        Image(resource.imageUrl)
          .width(90)
          .height(90)
          .objectFit(ImageFit.Cover)
          .borderRadius(10);

        // 类型标签
        Text(resource.type || '视频')
          .fontSize(10)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .padding({
            left: 6,
            right: 6,
            top: 2,
            bottom: 2
          })
          .backgroundColor('#B51F2E')
          .borderRadius({ topLeft: 10, bottomRight: 8 })
          .position({ x: 0, y: 0 });
      }
      .margin({ right: 14 });

      // 右侧内容
      Column() {
        Text(resource.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: 10 });

        // 进度条区域
        Column() {
          Row() {
            Text('学习进度')
              .fontSize(11)
              .fontColor('#999999');

            Blank();

            Text(`${this.calculateProgress(resource)}%`)
              .fontSize(11)
              .fontColor('#B51F2E')
              .fontWeight(FontWeight.Medium);
          }
          .width('100%')
          .margin({ bottom: 6 });

          // 进度条
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(5)
              .backgroundColor('#EFE7DB')
              .borderRadius(3);

            Row()
              .width(`${this.calculateProgress(resource)}%`)
              .height(5)
              .backgroundColor('#B51F2E')
              .borderRadius(3);
          }
          .width('100%')
          .height(5);
        }
        .width('100%')
        .margin({ bottom: 10 });

        // 底部信息 - 已学时长
        Row() {
          Image($rawfile('时间.png'))
            .width(13)
            .height(13)
            .opacity(0.5)
            .margin({ right: 4 });
          Text(`预计 ${resource.duration} 分钟`)
            .fontSize(12)
            .fontColor('#999999');

          Blank();

          Text(`已学 ${Math.floor((this.resourceProgresses.get(resource.id)?.studyDuration || 0) / 60)} 分钟`)
            .fontSize(12)
            .fontColor('#B51F2E')
            .fontWeight(FontWeight.Medium);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#EFE7DB' })
    .shadow({
      radius: 8,
      color: '#00000006',
      offsetX: 0,
      offsetY: 3
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/StudyDetailPage',
        params: { resourceId: resource.id }
      });
    });
  }
}