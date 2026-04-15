import { NavigationBar, NavigationItem } from '../components/NavigationBar';
import { HomePage } from '../pages/HomePage';
import { PolicyPage } from '../pages/PolicyPage';
import { StudyPage } from '../pages/StudyPage';
import { ActivityPage } from '../pages/ActivityPage';
import { ProfilePage } from '../pages/ProfilePage';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Index {
  @State @Watch('onCurrentIndexChange') currentIndex: number = 0;

  // 颜色配置 - 庄重红金正式风
  private readonly COLOR_BG = '#F7F4EF';  // 米白背景

  private pages: Array<NavigationItem> = [
    { name: '首页', icon: $rawfile('首页.png'), component: HomePage },
    { name: '政策宣传', icon: $rawfile('新闻.png'), component: PolicyPage },
    { name: '学习园地', icon: $rawfile('学习.png'), component: StudyPage },
    { name: '活动管理', icon: $rawfile('活动.png'), component: ActivityPage },
    { name: '个人中心', icon: $rawfile('个人中心.png'), component: ProfilePage }
  ];

  aboutToAppear() {
    console.log('Index aboutToAppear, currentIndex:', this.currentIndex);
  }

  onCurrentIndexChange() {
    console.log('currentIndex changed:', this.currentIndex);
    promptAction.showToast({
      message: `切换到: ${this.pages[this.currentIndex]?.name}`,
      duration: 800
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 页面内容区域
      Column() {
        if (this.currentIndex === 0) {
          HomePage()
        } else if (this.currentIndex === 1) {
          PolicyPage()
        } else if (this.currentIndex === 2) {
          StudyPage()
        } else if (this.currentIndex === 3) {
          ActivityPage()
        } else if (this.currentIndex === 4) {
          ProfilePage()
        }
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 36 })  // 为底部导航栏留出空间
      .backgroundColor(this.COLOR_BG)

      // 底部导航栏
      NavigationBar({
        items: this.pages,
        currentIndex: $currentIndex
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.COLOR_BG)
  }
}
