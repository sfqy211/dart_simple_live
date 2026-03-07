import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:simple_live_app/app/log.dart';

class SystemTrayManager {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();

  late final SystemTray _systemTray;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || !Platform.isWindows) return;

    try {
      Log.d('Initializing system tray...');
      _systemTray = SystemTray();

      // 初始化系统托盘（使用新的 logo.ico 文件）
      Log.d('Initializing system tray with logo.ico...');
      await _systemTray.initSystemTray(
        title: 'Simple Live',
        iconPath: 'assets/logo.ico',
      );
      Log.d('System tray initialized successfully');

      // 创建右键菜单
      Log.d('Creating system tray context menu...');
      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: '显示/隐藏',
          onClicked: (menuItem) async {
            var visible = await WindowManagerPlus.current.isVisible();
            if (visible) {
              await WindowManagerPlus.current.hide();
              Log.d('Window hidden to tray');
            } else {
              await WindowManagerPlus.current.show();
              await WindowManagerPlus.current.focus();
              Log.d('Window shown from tray');
            }
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: '退出',
          onClicked: (menuItem) async {
            await WindowManagerPlus.current.destroy();
            Log.d('Application exited from tray');
          },
        ),
      ]);

      // 设置右键菜单
      await _systemTray.setContextMenu(menu);
      Log.d('System tray context menu set successfully');

      // 监听托盘事件
      _systemTray.registerSystemTrayEventHandler((eventName) {
        Log.d('System tray event: $eventName');
        switch (eventName) {
          case kSystemTrayEventClick:
            // 左键点击：显示/隐藏窗口
            WindowManagerPlus.current.isVisible().then((visible) {
              if (visible) {
                WindowManagerPlus.current.hide();
                Log.d('Window hidden to tray');
              } else {
                WindowManagerPlus.current.show();
                WindowManagerPlus.current.focus();
                Log.d('Window shown from tray');
              }
            });
            break;
          case kSystemTrayEventRightClick:
            // 右键点击：弹出菜单
            _systemTray.popUpContextMenu();
            Log.d('Context menu popped up');
            break;
          default:
            Log.d('Other tray event: $eventName');
            break;
        }
      });

      _isInitialized = true;
      Log.d('System tray service fully initialized');
    } catch (e, stackTrace) {
      Log.e('System tray initialization failed: $e', stackTrace);
    }
  }

  Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized || !Platform.isWindows) return;
    await _systemTray.setSystemTrayInfo(
      toolTip: tooltip,
    );
  }

  Future<void> dispose() async {
    if (!_isInitialized || !Platform.isWindows) return;
    await _systemTray.destroy();
    Log.d('System tray destroyed');
  }
}
