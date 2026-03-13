# Simple Live App

基于 Flutter 开发的跨平台直播聚合客户端，支持多种直播平台，提供清爽的观看体验和丰富的功能。

## ✨ 主要特性

- **多平台聚合**：支持 **哔哩哔哩 (Bilibili)**、**斗鱼 (Douyu)**、**虎牙 (Huya)**、**抖音 (Douyin)** 等主流直播平台。
- **跨平台支持**：完美运行于 **Windows**、**Android**，并支持 Linux (实验性)。
- **沉浸式播放体验**：
  - 基于 `media_kit` 的高性能播放器。
  - 支持多清晰度切换、硬件解码。
  - **弹幕系统**：支持实时弹幕显示、自定义样式（大小、透明度、速度）、关键词屏蔽。
- **AI 实时字幕**：
  - 内置本地语音识别模型（Sherpa ONNX），无需联网即可生成实时字幕。
  - 支持在线 WebSocket API 识别。
  - **透明浮窗模式**：支持“幽灵窗口”模式，在桌面顶层透明显示画面与字幕，工作摸鱼两不误。
- **数据同步**：
  - 支持 **WebDAV** 云端同步关注列表与观看历史。
  - 支持局域网内二维码扫码快速同步。
- **个性化设置**：
  - 主题色切换、深色模式支持。
  - 自动定时关闭（睡眠模式）。
  - 界面布局自定义。

## 🛠️ 开发与构建

### 环境要求
- Flutter SDK: `>=3.0.5 <4.0.0`
- Dart SDK: 配套版本

### 运行步骤

```powershell
# 1. 克隆项目
git clone https://github.com/your-repo/simple_live_app.git
cd simple_live_app

# 2. 安装依赖
flutter pub get

# 3. 运行应用
# Windows
flutter run -d windows
# Android
flutter run -d android
```

### 构建发布包

```powershell
# Windows
flutter build windows --release

# Android
flutter build apk --release
# 或者构建 AppBundle
flutter build appbundle --release
```

## 🔑 签名配置 (Android)

如果你需要构建签名的 Android release 包，请参考以下命令生成密钥库：

```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

默认配置参考：
- 密钥库口令：`123456`
- 别名：`upload`
- 密码：`123456`
- CN=wind, OU=sfqy, O=Unknown, L=Unknown, ST=Unknown, C=Unknown

## � 项目结构

项目采用标准的 Flutter 项目结构，主要目录说明如下：

```
simple_live_app/
├── android/            # Android 平台相关代码和配置
│   ├── app/            # Android 应用代码
│   └── gradle/         # Gradle 配置文件
├── assets/             # 静态资源文件
│   ├── icons/          # 应用图标
│   ├── images/         # 图片资源
│   ├── lotties/        # Lottie 动画文件
│   └── logo.*          # 应用 logo 文件
├── ios/                # iOS 平台相关代码和配置
│   ├── Flutter/        # Flutter 相关配置
│   ├── Runner/         # iOS 应用代码
│   └── Runner.xcodeproj/ # Xcode 项目文件
├── lib/                # Dart 源代码
│   ├── app/            # 应用核心配置和工具
│   │   ├── controller/ # 应用控制器
│   │   └── utils/      # 工具类
│   ├── modules/        # 功能模块
│   │   ├── category/   # 分类模块
│   │   ├── follow_user/ # 关注用户模块
│   │   ├── home/       # 首页模块
│   │   ├── indexed/    # 索引模块
│   │   ├── live_room/  # 直播间模块
│   │   ├── mine/       # 个人中心模块
│   │   ├── search/     # 搜索模块
│   │   ├── settings/   # 设置模块
│   │   └── sync/       # 同步模块
│   ├── requests/       # 网络请求相关
│   ├── routes/         # 路由配置
│   ├── services/       # 服务类
│   └── main.dart       # 应用入口文件
├── .fvmrc              # FVM 配置文件
├── .gitignore          # Git 忽略文件
├── README.md           # 项目说明文档
├── analysis_options.yaml # 代码分析配置
└── distribute_options.yaml # 分发配置
```

### 核心模块说明

- **app/**: 应用核心配置和工具类，包含应用样式、常量定义、事件总线等
- **modules/**: 功能模块集合，每个模块包含对应的页面和控制器
- **requests/**: 网络请求相关代码，封装了 HTTP 客户端
- **routes/**: 应用路由配置，定义了页面导航规则
- **services/**: 服务类，提供账号管理、数据存储等功能

## �📄 许可证

MIT License
