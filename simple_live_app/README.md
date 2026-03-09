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

## 📄 许可证

MIT License
