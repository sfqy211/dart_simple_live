# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Simple Live is a Flutter-based cross-platform live streaming aggregation client that supports multiple Chinese streaming platforms (Huya, Douyu, Bilibili, Douyin). The project is written in Dart and organized as a monorepo with multiple packages.

## Environment

- **Flutter Version**: 3.38.3 (managed via FVM - see `.fvmrc`)
- **Dart SDK**: >=3.0.5 <4.0.0 for app, >=3.10.0 for core
- **Platforms**: Android, iOS, Windows (beta), macOS (beta), Linux (beta)

## Package Structure

```
├── simple_live_core/     # Core library - platform APIs and danmaku
├── simple_live_app/      # Flutter APP client
└── simple_live_console/  # Console application
```

### simple_live_core Architecture

The core library uses a plugin-like interface architecture:

- **`src/interface/live_site.dart`** - Abstract `LiveSite` class defining the contract for all streaming platforms
- **`src/interface/live_danmaku.dart`** - Abstract class for danmaku (bullet comments) handling
- **`src/huya_site.dart`**, **`src/douyu_site.dart`**, **`src/bilibili_site.dart`**, **`src/douyin_site.dart`** - Platform-specific implementations
- **`src/danmaku/`** - Platform-specific danmaku WebSocket handlers
- **`src/model/`** - Data models (LiveRoomDetail, LivePlayUrl, LiveCategory, etc.)
- **`src/common/`** - HTTP client, WebSocket utilities, logging

### simple_live_app Architecture

Uses **GetX** for state management, routing, and dependency injection.

Key directories:
- **`lib/modules/`** - Feature modules (category, follow_user, home, live_room, search, settings, sync)
- **`lib/services/`** - Business services (follow_service, sync_service, bilibili_account_service, etc.)
- **`lib/routes/`** - GetX routing configuration
- **`lib/widgets/`** - Reusable UI components
- **`lib/app/`** - App-wide configuration (style, constants, utils)
- **`lib/models/`** - Data models (Hive adapters for follow_user, history, etc.)

## Common Commands

```bash
# Install dependencies (run from package directory)
flutter pub get

# Run the app
flutter run -d windows    # Windows
flutter run -d android    # Android
flutter run -d ios        # iOS

# Build releases
flutter build windows --release
flutter build apk --release
flutter build appbundle --release

# Static analysis
flutter analyze

# Run tests
flutter test
```

## Development Notes

- **FVM**: The project uses Flutter Version Manager (FVM). Run `fvm flutter` instead of `flutter` when in the project directory, or configure your IDE to use `.fvmrc`.
- **State Management**: GetX is used throughout `simple_live_app`. Controllers extend `GetxController` and views use `GetBuilder` or `Obx`.
- **Storage**: Local persistence uses Hive (see `hive_flutter`). Models in `simple_live_app/models/db/` have Hive adapters.
- **Video Playback**: Uses `media_kit` library for cross-platform video playback.
- **Danmaku Rendering**: Uses `canvas_danmaku` package.
- **Voice Recognition**: Uses `sherpa_onnx` for local ASR (automatic speech recognition).
- **Desktop Window Management**: `window_manager_plus` handles multi-window support on desktop platforms. The app supports a "ghost window" (PIP-like transparent overlay) mode.
- **Windows-specific**: Desktop builds use `libmpv` for video playback. The build directory contains pre-built native dependencies.

## Platform Integration Points

- **Bilibili**: Uses Tars protocol (see `packages/tars_dart`) and custom protobuf definitions for danmaku
- **Douyin**: Uses protobuf for danmaku (`src/danmaku/proto/douyin.pb.dart`)
- **Huya/Douyu**: Custom WebSocket-based danmaku protocols
