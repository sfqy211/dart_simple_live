# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this directory.

## Project Overview

Simple Live App is a Flutter-based cross-platform live streaming client for **Bilibili only**. It depends on `simple_live_core` for platform-specific implementations.

## Environment

- **Flutter Version**: 3.38.3 (managed via FVM - see `.fvmrc`)
- **Dart SDK**: >=3.0.5 <4.0.0
- **State Management**: GetX

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run -d windows    # Windows
flutter run -d android    # Android
flutter run -d ios        # iOS
flutter run -d linux      # Linux

# Build releases
flutter build windows --release
flutter build apk --release
flutter build appbundle --release

# Static analysis
flutter analyze
```

## Architecture

### Directory Structure

```
lib/
├── main.dart              # App entry point, window initialization
├── app/                   # Core config, constants, GetX controllers
│   ├── controller/        # AppSettingsController, BaseController
│   ├── constant.dart      # App constants, platform IDs
│   ├── sites.dart         # Platform site definitions (Bilibili only)
│   └── utils/             # Utilities (archive, document, fourth button listener)
├── modules/               # Feature modules (pages + controllers)
│   ├── home/              # Home page
│   ├── category/          # Category browsing
│   ├── follow_user/       # Followed streamers
│   ├── live_room/        # Live player (92KB controller, largest module)
│   ├── search/            # Search across platforms
│   ├── settings/          # Settings sub-pages (danmu, subtitle, playback, etc.)
│   ├── sync/              # Data sync (WebDAV, local QR sync)
│   ├── mine/              # Account, history, tools
│   └── indexed/           # Tab navigation container
├── services/              # Business logic services
│   ├── follow_service.dart    # Followed users management
│   ├── sync_service.dart      # Data synchronization
│   ├── db_service.dart        # Hive database operations
│   ├── bilibili_account_service.dart  # Bilibili login/sessions
│   └── ...
├── widgets/               # Reusable UI components
│   ├── settings/          # Settings-specific widgets (cards, menus, switches)
│   ├── status/            # Loading/empty/error state widgets
│   └── ...
├── models/                # Data models
│   └── db/                # Hive-persisted models (FollowUser, History, etc.)
├── routes/                # GetX routing
│   ├── app_pages.dart     # Page definitions and bindings
│   └── route_path.dart    # Route name constants
└── requests/              # HTTP client, interceptors
```

### Key Patterns

- **Controllers**: Each feature module has its own controller extending `GetxController`. Use `BindingsBuilder.put()` in route definitions for dependency injection.
- **Settings**: `AppSettingsController` is the global settings singleton (Get.find pattern). All settings persist via `LocalStorageService` using Hive.
- **Site Integration**: Platform sites are registered in `app/sites.dart` using `simple_live_core` classes (`BiliBiliSite`)
- **Routing**: Routes are defined in `AppPages.routes` using GetX. Arguments are passed via `Get.arguments` or `Get.parameters`.

### Database Models

Hive models in `models/db/` include `FollowUser`, `History`, `FollowUserTag`. These have generated `.g.dart` files and are registered in `main.dart` `initServices()`.

### Live Room Module

The `live_room` module is the most complex, containing:
- `live_room_controller.dart` - Handles playback, danmaku, subtitle recognition
- `live_room_page.dart` - Player UI
- `player/` - Player-related components (ghost window, etc.)

## Development Notes

- **FVM**: Use `fvm flutter` instead of `flutter` when running commands
- **Multi-window**: Desktop builds support multiple windows (main window + ghost/PIP window). Window creation is handled in `main.dart` based on command-line args
- **Platform-specific storage paths**: Desktop stores Hive data in `ApplicationSupportDirectory`, mobile uses default path
- **Windows tray**: System tray integration on Windows uses `system_tray` package
