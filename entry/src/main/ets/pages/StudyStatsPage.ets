import { StudyService, LearningDistribution, BranchAverage } from '../models/StudyModel';
import { ApiResponse, UserInfo } from '../models/UserModel';
import { StorageService } from '../services/StorageService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  PieChartModel,
  PieEntry,
  PieDataSet,
  PieData,
  JArrayList,
  ColorTemplate,
  Legend,
  PieChart,
  ValuePosition,
  IValueFormatter,
  EntryOhos,
  ViewPortHandler
} from '@ohos/mpchart';

// 自定义百分比格式化器（保留一位小数 + %）
class PercentValueFormatter implements IValueFormatter {
  getFormattedValue(value: number, entry: EntryOhos, dataSetIndex: number, viewPortHandler: ViewPortHandler): string {
    return value.toFixed(1) + '%';
  }
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
export struct StudyStatsPage {
  private studyService: StudyService = new StudyService();
  @State isLoading: boolean = false;
  @State userRole: string = '';
  @State userBranch: string = '';
  @State userId: string = '';

  // 个人数据
  @State myDistribution: LearningDistribution | null = null;
  @State myProgress: number = 0;
  @State myDuration: number = 0;
  @State branchAvg: BranchAverage | null = null;

  // 总统计数据
  @State totalCourses: number = 0;
  @State completedCourses: number = 0;
  @State myDurationMinutes: number = 0;

  // 饼图相关
  private pieChartModel: PieChartModel | null = null;

  aboutToAppear() {
    this.initPieChartModel();
    this.checkUserRole();
    this.loadData();
  }

  // 初始化饼图模型
  initPieChartModel() {
    this.pieChartModel = new PieChartModel();
    this.pieChartModel.setUsePercentValues(true);
    this.pieChartModel.setDrawHoleEnabled(false); // 实心饼图
    this.pieChartModel.setDrawEntryLabels(false);
    const desc = this.pieChartModel.getDescription();
    if (desc) {
      desc.setEnabled(false);
    }
  }

  // 更新饼图数据
  updatePieChartData() {
    if (!this.pieChartModel || !this.myDistribution) return;

    const entries: JArrayList<PieEntry> = new JArrayList<PieEntry>();
    entries.add(new PieEntry(this.myDistribution.completed, '已完成'));
    entries.add(new PieEntry(this.myDistribution.inProgress, '学习中'));
    entries.add(new PieEntry(this.myDistribution.notStarted, '未学习'));

    const dataSet: PieDataSet = new PieDataSet(entries, '学习状态');
    
    // 设置颜色
    const colors: JArrayList<number> = new JArrayList<number>();
    colors.add(0xFFB51F2E); // 绛红 - 已完成
    colors.add(0xFFD83A34); // 亮红 - 学习中
    colors.add(0xFFCCCCCC); // 灰色 - 未学习
    dataSet.setColorsByList(colors);
    
    dataSet.setSliceSpace(2);
    dataSet.setDrawValues(true);
    dataSet.setValueTextSize(14); // 增大文字
    
    // 百分比文字颜色设为黑色
    dataSet.setValueTextColor(0xFF1F1F1F);
    
    // 使用百分比格式化器（加%号）
    dataSet.setValueFormatter(new PercentValueFormatter());
    
    // 设置标签位置为外部（带折线）
    dataSet.setXValuePosition(ValuePosition.OUTSIDE_SLICE);
    dataSet.setYValuePosition(ValuePosition.OUTSIDE_SLICE);
    
    // 折线设置 - 确保折线伸出饼图
    dataSet.setValueLineColor(0xFF888888); // 折线颜色
    dataSet.setValueLineWidth(1.2); // 折线宽度
    dataSet.setValueLinePart1OffsetPercentage(100); // 折线起点在饼图外
    dataSet.setValueLinePart1Length(0.6); // 折线第一段长度
    dataSet.setValueLinePart2Length(0.8); // 折线第二段长度
    dataSet.setValueLineVariableLength(true); // 允许折线长度可变

    const pieData: PieData = new PieData(dataSet);
    this.pieChartModel.setData(pieData);

    // 图例设置
    const legend: Legend | null = this.pieChartModel.getLegend();
    if (legend) {
      legend.setEnabled(false);
    }
  }

  async checkUserRole() {
    const userInfo = await StorageService.getItemAsync<UserInfo>('user');
    if (userInfo) {
      this.userRole = userInfo.role;
      this.userBranch = userInfo.branch;
      this.userId = userInfo.id || '';
    }
  }

  async loadData() {
    await this.loadPersonalStats();
  }

  async loadPersonalStats() {
    this.isLoading = true;
    try {
      // 串行加载，避免解构赋值问题
      const distRes = await this.studyService.getMyLearningDistribution();
      const branchRes = await this.studyService.getBranchAverage();
      const statsRes = await this.studyService.getStudyStats();

      if (distRes.code === 200 && distRes.data) {
        this.myDistribution = distRes.data;
        this.updatePieChartData();
      }
      if (branchRes.code === 200 && branchRes.data) {
        this.branchAvg = branchRes.data;
      }
      if (statsRes.code === 200 && statsRes.data) {
        this.myProgress = statsRes.data.totalProgress;
        this.myDurationMinutes = statsRes.data.totalDuration;
        this.totalCourses = statsRes.data.totalCourses;
        this.completedCourses = statsRes.data.completedCourses;
      }
    } catch (error) {
      console.error('加载个人学习统计失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 获取支部对比差距
  getProgressDiff(): number {
    return this.myProgress - (this.branchAvg?.avgProgress || 0);
  }

  // 【原生饼图组件】使用 @ohos/mpchart 绘制饼图
  @Builder
  PieChartView() {
    Column() {
      // 饼图主体：使用原生 mpchart 组件
      Row() {
        if (this.pieChartModel) {
          PieChart({ model: this.pieChartModel })
            .width(280)
            .height(280)
        } else {
          // 加载中显示占位
          Circle()
            .width(280)
            .height(280)
            .fill('#E8E8E8')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      // 图例
      Row({ space: 36 }) {
        Row({ space: 6 }) {
          Circle().width(14).height(14).fill('#B51F2E');
          Text('已完成 ' + (this.myDistribution?.completed || 0)).fontSize(15).fontColor('#666');
        }
        Row({ space: 6 }) {
          Circle().width(14).height(14).fill('#D83A34');
          Text('学习中 ' + (this.myDistribution?.inProgress || 0)).fontSize(15).fontColor('#666');
        }
        Row({ space: 6 }) {
          Circle().width(14).height(14).fill('#CCCCCC');
          Text('未学习 ' + (this.myDistribution?.notStarted || 0)).fontSize(15).fontColor('#666');
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 12, bottom: 20, left: 16, right: 16 })
  }

  // 支部对比视图
  @Builder
  BranchComparisonView() {
    Column() {
      Text('学习进度对比')
        .fontSize(15)
        .fontWeight(700)
        .fontColor('#1F1F1F')
        .margin({ bottom: 16 });

      // 我的进度
      Row() {
        Text('我的进度')
          .fontSize(13)
          .fontColor('#666666')
          .width(70);
        Column() {
          Row() {
            Column()
              .width(this.myProgress + '%')
              .height(20)
              .backgroundColor('#B51F2E')
              .borderRadius(4);
            Blank();
            Text(this.myProgress + '%')
              .fontSize(13)
              .fontColor('#B51F2E')
              .fontWeight(600);
          }
          .width('100%');
        }
        .layoutWeight(1);
      }
      .margin({ bottom: 10 });

      // 支部平均
      Row() {
        Text('支部平均')
          .fontSize(13)
          .fontColor('#666666')
          .width(70);
        Column() {
          Row() {
            Column()
              .width((this.branchAvg?.avgProgress || 0) + '%')
              .height(20)
              .backgroundColor('#C9A45C')
              .borderRadius(4);
            Blank();
            Text((this.branchAvg?.avgProgress || 0) + '%')
              .fontSize(13)
              .fontColor('#C9A45C')
              .fontWeight(600);
          }
          .width('100%');
        }
        .layoutWeight(1);
      }
      .margin({ bottom: 16 });

      // 对比结论
      Row() {
        if (this.getProgressDiff() > 0) {
          Text('🟢 领先支部平均 ' + this.getProgressDiff() + '%')
            .fontSize(12)
            .fontColor('#2E7D32')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#E8F5E9')
            .borderRadius(12);
        } else if (this.getProgressDiff() < 0) {
          Text('🟡 落后支部平均 ' + Math.abs(this.getProgressDiff()) + '%')
            .fontSize(12)
            .fontColor('#F57C00')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#FFF3E0')
            .borderRadius(12);
        } else {
          Text('🟡 与支部平均水平持平')
            .fontSize(12)
            .fontColor('#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#F5F5F5')
            .borderRadius(12);
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .border({ width: 1, color: '#EFE7DB' });
  }

  // 个人统计卡片
  @Builder
  PersonalStatsCard() {
    Column() {
      Row() {
        Row() {
          Row()
            .width(4)
            .height(14)
            .borderRadius(2)
            .backgroundColor('#B51F2E')
            .margin({ right: 8 });
          Text('我的学习')
            .fontSize(15)
            .fontWeight(700)
            .fontColor('#1F1F1F');
        }
        .flexGrow(1);

        Text(this.userBranch)
          .fontSize(11)
          .fontColor('#B51F2E')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor('#FFF1F1')
          .borderRadius(10);
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Column() {
          Text(this.totalCourses.toString())
            .fontSize(20)
            .fontWeight(700)
            .fontColor('#B51F2E');
          Text('总课程')
            .fontSize(11)
            .fontColor('#999999');
        }
        .flexGrow(1);

        Column() {
          Text(this.completedCourses.toString())
            .fontSize(20)
            .fontWeight(700)
            .fontColor('#B51F2E');
          Text('已完成')
            .fontSize(11)
            .fontColor('#999999');
        }
        .flexGrow(1);

        Column() {
          Text(this.myDurationMinutes + '分钟')
            .fontSize(20)
            .fontWeight(700)
            .fontColor('#B51F2E');
          Text('学习时长')
            .fontSize(11)
            .fontColor('#999999');
        }
        .flexGrow(1);

        Column() {
          Text(this.myProgress + '%')
            .fontSize(20)
            .fontWeight(700)
            .fontColor('#B51F2E');
          Text('总进度')
            .fontSize(11)
            .fontColor('#999999');
        }
        .flexGrow(1);
      }
      .width('100%');
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .border({ width: 1, color: '#EFE7DB' });
  }

  build() {
    Column() {
      // ===================== 【顶栏】 =====================
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .margin({ right: 8, bottom: 6 })
          .onClick(() => router.back());

        Text('我的学习')
          .fontSize(18)
          .fontWeight(700)
          .fontColor('#FFFFFF');
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#B51F2E')
      .alignItems(VerticalAlign.Center);

      // ===================== 【内容区】 =====================
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#B51F2E');
        }
        .width('100%')
        .flexGrow(1)
        .justifyContent(FlexAlign.Center);
      } else {
        // ===================== 【个人学习统计视图】 =====================
        Scroll() {
          Column({ space: 12 }) {
            // 学习状态扇形图卡片
            Column() {
              Text('学习状态分布')
                .fontSize(18)
                .fontWeight(700)
                .fontColor('#1F1F1F')
                .margin({ bottom: 16, top: 8 });

              this.PieChartView();
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .border({ width: 1, color: '#EFE7DB' })
            .margin({ left: 12, right: 12, top: 12 });

            // 个人统计卡片
            Column() {
              this.PersonalStatsCard()
            }
            .margin({ left: 12, right: 12 });

            // 支部对比卡片
            Column() {
              this.BranchComparisonView()
            }
            .margin({ left: 12, right: 12 });

            // 学习建议卡片
            Column() {
              Row() {
                Row()
                  .width(4)
                  .height(14)
                  .borderRadius(2)
                  .backgroundColor('#C9A45C')
                  .margin({ right: 8 });
                Text('学习建议')
                  .fontSize(15)
                  .fontWeight(700)
                  .fontColor('#1F1F1F');
              }
              .width('100%')
              .margin({ bottom: 12 });

              if (this.myDistribution && this.myDistribution.notStarted > 0) {
                Row() {
                  Image($rawfile('书本.png'))
                    .width(24)
                    .height(24)
                    .margin({ right: 10 });
                  Column() {
                    Text('您有 ' + this.myDistribution.notStarted + ' 个资源尚未开始学习')
                      .fontSize(13)
                      .fontColor('#333333')
                      .width('100%');
                    Text('建议从感兴趣的内容开始，逐步提升学习进度')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 2 })
                      .width('100%');
                  }
                  .alignItems(HorizontalAlign.Start);
                }
                .width('100%')
                .alignItems(VerticalAlign.Top);
              }

              if (this.getProgressDiff() < 0) {
                Row() {
                  Text('💪')
                    .fontSize(18)
                    .margin({ right: 10 });
                  Column() {
                    Text('您的学习进度落后于支部平均')
                      .fontSize(13)
                      .fontColor('#333333')
                      .width('100%');
                    Text('建议加强学习，争取迎头赶上')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 2 })
                      .width('100%');
                  }
                  .alignItems(HorizontalAlign.Start);
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .margin({ top: 12 });
              }

              if (this.myDistribution && this.myDistribution.inProgress > 0) {
                Row() {
                  Image($rawfile('闹钟.png'))
                    .width(24)
                    .height(24)
                    .margin({ right: 10 });
                  Column() {
                    Text('您有 ' + this.myDistribution.inProgress + ' 个资源正在学习')
                      .fontSize(13)
                      .fontColor('#333333')
                      .width('100%');
                    Text('记得抽空完成，避免学习进度中断')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 2 })
                      .width('100%');
                  }
                  .alignItems(HorizontalAlign.Start);
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .margin({ top: 12 });
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .border({ width: 1, color: '#EFE7DB' })
            .margin({ left: 12, right: 12 });

            Blank().height(20);
          }
          .padding({ top: 10, bottom: 20 });
        }
        .width('100%')
        .flexGrow(1)
        .backgroundColor('#F7F4EF')
        .align(Alignment.TopStart);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4EF');
  }
}