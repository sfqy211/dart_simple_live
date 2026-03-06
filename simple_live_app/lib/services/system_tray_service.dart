import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayManager {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();

  late final SystemTray _systemTray;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || !Platform.isWindows) return;

    try {
      _systemTray = SystemTray();

      // 设置托盘图标
      await _systemTray.initSystemTray(
        title: 'Simple Live',
        iconPath: 'assets/logo.png',
        toolTip: 'Simple Live',
      );

      // 监听托盘点击事件
      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == 'click') {
          windowManager.isVisible().then((visible) {
            if (visible) {
              windowManager.hide();
            } else {
              windowManager.show();
              windowManager.focus();
            }
          });
        }
      });

      _isInitialized = true;
    } catch (e) {
      // 托盘初始化失败，不影响应用启动
      print('System tray initialization failed: $e');
    }
  }

  Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized || !Platform.isWindows) return;
    await _systemTray.setToolTip(tooltip);
  }

  Future<void> dispose() async {
    if (!_isInitialized || !Platform.isWindows) return;
    // 旧版本的 system_tray 可能没有 dispose 方法
  }
}
