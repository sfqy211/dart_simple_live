# Windows Release Flow

## Standard Flow

1. 运行 `flutter pub get`
2. 运行 `flutter analyze --no-pub`
3. 运行 `flutter test`
4. 运行 `flutter build windows --release`
5. 将 `build/windows/x64/runner/Release` 打包为 zip

## Scripts

- 构建脚本：[build_windows.ps1](C:/Users/sfqy/Documents/code/dart_simple_live/simple_live_app/scripts/build_windows.ps1)
- 发布打包脚本：[release_windows.ps1](C:/Users/sfqy/Documents/code/dart_simple_live/simple_live_app/scripts/release_windows.ps1)

## Output Convention

- 目录：`dist/`
- 文件名：`simple_live_windows_v<version>.zip`

## Verification

发布前至少执行：
- `flutter analyze --no-pub`
- `flutter test`
- `flutter build windows --release`
