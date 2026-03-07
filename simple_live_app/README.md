# simple_live_app

基于核心库实现的Flutter APP客户端。

## TODO

- [ ] 支持桌面平台
- [ ] iOS播放问题
- [ ] 全屏、非全屏弹幕样式分离
- [ ] 重写直播间 

## 运行

```powershell
cd d:\AHEU\code\dart_simple_live\simple_live_app
# 运行分析
flutter analyze
# 安装依赖
flutter pub get
# 运行应用
flutter run -d windows
# 构建 Windows 应用
flutter build windows --release
```

如需 Android 构建：

```powershell
cd d:\AHEU\code\dart_simple_live\simple_live_app
# 运行应用
flutter run -d android
# 构建 Android 应用
flutter build apk --release
```

## 备注

```
keytool -genkey -v -keystore d:\AHEU\code\dart_simple_live\simple_live_app\android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

密钥库口令： 123456

您的名字与姓氏是什么：wind

您的组织单位名称是什么：sfqy

其余项均为空（直接空格）

CN=wind, OU=sfqy, O=Unknown, L=Unknown, ST=Unknown, C=Unknown