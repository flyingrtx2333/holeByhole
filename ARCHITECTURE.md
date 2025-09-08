# holeByhole App Architecture

## 应用架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    holeByhole App                           │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI Views)                        │
├─────────────────────────────────────────────────────────────┤
│  • HomeView          • CourseListView    • StatsView       │
│  • NewRoundView      • VideoRecordingView • SettingsView   │
│  • VideoPlaybackView • HoleDiaryView     • CourseDetailView│
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (ViewModels & Managers)              │
├─────────────────────────────────────────────────────────────┤
│  • CameraManager     • VideoPlayerManager                  │
│  • LocalizationManager                                     │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (SwiftData Models)                             │
├─────────────────────────────────────────────────────────────┤
│  • GolfCourse        • GolfHole          • GolfVideo       │
│  • VideoKeyFrame     • ClubType          • ShotType        │
├─────────────────────────────────────────────────────────────┤
│  System Layer (iOS Frameworks)                             │
├─────────────────────────────────────────────────────────────┤
│  • SwiftData         • AVFoundation      • Photos          │
│  • SwiftUI           • Foundation        • UIKit           │
└─────────────────────────────────────────────────────────────┘
```

## 数据流

```
User Input → View → ViewModel → Manager → Data Model → SwiftData
     ↑                                                      ↓
User Interface ← View ← ViewModel ← Manager ← Data Model ←──┘
```

## 核心功能模块

### 1. 球场管理模块
- **CourseListView**: 球场列表展示
- **CourseDetailView**: 球场详情和统计
- **AddCourseView**: 添加新球场
- **GolfCourse Model**: 球场数据模型

### 2. 视频录制模块
- **VideoRecordingView**: 视频录制界面
- **CameraManager**: 相机控制和录制管理
- **VideoSaveOptionsView**: 视频保存选项
- **GolfVideo Model**: 视频数据模型

### 3. 视频播放模块
- **VideoPlaybackView**: 视频播放界面
- **VideoPlayerManager**: 视频播放控制
- **KeyFrameEditorView**: 关键帧编辑
- **VideoKeyFrame Model**: 关键帧数据模型

### 4. 数据统计模块
- **StatsView**: 统计展示界面
- **OverviewStatsView**: 概览统计
- **ScoreDistributionView**: 成绩分布图表
- **PerformanceByHoleView**: 各洞表现分析

### 5. 个人日记模块
- **HoleDiaryView**: 日记列表
- **HoleRecordDetailView**: 记录详情
- **EditHoleView**: 编辑记录
- **GolfHole Model**: 球洞数据模型

## 技术特点

### MVVM架构
- **Model**: SwiftData数据模型
- **View**: SwiftUI视图
- **ViewModel**: 视图逻辑处理

### 数据持久化
- 使用SwiftData进行本地数据存储
- 支持关系型数据模型
- 自动数据同步和更新

### 视频处理
- AVFoundation框架进行视频录制
- 支持前后摄像头切换
- 自动缩略图生成
- 多倍速播放支持

### 本地化支持
- 支持中英文双语
- 动态语言切换
- 系统语言跟随

### 主题支持
- 浅色/深色主题
- 系统主题跟随
- 动态主题切换

## 文件组织

```
holeByhole/
├── Models/
│   └── Models.swift              # 所有数据模型
├── Views/
│   ├── HomeView.swift            # 首页
│   ├── CourseListView.swift      # 球场列表
│   ├── CourseDetailView.swift    # 球场详情
│   ├── NewRoundView.swift        # 新轮次
│   ├── VideoRecordingView.swift  # 视频录制
│   ├── VideoPlaybackView.swift   # 视频播放
│   ├── StatsView.swift           # 统计页面
│   ├── SettingsView.swift        # 设置页面
│   └── ...                       # 其他视图
├── Managers/
│   ├── CameraManager.swift       # 相机管理
│   ├── VideoPlayerManager.swift  # 视频播放管理
│   └── LocalizationManager.swift # 本地化管理
├── Localization/
│   ├── Localizable.strings       # 英文本地化
│   └── zh-Hans.lproj/            # 中文本地化
└── Assets.xcassets/              # 资源文件
```

## 性能优化

### 内存管理
- 视频播放器的及时释放
- 图片和视频的异步加载
- 数据模型的懒加载

### 存储优化
- 视频文件的压缩存储
- 缩略图的智能生成
- 数据的分页加载

### 用户体验
- 流畅的动画过渡
- 响应式界面设计
- 错误处理和用户反馈

## 扩展性设计

### 模块化架构
- 各功能模块独立开发
- 清晰的接口定义
- 易于功能扩展

### 数据模型扩展
- 支持新字段添加
- 版本兼容性处理
- 数据迁移支持

### 国际化扩展
- 支持新语言添加
- 本地化资源管理
- 文化适配支持
