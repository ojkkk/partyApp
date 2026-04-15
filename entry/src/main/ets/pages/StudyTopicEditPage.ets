import { StudyResource, StudyTopic, StudyService } from '../models/StudyModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

interface DialogResult {
  index: number
}

// ─────────────────────────────────────────────────────────────────────────────
// 专题学习目录编辑页
// 功能：创建/编辑专题目录 + 管理目录下的子资源
// ─────────────────────────────────────────────────────────────────────────────

@Entry
@Component
struct StudyTopicEditPage {
  private studyService: StudyService = new StudyService();
  @State topicId: string = '';
  @State isEdit: boolean = false;
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;

  // 目录基本信息
  @State title: string = '';
  @State content: string = '';
  @State imageUrl: string = '';
  @State createdBy: string = '';

  // 子资源管理
  @State children: StudyResource[] = [];
  @State showChildForm: boolean = false;
  @State editingChild: StudyResource | null = null;
  @State childTitle: string = '';
  @State childContent: string = '';
  @State childDuration: string = '';
  @State childImageUrl: string = '';
  @State childVideoUrl: string = '';

  // 图片URL输入浮层
  @State showImageUrlInput: boolean = false;
  @State pendingImageUrl: string = '';
  @State imageUrlTarget: string = ''; // 'topic' | 'child'

  // ===================== 颜色配置 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';
  private readonly COLOR_BG = '#F7F4EF';
  private readonly COLOR_CARD = '#FFFFFF';
  private readonly COLOR_TEXT = '#1F1F1F';
  private readonly COLOR_TEXT_SEC = '#666666';
  private readonly COLOR_TEXT_TER = '#999999';
  private readonly COLOR_DIVIDER = '#F0EBE3';

  async aboutToAppear() {
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params['topicId']) {
      this.topicId = params['topicId'];
      this.isEdit = true;
      await this.loadTopic();
    }
  }

  async loadTopic() {
    this.isLoading = true;
    try {
      const detailRes = await this.studyService.getResourceDetail(this.topicId);
      if (detailRes.code === 200 && detailRes.data) {
        const topic = detailRes.data;
        this.title = topic.title || '';
        this.content = topic.content || '';
        this.imageUrl = topic.imageUrl || '';
        this.createdBy = topic.createdBy || '';
      }
      const childrenRes = await this.studyService.getTopicChildren(this.topicId);
      if (childrenRes.code === 200 && childrenRes.data) {
        this.children = childrenRes.data;
      }
    } catch (error) {
      console.error('加载专题失败:', error);
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  // ===================== 保存专题目录 =====================
  async saveTopic() {
    if (!this.title.trim()) {
      promptAction.showToast({ message: '请输入专题标题', duration: 2000 });
      return;
    }
    this.isSaving = true;
    try {
      const topicData: StudyResource = {
        id: this.topicId ?? '',
        title: this.title.trim(),
        content: this.content.trim(),
        imageUrl: this.imageUrl,
        type: '专题学习',
        duration: 0,
      };

      let savedTopic: StudyResource;
      if (this.isEdit) {
        const res = await this.studyService.updateTopic(this.topicId, topicData);
        savedTopic = res.data!;
      } else {
        const res = await this.studyService.createTopic(topicData);
        savedTopic = res.data!;
        this.topicId = savedTopic.id ?? '';
        this.isEdit = true;
      }

      promptAction.showToast({ message: '保存成功', duration: 2000 });
      emitter.emit('refreshTopics', null);
    } catch (error) {
      console.error('保存失败:', error);
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.isSaving = false;
    }
  }

  // ===================== 删除专题目录 =====================
  async deleteTopic() {
    if (!this.topicId) return;
    promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除该专题吗？目录下的所有资源也会一并删除。',
      buttons: [{ text: '删除', color: '#B51F2E' }, { text: '取消', color: '#999999' }]
    }).then((value: DialogResult) => {
      if (value.index === 0) {
        this.doDeleteTopic();
      }
    });
  }

  async doDeleteTopic() {
    try {
      const res = await this.studyService.deleteTopic(this.topicId);
      if (res.code === 200) {
        promptAction.showToast({ message: '删除成功', duration: 2000 });
        emitter.emit('refreshTopics', null);
        router.back();
      }
    } catch (error) {
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    }
  }

  // ===================== 子资源表单 =====================
  openChildForm(resource?: StudyResource) {
    if (resource) {
      this.editingChild = resource;
      this.childTitle = resource.title;
      this.childContent = resource.content || '';
      this.childDuration = resource.duration > 0 ? resource.duration.toString() : '';
      this.childImageUrl = resource.imageUrl || '';
      this.childVideoUrl = resource.videoUrl || '';
    } else {
      this.editingChild = null;
      this.childTitle = '';
      this.childContent = '';
      this.childDuration = '';
      this.childImageUrl = '';
      this.childVideoUrl = '';
    }
    this.showChildForm = true;
  }

  async saveChild() {
    if (!this.childTitle.trim()) {
      promptAction.showToast({ message: '请输入资源标题', duration: 2000 });
      return;
    }
    const resourceData: StudyResource = {
      id: this.editingChild?.id || '',
      title: this.childTitle.trim(),
      content: this.childContent.trim(),
      imageUrl: this.childImageUrl,
      videoUrl: this.childVideoUrl || undefined,
      type: '专题学习',
      duration: parseInt(this.childDuration) || 0,
      parentId: this.topicId,
    };

    try {
      if (this.editingChild) {
        const res = await this.studyService.updateResource(this.editingChild.id, resourceData);
        if (res.code === 200) {
          const idx = this.children.findIndex(r => r.id === this.editingChild!.id);
          if (idx >= 0) this.children[idx] = res.data!;
        }
      } else {
        const res = await this.studyService.createResource(resourceData);
        if (res.code === 200) {
          this.children.push(res.data!);
        }
      }
      this.children = [...this.children];
      this.showChildForm = false;
      promptAction.showToast({ message: '保存成功', duration: 2000 });
    } catch (error) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  async deleteChild(resource: StudyResource) {
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除"${resource.title}"吗？`,
      buttons: [{ text: '删除', color: '#B51F2E' }, { text: '取消', color: '#999999' }]
    }).then((value: DialogResult) => {
      if (value.index === 0) {
        this.doDeleteChild(resource);
      }
    });
  }

  async doDeleteChild(resource: StudyResource) {
    try {
      const res = await this.studyService.deleteResource(resource.id);
      if (res.code === 200) {
        this.children = this.children.filter(r => r.id !== resource.id);
        promptAction.showToast({ message: '已删除', duration: 2000 });
      }
    } catch (error) {
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    }
  }

  // ===================== 封面区域点击 → 打开URL输入 =====================
  openCoverInput() {
    this.pendingImageUrl = this.imageUrl;
    this.imageUrlTarget = 'topic';
    this.showImageUrlInput = true;
  }

  openChildCoverInput() {
    this.pendingImageUrl = this.childImageUrl;
    this.imageUrlTarget = 'child';
    this.showImageUrlInput = true;
  }

  insertImageUrl() {
    if (!this.pendingImageUrl.trim()) {
      promptAction.showToast({ message: '请输入图片URL', duration: 2000 });
      return;
    }
    if (this.imageUrlTarget === 'child') {
      this.childImageUrl = this.pendingImageUrl.trim();
    } else {
      this.imageUrl = this.pendingImageUrl.trim();
    }
    this.showImageUrlInput = false;
    this.pendingImageUrl = '';
  }

  // ===================== 页面构建 =====================
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部导航栏
        Row() {
          Button() {
            Text('‹ 返回')
              .fontSize(16)
              .fontColor('#1F1F1F');
          }
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            emitter.emit('refreshTopics', null);
            router.back();
          });

          Blank();

          Text(this.isEdit ? '编辑专题' : '新建专题')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F');

          Blank();

          if (this.isEdit) {
            Text('删除')
              .fontSize(14)
              .fontColor('#B51F2E')
              .onClick(() => this.deleteTopic());
          } else {
            Text('  取消  ')
              .fontSize(14)
              .fontColor('#999999');
          }
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 10, bottom: 10 })
        .backgroundColor('#FFFFFF')
        .border({ width: 0, color: this.COLOR_DIVIDER })
        .shadow({ radius: 6, color: '#00000010', offsetX: 0, offsetY: 2 });

        Scroll() {
          Column() {
            this.FormCard();
            if (this.isEdit || this.children.length > 0) {
              this.ChildrenCard();
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 90 });
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.COLOR_BG);

        // 悬浮保存按钮
        Button() {
          Row() {
            if (this.isSaving) {
              LoadingProgress()
                .width(18)
                .height(18)
                .color('#FFFFFF')
                .margin({ right: 6 });
            }
            Text(this.isSaving ? '保存中...' : '保存专题')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF');
          }
        }
        .width('90%')
        .height(50)
        .linearGradient({
          angle: 90,
          colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
        })
        .borderRadius(25)
        .shadow({ radius: 14, color: '#B51F2E40', offsetX: 0, offsetY: 6 })
        .margin({ bottom: 24 })
        .onClick(() => this.saveTopic())
        .enabled(!this.isSaving);
      }
      .width('100%')
      .height('100%');

      // 子资源弹窗
      if (this.showChildForm) {
        this.ChildFormOverlay();
      }

      // 图片URL输入浮层
      if (this.showImageUrlInput) {
        this.ImageUrlOverlay();
      }
    }
  }

  // ──────────── 子资源表单浮层（虚化背景 + 统一格式） ────────────
  @Builder
  ChildFormOverlay() {
    Column() {
      // 虚化遮罩层
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#C0000000')
          .onClick(() => this.showChildForm = false);

        Column() {
          // 标题栏
          Row() {
            Text(this.editingChild ? '编辑资源' : '添加资源')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F1F1F');
            Blank();
            Text('×')
              .fontSize(26)
              .fontColor('#999999')
              .onClick(() => this.showChildForm = false);
          }
          .width('100%')
          .padding({ left: 20, right: 12, top: 18, bottom: 14 });

          Divider().color(this.COLOR_DIVIDER);

          // 表单内容
          Scroll() {
            Column() {
              // 资源标题
              this.FormField('资源标题', this.childTitle, (v) => this.childTitle = v, '请输入资源标题');

              // 学习时长
              this.FormField('学习时长（分钟）', this.childDuration, (v) => this.childDuration = v, '请输入学习时长');

              // 封面图片URL
              this.FormField('封面图片URL', this.childImageUrl, (v) => this.childImageUrl = v, '请输入封面图片URL');

              // 视频URL
              this.FormField('视频URL', this.childVideoUrl, (v) => this.childVideoUrl = v, '请输入视频URL（m3u8/mp4），可选');

              // 内容简介
              Column() {
                Text('内容简介')
                  .fontSize(14)
                  .fontColor(this.COLOR_TEXT_SEC)
                  .align(Alignment.Start)
                  .margin({ bottom: 8 });
                TextArea({ text: this.childContent })
                  .width('100%')
                  .height(100)
                  .fontSize(14)
                  .fontColor(this.COLOR_TEXT)
                  .backgroundColor(this.COLOR_BG)
                  .borderRadius(10)
                  .border({ width: 1, color: this.COLOR_DIVIDER })
                  .padding(12)
                  .placeholderFont({ size: 14, style: FontStyle.Normal })
                  .placeholderColor(this.COLOR_TEXT_TER)
                  .onChange((v: string) => this.childContent = v);
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ top: 14 });
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 10, bottom: 20 });
          }
          .width('100%')
          .constraintSize({ maxHeight: 520 });

          // 底部保存按钮
          Button('保存资源')
            .width('90%')
            .height(46)
            .margin({ left: 20, right: 20, bottom: 20 })
            .linearGradient({
              angle: 90,
              colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
            })
            .fontColor('#FFFFFF')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .borderRadius(23)
            .onClick(() => this.saveChild());
        }
        .width('92%')
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .clip(true);
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }

  // ──────────── 图片URL输入浮层 ────────────
  @Builder
  ImageUrlOverlay() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        // 遮罩（点击关闭）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#B0000000')
          .onClick(() => this.showImageUrlInput = false);

        // 输入卡片
        Column() {
          Text('输入图片URL')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
            .margin({ bottom: 14 });

          TextInput({ text: this.pendingImageUrl, placeholder: 'https://...' })
            .width('100%')
            .height(46)
            .fontSize(14)
            .fontColor(this.COLOR_TEXT)
            .backgroundColor(this.COLOR_BG)
            .borderRadius(10)
            .border({ width: 1, color: this.COLOR_DIVIDER })
            .padding({ left: 14 })
            .placeholderFont({ size: 14, style: FontStyle.Normal })
            .placeholderColor(this.COLOR_TEXT_TER)
            .onChange((v: string) => this.pendingImageUrl = v);

          Row() {
            Button('取消')
              .width('46%')
              .height(42)
              .backgroundColor('#F0EBE3')
              .fontColor(this.COLOR_TEXT_SEC)
              .fontSize(14)
              .borderRadius(21)
              .onClick(() => this.showImageUrlInput = false);

            Button('确认')
              .width('46%')
              .height(42)
              .linearGradient({
                angle: 90,
                colors: [['#D83A34', 0.0], ['#B51F2E', 1.0]]
              })
              .fontColor('#FFFFFF')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .borderRadius(21)
              .onClick(() => this.insertImageUrl());
          }
          .width('100%')
          .margin({ top: 16 })
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('86%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16);
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }

  // ──────────── 专题信息卡片 ────────────
  @Builder
  FormCard() {
    Column() {
      Text('专题信息')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F1F1F')
        .align(Alignment.Start)
        .margin({ bottom: 14 });

      // 专题标题
      this.FormField('专题标题', this.title, (v) => this.title = v, '请输入专题名称，如"红军长征"');

      // 专题简介
      Column() {
        Text('专题简介')
          .fontSize(14)
          .fontColor(this.COLOR_TEXT_SEC)
          .align(Alignment.Start)
          .margin({ bottom: 8 });
        TextArea({ text: this.content })
          .width('100%')
          .height(100)
          .fontSize(14)
          .fontColor(this.COLOR_TEXT)
          .backgroundColor(this.COLOR_BG)
          .borderRadius(10)
          .border({ width: 1, color: this.COLOR_DIVIDER })
          .padding(12)
          .placeholderFont({ size: 14, style: FontStyle.Normal })
          .placeholderColor(this.COLOR_TEXT_TER)
          .onChange((v: string) => this.content = v);
        Text('简要描述该专题的核心内容，帮助党员快速了解专题主题')
          .fontSize(11)
          .fontColor(this.COLOR_TEXT_TER)
          .margin({ top: 6 });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 14 });

      // 专题封面
      Column() {
        Text('专题封面')
          .fontSize(14)
          .fontColor(this.COLOR_TEXT_SEC)
          .align(Alignment.Start)
          .margin({ bottom: 8 });

        if (this.imageUrl) {
          Stack({ alignContent: Alignment.TopEnd }) {
            Image(this.imageUrl)
              .width('100%')
              .height(160)
              .objectFit(ImageFit.Cover)
              .borderRadius(10)
              .onClick(() => this.openCoverInput());
            Column() {
              Text('×')
                .fontSize(18)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold);
            }
            .width(32)
            .height(32)
            .backgroundColor('#00000060')
            .borderRadius(16)
            .justifyContent(FlexAlign.Center)
            .margin({ top: 12, right: 8 })
            .onClick(() => this.imageUrl = '');
          }
        } else {
          Column() {
            Image($rawfile('上传.png'))
              .width(48)
              .height(48)
              .opacity(0.5)
              .margin({ top: 24 });
            Text('点击此处输入封面图片URL')
              .fontSize(12)
              .fontColor(this.COLOR_TEXT_TER)
              .margin({ top: 8, bottom: 24 });
          }
          .width('100%')
          .backgroundColor(this.COLOR_BG)
          .borderRadius(10)
          .border({ width: 1, color: this.COLOR_DIVIDER, style: BorderStyle.Dashed })
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 8 })
          .onClick(() => this.openCoverInput());
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 14 });
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 14 });
  }

  // ──────────── 子资源列表卡片 ────────────
  @Builder
  ChildrenCard() {
    Column() {
      Row() {
        Text('子资源')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F');

        Blank();

        Button() {
          Row() {
            Text('+ 添加资源')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF');
          }
        }
        .height(32)
        .padding({ left: 12, right: 12 })
        .backgroundColor(this.COLOR_PRIMARY)
        .borderRadius(16)
        .onClick(() => this.openChildForm());

        Text(`  ${this.children.length} 个`)
          .fontSize(12)
          .fontColor(this.COLOR_TEXT_TER);
      }
      .width('100%')
      .margin({ bottom: 12 });

      if (this.children.length === 0) {
        Column() {
          Image($rawfile('暂无内容.png'))
            .width(64)
            .height(64)
            .opacity(0.5)
            .margin({ bottom: 8 });
          Text('暂无资源，点击上方按钮添加')
            .fontSize(13)
            .fontColor(this.COLOR_TEXT_TER);
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
        .alignItems(HorizontalAlign.Center);
      } else {
        ForEach(this.children, (resource: StudyResource) => {
          Column() {
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

                Row() {
                  if (resource.videoUrl) {
                    Text('视频')
                      .fontSize(11)
                      .fontColor('#C9A45C')
                      .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      .backgroundColor('#F5F0E8')
                      .borderRadius(3);
                  }
                  Text(resource.duration > 0 ? `${resource.duration} 分钟` : '图文')
                    .fontSize(11)
                    .fontColor(this.COLOR_TEXT_TER);
                }
              }
              .layoutWeight(1)
              .margin({ left: 10, right: 10 })
              .alignItems(HorizontalAlign.Start);

              Text('编辑')
                .fontSize(12)
                .fontColor(this.COLOR_PRIMARY)
                .onClick(() => this.openChildForm(resource));

              Text('删除')
                .fontSize(12)
                .fontColor('#FF6B6B')
                .margin({ left: 12 })
                .onClick(() => this.deleteChild(resource));
            }
            .width('100%')
            .alignItems(VerticalAlign.Center);

            if (this.children.indexOf(resource) < this.children.length - 1) {
              Divider().color(this.COLOR_DIVIDER).margin({ top: 10 });
            }
          }
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER });
  }

  // ──────────── 通用表单项：第一行名称，第二行输入框 ────────────
  @Builder
  FormField(label: string, value: string, onChange: (v: string) => void, placeholder: string) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_SEC)
        .align(Alignment.Start)
        .margin({ bottom: 8 });
      TextInput({ text: value, placeholder: placeholder })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor(this.COLOR_TEXT)
        .backgroundColor(this.COLOR_BG)
        .borderRadius(10)
        .border({ width: 1, color: this.COLOR_DIVIDER })
        .padding({ left: 12 })
        .placeholderFont({ size: 14, style: FontStyle.Normal })
        .placeholderColor(this.COLOR_TEXT_TER)
        .onChange(onChange);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }
}
