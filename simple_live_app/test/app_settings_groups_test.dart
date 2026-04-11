import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/settings/app_settings_groups.dart';

void main() {
  test('playback and window groups expose controller values', () {
    final controller = AppSettingsController();
    controller.playerVolume.value = 72;
    controller.customPlayerOutput.value = true;
    controller.videoOutputDriver.value = 'libmpv';
    controller.ghostPanelColor.value = 123;

    expect(controller.playback.playerVolume, 72);
    expect(controller.playback.customPlayerOutputEnabled, isTrue);
    expect(controller.playback.videoOutputDriver, 'libmpv');
    expect(controller.window.ghostPanelColor, 123);
  });

  test('danmaku and subtitle groups expose controller values', () {
    final controller = AppSettingsController();
    controller.danmuSize.value = 18;
    controller.danmuOpacity.value = 0.7;
    controller.subtitleEnable.value = true;
    controller.subtitleDelay.value = 1500;

    expect(controller.danmaku.fontSize, 18);
    expect(controller.danmaku.opacity, 0.7);
    expect(controller.subtitle.enabled, isTrue);
    expect(controller.subtitle.delayMs, 1500);
  });
}
