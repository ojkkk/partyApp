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

  // 监控 currentIndex 变化
  onCurrentIndexChange() {
    console.log('currentIndex changed:', this.currentIndex);
    promptAction.showToast({
      message: `切换到页面: ${this.pages[this.currentIndex]?.name}`,
      duration: 1000
    });
  }

  build() {
    Column() {
      // 页面内容
      Column() {
        if (this.currentIndex === 0) {
          HomePage()
            .width('100%')
            .height('100%')
        } else if (this.currentIndex === 1) {
          PolicyPage()
            .width('100%')
            .height('100%')
        } else if (this.currentIndex === 2) {
          StudyPage()
            .width('100%')
            .height('100%')
        } else if (this.currentIndex === 3) {
          ActivityPage()
            .width('100%')
            .height('100%')
        } else if (this.currentIndex === 4) {
          ProfilePage()
            .width('100%')
            .height('100%')
        }
      }
      .flexGrow(1)

      // 底部导航栏
      NavigationBar({
        items: this.pages,
        currentIndex: $currentIndex
      })
        .margin({ top: -30 })
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
}