# PartyApp 项目长期记忆

## 项目概述
- HarmonyOS ArkTS 党建应用，已升级到 API 21（HarmonyOS 6.0.1）
- 前端：DevEco Studio，ArkTS + ArkUI
- 后端：Java Spring Boot（`backend/` 目录）
- 数据库：MySQL
- `build-profile.json5` 中 targetSdkVersion 和 compatibleSdkVersion 均为 `"6.0.1(21)"`（2026-03-31 升级）

## 设计规范
### 正式类页面视觉偏好（2026-04-01 更新）
用户当前更偏好“庄重红金正式风”，强调页面成熟度、层级感和精致留白；避免科技风与花哨霓虹效果。
- **整体基调**：正式、稳重、干净、有品质感
- **主色**：绛红 `#B51F2E`，亮红 `#D83A34`
- **点缀色**：暖金 `#C9A45C`，深金 `#A67C2E`
- **背景色**：米白 `#F7F4EF`，卡片白 `#FFFFFF`
- **文字主色**：`#1F1F1F`，副色 `#666666`，弱色 `#999999`
- **设计重点**：更强的信息层级、规整留白、精致分区、统一按钮体系、轻量阴影、移动端优先避免头部拥挤与操作误触
- **移动端按钮偏好**：关键主操作优先用清晰文字按钮；编辑/删除等次级操作可用图标+文字，但不建议只用纯图标
- **文案偏好**：减少“精致版”“更正式的层级”这类装饰性自述文案，界面文案要直接、克制、产品化
- **避免方向**：科技蓝、霓虹光效、深色赛博风、过度装饰

## 已美化的页面
- `ActivityPage.ets`（2026-04-01）- 庄重红金正式风（增强层级与质感版）
- `ActivityDetailPage.ets`（2026-04-01）- 庄重红金正式风（封面+分区卡片+底部操作栏统一版）
- `ActivityParticipantsPage.ets`（2026-04-01）- 庄重红金正式风（渐变顶栏+摘要条+卡片列表+空态）
- `ActivityEditPage.ets`（2026-04-01）- 庄重红金正式风（渐变顶栏+FormCard+悬浮保存按钮+时间选择浮层）
- `HomePage.ets`（2026-04-01）- 庄重红金正式风（米白背景+金色边框卡片+绛红强调色+统一搜索栏）

## 项目结构关键路径
- 页面：`entry/src/main/ets/pages/`
- 模型：`entry/src/main/ets/models/`
- 服务：`entry/src/main/ets/services/`
- 静态资源：`entry/src/main/resources/rawfile/`

## 学习模块最新改动（2026-04-13）
- `StudyTopicEditPage.ets`：封面点击直接输入URL，弹窗虚化背景，子资源弹窗所有字段统一"名称+输入框"格式；专题标题加载时加 `|| ''` 兜底
- `StudyEditPage.ets`：`TypeCard` 替换为 `TypeFixedCard`，类型固定为"党史学习"不可切换；移除顶部右上角上传按钮
- `StudyPage.ets`：右上角上传按钮移除；专题学习列表增加"编辑专题"切换按钮（管理员可见），点击后进入编辑模式，专题卡片显示"点击编辑"并可整行点击进入编辑页；党史学习列表右上角新增"上传资源"按钮（仅管理员）

## ArkTS 编译限制备忘
- `@Builder` 不支持函数类型参数（`content: () => void`），每个卡片应独立写 `@Builder`
- Lambda 内部不能写带链式属性的 UI 表达式（`Row(){...}.width(...)`）
- UI 组件名（如 `Column`）是值不是类型，不能用作类型注解
- `fillColor` 对 PNG 图片无效（只对矢量图有效）；深色背景上的返回按钮建议用白色文字 `‹`
- `markAnchor` + `offset` 高级定位 API 在 API 21 上行为可能不可靠，底部悬浮元素推荐用 `Stack({ alignContent: Alignment.Bottom })`
- **扇形图实现**：`Canvas` API 和 `SVG data URI` 在 HarmonyOS 上不可靠，改用 `Path` 组件的 `commands` 属性绘制真正的扇形
- 对象字面量数组需要显式声明接口类型（如 `const arr: MyInterface[] = [...]`）
