import { Policy, PolicyService } from '../models/PolicyModel';
import { ApiResponse } from '../models/UserModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { emitter } from '@kit.BasicServicesKit';

@Entry
@Component
struct PolicyEditPage {
  private policyService: PolicyService = new PolicyService();
  @State policyId: string = '';
  @State isEdit: boolean = false;
  @State title: string = '';
  @State content: string = '';
  @State selectedType: string = '新闻动态';
  private types = ['新闻动态', '政策法规', '重要讲话', '先进典型'];
  @State publishDate: string = new Date().toISOString().split('T')[0];
  @State imageUrl: string = '';
  @State videoUrl: string = '';
  @State publisher: string = '';
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;

  // 日期选择器弹窗相关
  @State showDatePicker: boolean = false;
  @State pickerYear: number = new Date().getFullYear();
  @State pickerMonth: number = new Date().getMonth() + 1;
  @State pickerDay: number = new Date().getDate();

  // 插图URL输入浮层
  @State showImgUrlInput: boolean = false;
  @State pendingImgUrl: string = '';

  // TextArea 光标位置控制
  private contentController: TextAreaController = new TextAreaController();
  @State caretOffset: number = 0;

  // ===================== 颜色配置 - 庄重红金正式风 =====================
  private readonly COLOR_PRIMARY = '#B51F2E';
  private readonly COLOR_PRIMARY_LIGHT = '#D83A34';
  private readonly COLOR_GOLD = '#C9A45C';
  private readonly COLOR_BG = '#F7F4EF';
  private readonly COLOR_CARD = '#FFFFFF';
  private readonly COLOR_TEXT_PRIMARY = '#1F1F1F';
  private readonly COLOR_TEXT_SECONDARY = '#666666';
  private readonly COLOR_TEXT_TERTIARY = '#999999';
  private readonly COLOR_DIVIDER = '#F0EBE3';

  async aboutToAppear() {
    const paramsObj = router.getParams() as Object;
    const params = paramsObj as Record<string, string>;
    if (params && params['policyId']) {
      this.policyId = params['policyId'];
      this.isEdit = true;
      await this.loadPolicy();
    }
  }

  async loadPolicy() {
    this.isLoading = true;
    try {
      const response: ApiResponse<Policy> = await this.policyService.getPolicyDetail(this.policyId);
      if (response.code === 200 && response.data) {
        const policy = response.data;
        this.title = policy.title;
        this.content = policy.content;
        this.selectedType = policy.type;
        this.publishDate = policy.publishDate;
        this.imageUrl = policy.imageUrl;
        this.videoUrl = policy.videoUrl || '';
        this.publisher = policy.publisher || '';
        // 同步日期选择器
        this.syncPickerFromDate(policy.publishDate);
      }
    } catch (error) {
      console.error('加载政策失败:', error);
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  syncPickerFromDate(dateStr: string) {
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      this.pickerYear = parseInt(parts[0]) || new Date().getFullYear();
      this.pickerMonth = parseInt(parts[1]) || (new Date().getMonth() + 1);
      this.pickerDay = parseInt(parts[2]) || new Date().getDate();
    }
  }

  confirmDatePicker() {
    const mm = this.pickerMonth < 10 ? `0${this.pickerMonth}` : `${this.pickerMonth}`;
    const dd = this.pickerDay < 10 ? `0${this.pickerDay}` : `${this.pickerDay}`;
    this.publishDate = `${this.pickerYear}-${mm}-${dd}`;
    this.showDatePicker = false;
  }

  // 在光标位置插入图片标记
  insertImageTag(url: string) {
    if (!url.trim()) return;
    const tag = `\n[IMG:${url.trim()}]\n`;
    const pos = this.caretOffset;
    const before = this.content.substring(0, pos);
    const after = this.content.substring(pos);
    this.content = before + tag + after;
    // 更新光标位置到插入内容末尾
    this.caretOffset = pos + tag.length;
    this.pendingImgUrl = '';
    this.showImgUrlInput = false;
  }

  async savePolicy() {
    if (!this.title.trim()) {
      promptAction.showToast({ message: '请输入标题', duration: 2000 });
      return;
    }
    if (!this.content.trim()) {
      promptAction.showToast({ message: '请输入内容', duration: 2000 });
      return;
    }
    if (!this.imageUrl.trim()) {
      promptAction.showToast({ message: '请输入封面图片URL', duration: 2000 });
      return;
    }

    this.isSaving = true;
    try {
      const policy: Policy = {
        id: this.policyId,
        title: this.title.trim(),
        content: this.content.trim(),
        type: this.selectedType,
        publishDate: this.publishDate,
        imageUrl: this.imageUrl.trim(),
        videoUrl: this.videoUrl.trim() || undefined,
        publisher: this.publisher.trim() || undefined
      };

      let response: ApiResponse<Policy>;
      if (this.isEdit) {
        response = await this.policyService.updatePolicy(this.policyId, policy);
      } else {
        response = await this.policyService.createPolicy(policy);
      }

      if (response.code === 200) {
        promptAction.showToast({ message: this.isEdit ? '更新成功' : '创建成功', duration: 2000 });
        emitter.emit("refreshPolicies", null);
        router.back();
      } else {
        promptAction.showToast({ message: response.message || '保存失败', duration: 2000 });
      }
    } catch (error) {
      console.error('保存失败:', error);
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.buildHeader();

        if (this.isLoading) {
          this.buildLoadingState();
        } else {
          this.buildForm();
        }
      }
      .width('100%')
      .height('100%');

      // 悬浮保存按钮
      if (!this.isLoading) {
        Button(this.isSaving ? '保存中...' : (this.isEdit ? '保存修改' : '创建发布'))
          .width('90%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isSaving ? this.COLOR_TEXT_TERTIARY : this.COLOR_PRIMARY)
          .borderRadius(24)
          .margin({ bottom: 24 })
          .enabled(!this.isSaving)
          .shadow({ radius: 8, color: this.isSaving ? '#00000010' : 'rgba(181, 31, 46, 0.3)', offsetX: 0, offsetY: 4 })
          .onClick(() => this.savePolicy());
      }

      // 日期选择器浮层
      if (this.showDatePicker) {
        this.buildDatePickerOverlay();
      }

      // 插图URL输入浮层
      if (this.showImgUrlInput) {
        this.buildImgUrlOverlay();
      }
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
            .onClick(() => {
              emitter.emit("refreshPolicies", null);
              router.back();
            });
        }
        .width(56)
        .height('100%')
        .justifyContent(FlexAlign.Center);

        Text(this.isEdit ? '编辑政策' : '新建政策')
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
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.COLOR_PRIMARY);
      Text('加载中...')
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_TERTIARY)
        .margin({ top: 12 });
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  buildForm() {
    Scroll() {
      Column() {
        // 标题输入
        this.TitleFormCard();

        // 类型选择
        this.TypeFormCard();

        // 发布人
        this.PublisherFormCard();

        // 发布日期（选择器）
        this.DateFormCard();

        // 封面图片
        this.ImageFormCard();

        // 视频URL（可选）
        this.VideoFormCard();

        // 内容编辑（图文混排）
        this.ContentFormCard();

        // 底部留白
        Row().height(90);
      }
      .width('100%')
      .padding({ top: 16, left: 16, right: 16 });
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off);
  }

  // 标题表单卡片
  @Builder
  TitleFormCard() {
    Column() {
      Row() {
        Text('标题')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
        Text('*')
          .fontSize(15)
          .fontColor(this.COLOR_PRIMARY)
          .margin({ left: 2 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      TextInput({ text: this.title, placeholder: '请输入政策标题' })
        .width('100%')
        .height(48)
        .fontSize(15)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .backgroundColor(this.COLOR_BG)
        .borderRadius(10)
        .border({ width: 1, color: this.COLOR_DIVIDER })
        .padding({ left: 16, right: 16 })
        .onChange((value: string): void => { this.title = value; });
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 12 });
  }

  // 类型表单卡片
  @Builder
  TypeFormCard() {
    Column() {
      Row() {
        Text('类型')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
        Text('*')
          .fontSize(15)
          .fontColor(this.COLOR_PRIMARY)
          .margin({ left: 2 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      this.TypeSelector();
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 12 });
  }

  @Builder
  TypeSelector() {
    Scroll() {
      Row() {
        ForEach(this.types, (type: string): void => {
          Text(type)
            .fontSize(14)
            .fontWeight(this.selectedType === type ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.selectedType === type ? '#FFFFFF' : this.COLOR_TEXT_SECONDARY)
            .padding({ left: 18, right: 18, top: 10, bottom: 10 })
            .borderRadius(20)
            .backgroundColor(this.selectedType === type ? this.COLOR_PRIMARY : this.COLOR_BG)
            .margin({ right: 10 })
            .onClick((): void => { this.selectedType = type; });
        });
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None);
  }

  // 发布人表单卡片
  @Builder
  PublisherFormCard() {
    Column() {
      Row() {
        Text('发布人')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
      }
      .width('100%')
      .margin({ bottom: 12 });

      TextInput({ text: this.publisher, placeholder: '请输入发布人姓名或部门（可选）' })
        .width('100%')
        .height(48)
        .fontSize(15)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .backgroundColor(this.COLOR_BG)
        .borderRadius(10)
        .border({ width: 1, color: this.COLOR_DIVIDER })
        .padding({ left: 16, right: 16 })
        .onChange((value: string): void => { this.publisher = value; });
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 12 });
  }

  // 发布日期选择器卡片
  @Builder
  DateFormCard() {
    Column() {
      Row() {
        Text('发布日期')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
        Text('*')
          .fontSize(15)
          .fontColor(this.COLOR_PRIMARY)
          .margin({ left: 2 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Row() {
        Image($rawfile('时间.png'))
          .width(18)
          .height(18)
          .margin({ right: 10 });

        Text(this.publishDate)
          .fontSize(15)
          .fontColor(this.COLOR_TEXT_PRIMARY)
          .layoutWeight(1);
      }
      .width('100%')
      .height(48)
      .padding({ left: 14, right: 14 })
      .backgroundColor(this.COLOR_BG)
      .borderRadius(10)
      .border({ width: 1, color: this.COLOR_DIVIDER })
      .onClick((): void => { this.showDatePicker = true; });
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 12 });
  }

  // 封面图片表单卡片
  @Builder
  ImageFormCard() {
    Column() {
      Row() {
        Text('封面图片')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
        Text('*')
          .fontSize(15)
          .fontColor(this.COLOR_PRIMARY)
          .margin({ left: 2 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      this.ImageInputContent();
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 12 });
  }

  @Builder
  ImageInputContent() {
    Column() {
      if (this.imageUrl) {
        Image(this.imageUrl)
          .width('100%')
          .height(180)
          .objectFit(ImageFit.Cover)
          .borderRadius(10)
          .margin({ bottom: 12 });
      }

      TextInput({ text: this.imageUrl, placeholder: '请输入封面图片URL地址' })
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .backgroundColor(this.COLOR_BG)
        .borderRadius(10)
        .border({ width: 1, color: this.COLOR_DIVIDER })
        .padding({ left: 16, right: 16 })
        .onChange((value: string): void => { this.imageUrl = value; });
    }
    .width('100%');
  }

  // 视频URL表单卡片
  @Builder
  VideoFormCard() {
    Column() {
      Row() {
        Text('视频URL')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.COLOR_TEXT_PRIMARY);
      }
      .width('100%')
      .margin({ bottom: 12 });

      this.VideoInputContent();
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 12 });
  }

  @Builder
  VideoInputContent() {
    Column() {
      if (this.videoUrl) {
        this.VideoPreviewRow();
      }

      TextInput({ text: this.videoUrl, placeholder: '请输入视频URL（可选）' })
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .backgroundColor(this.COLOR_BG)
        .borderRadius(10)
        .border({ width: 1, color: this.COLOR_DIVIDER })
        .padding({ left: 16, right: 16 })
        .onChange((value: string): void => { this.videoUrl = value; });
    }
    .width('100%');
  }

  @Builder
  VideoPreviewRow() {
    Row() {
      Image($rawfile('视频.png'))
        .width(40)
        .height(40)
        .fillColor(this.COLOR_GOLD);

      Text('已添加视频')
        .fontSize(14)
        .fontColor(this.COLOR_TEXT_SECONDARY)
        .margin({ left: 12 });

      Blank();

      Text('清除')
        .fontSize(13)
        .fontColor(this.COLOR_PRIMARY)
        .onClick((): void => { this.videoUrl = ''; });
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.COLOR_BG)
    .borderRadius(10)
    .margin({ bottom: 12 });
  }

  // 内容表单卡片（图文混排）
  @Builder
  ContentFormCard() {
    Column() {
      // 标题行
      Row() {
        Row() {
          Text('内容')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY);
          Text('*')
            .fontSize(15)
            .fontColor(this.COLOR_PRIMARY)
            .margin({ left: 2 });
        }
        .layoutWeight(1);

        // 插入图片按钮
        Button() {
          Row() {
            Text('🖼')
              .fontSize(14)
              .margin({ right: 4 });
            Text('插入图片')
              .fontSize(13)
              .fontColor(this.COLOR_PRIMARY)
              .fontWeight(FontWeight.Medium);
          }
        }
        .height(32)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#FFF1F1')
        .border({ width: 1, color: '#E3B3B3' })
        .borderRadius(8)
        .onClick((): void => {
          this.pendingImgUrl = '';
          this.showImgUrlInput = true;
        });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 });

      // 格式提示
      Text('提示：正文输入文本内容，点击"插入图片"可在当前位置嵌入网络图片。')
        .fontSize(12)
        .fontColor(this.COLOR_TEXT_TERTIARY)
        .width('100%')
        .margin({ bottom: 10 });

      // 文本域
      TextArea({ text: this.content, placeholder: '请输入政策详细内容...\n\n支持多段落，图片将以 [IMG:URL] 标记插入。', controller: this.contentController })
        .width('100%')
        .height(240)
        .fontSize(15)
        .fontColor(this.COLOR_TEXT_PRIMARY)
        .backgroundColor(this.COLOR_BG)
        .borderRadius(10)
        .border({ width: 1, color: this.COLOR_DIVIDER })
        .padding(16)
        .maxLength(99999)
        .showCounter(true, { highlightBorder: false })
        .onChange((value: string): void => { this.content = value; })
        .onTextSelectionChange((selectionStart: number, selectionEnd: number): void => {
          // 记录光标（选择结束位置）用于插入
          this.caretOffset = selectionEnd;
        });

      // 内容预览区（仅当内容包含图片标记时显示）
      if (this.content.indexOf('[IMG:') !== -1) {
        Column() {
          Row() {
            Row()
              .width(3)
              .height(14)
              .borderRadius(2)
              .backgroundColor(this.COLOR_GOLD)
              .margin({ right: 8 });
            Text('图文预览')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.COLOR_TEXT_SECONDARY);
          }
          .width('100%')
          .margin({ bottom: 10 });

          this.ContentPreview();
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFCF8')
        .borderRadius(10)
        .border({ width: 1, color: '#F3EBDD' })
        .margin({ top: 12 });
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLOR_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.COLOR_DIVIDER })
    .margin({ bottom: 12 });
  }

  // 内容预览（解析图文混排）
  @Builder
  ContentPreview() {
    Column() {
      ForEach(this.parseContent(this.content), (seg: ContentSegment, idx: number): void => {
        if (seg.type === 'text' && seg.value.trim().length > 0) {
          Text(seg.value.trim())
            .fontSize(14)
            .lineHeight(22)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: 8 });
        } else if (seg.type === 'image') {
          Image(seg.value)
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .margin({ bottom: 8 });
        }
      });
    }
    .width('100%');
  }

  // 日期选择器浮层
  @Builder
  buildDatePickerOverlay() {
    Column() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick((): void => { this.showDatePicker = false; });

      // 选择器面板
      Column() {
        // 顶部标题
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .onClick((): void => { this.showDatePicker = false; });

          Text('选择发布日期')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center);

          Text('确定')
            .fontSize(16)
            .fontColor(this.COLOR_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .onClick((): void => { this.confirmDatePicker(); });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 });

        Divider().color(this.COLOR_DIVIDER);

        // 日期滚轮选择器
        DatePicker({
          start: new Date('2000-01-01'),
          end: new Date('2030-12-31'),
          selected: new Date(`${this.pickerYear}-${this.pickerMonth < 10 ? '0' + this.pickerMonth : this.pickerMonth}-${this.pickerDay < 10 ? '0' + this.pickerDay : this.pickerDay}`)
        })
          .width('100%')
          .height(220)
          .disappearTextStyle({ color: this.COLOR_TEXT_TERTIARY, font: { size: 14 } })
          .textStyle({ color: this.COLOR_TEXT_SECONDARY, font: { size: 16 } })
          .selectedTextStyle({ color: this.COLOR_PRIMARY, font: { size: 18, weight: FontWeight.Medium } })
          .onDateChange((value: Date): void => {
            this.pickerYear = value.getFullYear();
            this.pickerMonth = value.getMonth() + 1;
            this.pickerDay = value.getDate();
          });

        Row().height(16);
      }
      .width('100%')
      .backgroundColor(this.COLOR_CARD)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .position({ x: 0, y: '100%' })
      .markAnchor({ x: 0, y: '100%' });
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 });
  }

  // 插图URL输入浮层
  @Builder
  buildImgUrlOverlay() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick((): void => { this.showImgUrlInput = false; });

      Column() {
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .onClick((): void => { this.showImgUrlInput = false; });

          Text('插入图片')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center);

          Text('插入')
            .fontSize(16)
            .fontColor(this.COLOR_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .onClick((): void => { this.insertImageTag(this.pendingImgUrl); });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 });

        Divider().color(this.COLOR_DIVIDER);

        Column() {
          Text('图片网络URL')
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_SECONDARY)
            .width('100%')
            .margin({ bottom: 10 });

          TextInput({ text: this.pendingImgUrl, placeholder: 'https://example.com/image.jpg' })
            .width('100%')
            .height(48)
            .fontSize(14)
            .fontColor(this.COLOR_TEXT_PRIMARY)
            .backgroundColor(this.COLOR_BG)
            .borderRadius(10)
            .border({ width: 1, color: this.COLOR_DIVIDER })
            .padding({ left: 16, right: 16 })
            .onChange((value: string): void => { this.pendingImgUrl = value; });

          // 预览
          if (this.pendingImgUrl.trim().length > 8) {
            Image(this.pendingImgUrl.trim())
              .width('100%')
              .height(160)
              .objectFit(ImageFit.Cover)
              .borderRadius(10)
              .margin({ top: 12 });
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 24 });
      }
      .width('100%')
      .backgroundColor(this.COLOR_CARD)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .position({ x: 0, y: '100%' })
      .markAnchor({ x: 0, y: '100%' });
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 });
  }

  // 解析内容为图文分段
  parseContent(raw: string): ContentSegment[] {
    const segments: ContentSegment[] = [];
    const imgRegex = /\[IMG:(.*?)\]/g;
    let lastIndex = 0;
    let match: RegExpExecArray | null = imgRegex.exec(raw);
    while (match !== null) {
      // 图片前的文本
      if (match.index > lastIndex) {
        const textPart = raw.substring(lastIndex, match.index);
        if (textPart.length > 0) {
          const seg: ContentSegment = { type: 'text', value: textPart };
          segments.push(seg);
        }
      }
      // 图片
      const imgSeg: ContentSegment = { type: 'image', value: match[1] };
      segments.push(imgSeg);
      lastIndex = match.index + match[0].length;
      match = imgRegex.exec(raw);
    }
    // 末尾文本
    if (lastIndex < raw.length) {
      const tail = raw.substring(lastIndex);
      if (tail.length > 0) {
        const tailSeg: ContentSegment = { type: 'text', value: tail };
        segments.push(tailSeg);
      }
    }
    return segments;
  }
}

// 内容段类型
interface ContentSegment {
  type: 'text' | 'image';
  value: string;
}
