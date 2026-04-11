import 'package:simple_live_app/app/controller/app_settings_controller.dart';

extension AppSettingsDomainAccess on AppSettingsController {
  PlaybackSettingsGroup get playback => PlaybackSettingsGroup(this);
  DanmakuSettingsGroup get danmaku => DanmakuSettingsGroup(this);
  SubtitleSettingsGroup get subtitle => SubtitleSettingsGroup(this);
  WindowSettingsGroup get window => WindowSettingsGroup(this);
  SyncSettingsGroup get sync => SyncSettingsGroup(this);
}

class PlaybackSettingsGroup {
  final AppSettingsController controller;

  const PlaybackSettingsGroup(this.controller);

  bool get hardwareDecodeEnabled => controller.hardwareDecode.value;
  bool get customPlayerOutputEnabled => controller.customPlayerOutput.value;
  String get audioOutputDriver => controller.audioOutputDriver.value;
  String get videoOutputDriver => controller.videoOutputDriver.value;
  String get videoHardwareDecoder => controller.videoHardwareDecoder.value;
  double get playerVolume => controller.playerVolume.value;
  bool get forceHttps => controller.playerForceHttps.value;
  int get playerBufferSize => controller.playerBufferSize.value;
}

class DanmakuSettingsGroup {
  final AppSettingsController controller;

  const DanmakuSettingsGroup(this.controller);

  double get fontSize => controller.danmuSize.value;
  double get opacity => controller.danmuOpacity.value;
  int get fontWeight => controller.danmuFontWeight.value;
  double get area => controller.danmuArea.value;
  double get speed => controller.danmuSpeed.value;
  bool get enabled => controller.danmuEnable.value;
}

class SubtitleSettingsGroup {
  final AppSettingsController controller;

  const SubtitleSettingsGroup(this.controller);

  bool get enabled => controller.subtitleEnable.value;
  double get fontSize => controller.subtitleFontSize.value;
  double get backgroundOpacity => controller.subtitleBackgroundOpacity.value;
  double get delayMs => controller.subtitleDelay.value;
  String get modelName => controller.subtitleModelName.value;
}

class WindowSettingsGroup {
  final AppSettingsController controller;

  const WindowSettingsGroup(this.controller);

  bool get ghostModeEnabled => controller.ghostMode.value;
  int get ghostPanelColor => controller.ghostPanelColor.value;
  bool get trayIntegrationEnabled => controller.windowsTrayIntegration.value;
  int get themeMode => controller.themeMode.value;
}

class SyncSettingsGroup {
  final AppSettingsController controller;

  const SyncSettingsGroup(this.controller);

  bool get autoUpdateFollowEnabled => controller.autoUpdateFollowEnable.value;
  int get autoUpdateFollowDuration => controller.autoUpdateFollowDuration.value;
  int get updateFollowThreadCount => controller.updateFollowThreadCount.value;
}
