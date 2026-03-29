import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:audio_session/audio_session.dart';

class BackgroundServiceManager {
  static final BackgroundServiceManager _instance =
      BackgroundServiceManager._internal();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._internal();

  late final FlutterBackgroundService _service;
  bool _isInitialized = false;

  bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() async {
    if (!_isSupportedPlatform) return;
    if (_isInitialized) return;

    _service = FlutterBackgroundService();

    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: onStart,
        isForegroundMode: true,
        notificationChannelId: 'simple-live-background',
        initialNotificationTitle: 'Simple Live',
        initialNotificationContent: '正在后台播放直播',
        foregroundServiceNotificationId: 888,
      ),
    );

    _isInitialized = true;
  }

  Future<void> startService() async {
    if (!_isSupportedPlatform) return;
    await initialize();
    await _service.startService();
  }

  Future<void> stopService() async {
    if (!_isSupportedPlatform) return;
    if (!_isInitialized) return;
    _service.invoke('stop');
  }

  Future<void> updateNotification(String title, String content) async {
    if (!_isSupportedPlatform) return;
    if (!_isInitialized) return;
    _service.invoke('updateNotification', {
      'title': title,
      'content': content,
    });
  }

  Future<void> setPlaybackState(bool isPlaying) async {
    if (!_isSupportedPlatform) return;
    if (!_isInitialized) return;
    _service.invoke('setPlaybackState', {
      'isPlaying': isPlaying,
    });
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    service.on('updateNotification').listen((event) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: event!['title'],
          content: event['content'],
        );
      }
    });

    service.on('setPlaybackState').listen((event) {
      if (service is AndroidServiceInstance) {
        final isPlaying = event!['isPlaying'] as bool;
        service.setForegroundNotificationInfo(
          title: 'Simple Live',
          content: isPlaying ? '正在后台播放直播' : '直播已暂停',
        );
      }
    });

    // 配置通知栏
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Simple Live',
        content: '正在后台播放直播',
      );
    }

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Simple Live',
          content: '正在后台播放直播',
        );
      }

      service.invoke('update');
    });
  }

  Future<void> setupAudioSession() async {
    if (!_isSupportedPlatform) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // 暂时降低音量
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // 暂停播放
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // 恢复音量
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // 恢复播放
            break;
        }
      }
    });

    session.becomingNoisyEventStream.listen((_) {
      // 耳机被拔出，暂停播放
    });
  }
}
