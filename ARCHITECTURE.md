# holeByhole App Architecture

## 应用架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    “一洞一记” App                           │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI Views)                        │
├─────────────────────────────────────────────────────────────┤
│  • HomeView          • CourseListView    • StatsView       │
│  • NewRoundView      • VideoRecordingView • SettingsView   │
│  • VideoPlaybackView • HoleDiaryView     • CourseDetailView│
│  • KeyFrameEditorView • AddCourseView    • EditCourseView  │
│  • NewHoleView       • EditHoleView      • HoleDetailView  │
│  • VideoSaveOptionsView • HoleRecordDetailView             │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (Managers & Extensions)              │
├─────────────────────────────────────────────────────────────┤
│  • CameraManager     • VideoPlayerManager                  │
│  • LocalizationManager • AppFileManager                    │
│  • ScoreColorExtension                                     │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (SwiftData Models)                             │
├─────────────────────────────────────────────────────────────┤
│  • GolfCourse        • GolfHole          • GolfVideo       │
│  • VideoKeyFrame     • HoleSide          • ClubType        │
│  • ShotType          • TimeRange                          │
├─────────────────────────────────────────────────────────────┤
│  System Layer (iOS Frameworks)                             │
├─────────────────────────────────────────────────────────────┤
│  • SwiftData         • AVFoundation      • Photos          │
│  • SwiftUI           • Foundation        • UIKit           │
│  • Charts            • Combine           • CoreData        │
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
- **CourseListView**: 球场列表展示，支持搜索和删除
- **CourseDetailView**: 球场详情和统计信息
- **AddCourseView**: 添加新球场界面
- **EditCourseView**: 编辑球场信息
- **GolfCourse Model**: 球场数据模型，包含名称、位置、自定义标识

### 2. 视频录制模块
- **VideoRecordingView**: 视频录制界面，支持前后摄像头切换
- **CameraManager**: 相机控制和录制管理，处理权限和会话
- **VideoSaveOptionsView**: 视频保存选项界面
- **GolfVideo Model**: 视频数据模型，包含文件路径、缩略图、球杆类型等

### 3. 视频播放模块
- **VideoPlaybackView**: 视频播放界面，支持多倍速播放
- **VideoPlayerManager**: 视频播放控制，使用AVPlayer
- **KeyFrameEditorView**: 关键帧编辑界面
- **VideoKeyFrame Model**: 关键帧数据模型，包含时间戳和描述

### 4. 数据统计模块
- **StatsView**: 统计展示界面，支持时间范围和球场筛选
- **OverviewStatsView**: 概览统计卡片
- **ScoreDistributionView**: 成绩分布图表，使用Charts框架
- **PerformanceByHoleView**: 各洞表现分析
- **ClubUsageView**: 球杆使用统计
- **RecentPerformanceView**: 最近表现记录

### 5. 个人日记模块
- **HoleDiaryView**: 日记列表，显示所有球洞记录
- **HoleRecordDetailView**: 记录详情界面
- **EditHoleView**: 编辑记录界面
- **NewHoleView**: 新建球洞记录
- **HoleDetailView**: 球洞详情界面
- **GolfHole Model**: 球洞数据模型，支持前后9洞分类

### 6. 系统管理模块
- **HomeView**: 首页，显示欢迎信息和最近活动
- **SettingsView**: 设置界面
- **NewRoundView**: 新轮次开始界面
- **CourseSelectionView**: 球场选择界面

## 技术特点

### MVVM架构
- **Model**: SwiftData数据模型，包含GolfCourse、GolfHole、GolfVideo、VideoKeyFrame
- **View**: SwiftUI视图，响应式UI设计
- **Manager**: 业务逻辑管理器，处理相机、视频播放、文件管理等

### 数据持久化
- 使用SwiftData进行本地数据存储
- 支持关系型数据模型（球场-球洞-视频-关键帧）
- 自动数据同步和更新
- 数据迁移支持（AppFileManager.fixVideoPaths）

### 视频处理
- AVFoundation框架进行视频录制和播放
- 支持前后摄像头切换
- 自动缩略图生成和存储
- 多倍速播放支持（0.25x-2x）
- 关键帧标记和编辑功能

### 文件管理
- AppFileManager统一管理视频和缩略图文件
- 自动创建目录结构（Videos、Thumbnails）
- 文件路径迁移和修复
- 存储空间统计和清理

### 本地化支持
- 支持中英文双语（en.lproj、zh-Hans.lproj）
- LocalizationManager动态语言切换
- 系统语言跟随
- 字符串扩展.localized简化使用

### 统计和图表
- 使用Charts框架展示数据可视化
- 成绩分布柱状图
- 各洞表现分析
- 球杆使用统计
- 时间范围筛选（全部、最近一周、一月、一年）

## 文件组织

```
holeByhole/
├── Item.swift                    # 所有数据模型（GolfCourse、GolfHole、GolfVideo、VideoKeyFrame）
├── holeByholeApp.swift           # 应用入口和SwiftData配置
├── ContentView.swift             # 主TabView容器
├── Views/
│   ├── HomeView.swift            # 首页
│   ├── CourseListView.swift      # 球场列表
│   ├── CourseDetailView.swift    # 球场详情
│   ├── AddCourseView.swift       # 添加球场
│   ├── EditCourseView.swift      # 编辑球场
│   ├── NewRoundView.swift        # 新轮次
│   ├── CourseSelectionView.swift # 球场选择
│   ├── VideoRecordingView.swift  # 视频录制
│   ├── VideoPlaybackView.swift   # 视频播放
│   ├── VideoSaveOptionsView.swift # 视频保存选项
│   ├── KeyFrameEditorView.swift  # 关键帧编辑
│   ├── StatsView.swift           # 统计页面
│   ├── HoleDiaryView.swift       # 球洞日记
│   ├── HoleDetailView.swift      # 球洞详情
│   ├── HoleRecordDetailView.swift # 记录详情
│   ├── NewHoleView.swift         # 新建球洞
│   ├── EditHoleView.swift        # 编辑球洞
│   └── SettingsView.swift        # 设置页面
├── Managers/
│   ├── CameraManager.swift       # 相机管理
│   ├── VideoPlayerManager.swift  # 视频播放管理
│   ├── LocalizationManager.swift # 本地化管理
│   └── FileManager.swift         # 文件管理
├── Extensions/
│   └── ScoreColorExtension.swift # 成绩颜色扩展
├── en.lproj/
│   └── Localizable.strings       # 英文本地化
├── zh-Hans.lproj/
│   └── Localizable.strings       # 中文本地化
└── Assets.xcassets/              # 资源文件
```

## 性能优化

### 内存管理
- VideoPlayerManager的cleanup方法及时释放资源
- 图片和视频的异步加载
- SwiftData的懒加载查询
- Combine框架的cancellables管理

### 存储优化
- AppFileManager统一管理文件存储
- 缩略图的JPEG压缩存储（0.8质量）
- 视频文件按时间戳命名避免冲突
- 数据迁移和路径修复机制

### 用户体验
- SwiftUI的流畅动画过渡
- 响应式界面设计
- 错误处理和用户反馈
- 搜索和筛选功能
- 多倍速视频播放

## 扩展性设计

### 模块化架构
- 各功能模块独立开发（球场、视频、统计、日记）
- Manager模式提供清晰的接口定义
- SwiftUI视图组件化设计
- 易于功能扩展和维护

### 数据模型扩展
- SwiftData支持新字段添加
- 枚举类型扩展（ClubType、ShotType、HoleSide）
- 数据迁移支持（AppFileManager.fixVideoPaths）
- 关系型数据模型设计

### 国际化扩展
- LocalizationManager支持新语言添加
- 本地化资源管理（.lproj目录）
- 字符串扩展.localized简化使用
- 文化适配支持

### 功能扩展点
- 新的球杆类型和击球类型
- 更多统计图表类型
- 视频编辑功能
- 社交分享功能
- 云端同步支持
