import 'dart:async';
import 'dart:io';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/settings/app_settings_groups.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

typedef PlayerErrorHandler = void Function(String error);
typedef PlayerLogHandler = void Function(String message, PlayerLog event);
typedef PlayerPlayingHandler = void Function();
typedef PlayerCompletedHandler = void Function();
typedef PlayerSizeChangedHandler = void Function(int? width, int? height);

class PlayerEngineBindings {
  final List<StreamSubscription<dynamic>> _subscriptions;

  PlayerEngineBindings(this._subscriptions);

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}

class PlayerEngine {
  PlayerEngine({AppSettingsController? settings})
      : settings = settings ?? AppSettingsController.instance;

  final AppSettingsController settings;

  PlaybackSettingsGroup get playback => settings.playback;

  late final Player player = Player(
    configuration: PlayerConfiguration(
      title: "Simple Live Player",
      logLevel: settings.logEnable.value ? MPVLogLevel.info : MPVLogLevel.error,
    ),
  );

  late final VideoController videoController = VideoController(
    player,
    configuration: _buildVideoControllerConfiguration(),
  );

  VideoControllerConfiguration _buildVideoControllerConfiguration() {
    if (playback.customPlayerOutputEnabled) {
      return VideoControllerConfiguration(
        vo: playback.videoOutputDriver,
        hwdec: playback.videoHardwareDecoder,
      );
    }
    return VideoControllerConfiguration(
      enableHardwareAcceleration: playback.hardwareDecodeEnabled,
      androidAttachSurfaceAfterVideoParameters: false,
    );
  }

  Future<void> initialize() async {
    final nativePlayer = player.platform as NativePlayer;
    final tempPath = Directory.systemTemp.path;
    final cacheDir = Directory(
      "$tempPath${Platform.pathSeparator}simple_live_cache",
    );
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    await nativePlayer.setProperty('cache-dir', cacheDir.path);

    if (playback.customPlayerOutputEnabled) {
      await nativePlayer.setProperty('ao', playback.audioOutputDriver);
    }
  }

  PlayerEngineBindings bind({
    required PlayerErrorHandler onError,
    required PlayerPlayingHandler onPlaying,
    required PlayerCompletedHandler onCompleted,
    required PlayerLogHandler onLog,
    required PlayerSizeChangedHandler onSizeChanged,
  }) {
    final subscriptions = <StreamSubscription<dynamic>>[
      player.stream.error.listen(onError),
      player.stream.playing.listen((event) {
        if (event) {
          WakelockPlus.enable();
          onPlaying();
        }
      }),
      player.stream.completed.listen((event) {
        if (event) {
          onCompleted();
        }
      }),
      player.stream.log.listen((event) {
        onLog(event.text, event);
      }),
      player.stream.width.listen((_) {
        onSizeChanged(player.state.width, player.state.height);
      }),
      player.stream.height.listen((_) {
        onSizeChanged(player.state.width, player.state.height);
      }),
    ];
    return PlayerEngineBindings(subscriptions);
  }

  Future<void> applySoftwareFallback() async {
    if (player.platform is! NativePlayer) {
      return;
    }
    try {
      await (player.platform as dynamic).setProperty('hwdec', 'no');
    } catch (e) {
      Log.logPrint('切换为软件解码失败: $e');
    }
    try {
      await (player.platform as dynamic).setProperty('vo', 'libmpv');
    } catch (e) {
      Log.logPrint('切换渲染输出失败: $e');
    }
  }

  Future<void> reopenCurrentPlaylist() async {
    if (player.state.playlist.medias.isEmpty) {
      return;
    }
    await player.open(player.state.playlist);
  }

  Future<void> setVolume(double value) async {
    await player.setVolume(value);
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
