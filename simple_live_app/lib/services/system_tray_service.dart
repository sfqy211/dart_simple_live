import 'dart:io';

import 'package:get/get.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/routes/route_path.dart';

class SystemTrayManager {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();

  late final SystemTray _systemTray;
  Menu? _contextMenu;
  bool _isInitialized = false;

  Future<void> _showWindow() async {
    await WindowManagerPlus.current.restore();
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  }

  Future<void> _toggleWindowVisibility() async {
    final visible = await WindowManagerPlus.current.isVisible();
    if (visible) {
      await WindowManagerPlus.current.hide();
      Log.d('Window hidden to tray');
    } else {
      await _showWindow();
      Log.d('Window shown from tray');
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
    final current = await WindowManagerPlus.current.isAlwaysOnTop();
    await WindowManagerPlus.current.setAlwaysOnTop(!current);
  }

  Future<void> _syncMenuState() async {
    if (!_isInitialized) {
      return;
    }
    final menu = _contextMenu;
    if (menu == null) {
      return;
    }

    try {
      final visible = await WindowManagerPlus.current.isVisible();
      final pinned = await WindowManagerPlus.current.isAlwaysOnTop();
      final themeMode = AppSettingsController.instance.themeMode.value;

      final toggleItem =
          menu.findItemByName<MenuItemLabel>('toggle_visibility');
      await toggleItem?.setLabel(visible ? '隐藏' : '显示');

      final pinItem = menu.findItemByName<MenuItemCheckbox>('always_on_top');
      await pinItem?.setCheck(pinned);

      final lightItem = menu.findItemByName<MenuItemCheckbox>('theme_light');
      final darkItem = menu.findItemByName<MenuItemCheckbox>('theme_dark');
      await lightItem?.setCheck(themeMode == 1);
      await darkItem?.setCheck(themeMode == 2);

      final tooltip = 'Simple Live · ${themeMode == 1 ? "浅色" : "深色"}'
          '${pinned ? " · 置顶" : ""}';
      await updateTooltip(tooltip);
    } catch (e) {
      Log.logPrint('Sync tray menu failed: $e');
    }
  }

  Future<void> _navigateTo(String route) async {
    await _showWindow();
    if (Get.key.currentState == null) {
      return;
    }
    Get.until((route) => route.isFirst);
    if (route != RoutePath.kIndex) {
      Get.toNamed(route);
    }
  }

  Future<void> refreshState() async {
    await _syncMenuState();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

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
          name: 'toggle_visibility',
          label: '显示',
          onClicked: (menuItem) async {
            await _toggleWindowVisibility();
            await _syncMenuState();
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: '打开主界面',
          onClicked: (menuItem) async {
            await _navigateTo(RoutePath.kIndex);
          },
        ),
        MenuItemLabel(
          label: '搜索直播间',
          onClicked: (menuItem) async {
            await _navigateTo(RoutePath.kSearch);
          },
        ),
        MenuSeparator(),
        MenuItemCheckbox(
          name: 'always_on_top',
          label: '置顶',
          checked: false,
          onClicked: (menuItem) async {
            await _toggleAlwaysOnTop();
            await _syncMenuState();
          },
        ),
        MenuSeparator(),
        SubMenu(
          label: '主题',
          children: [
            MenuItemCheckbox(
              name: 'theme_light',
              label: '浅色',
              checked: AppSettingsController.instance.themeMode.value == 1,
              onClicked: (menuItem) async {
                AppSettingsController.instance.setTheme(1);
                await _syncMenuState();
              },
            ),
            MenuItemCheckbox(
              name: 'theme_dark',
              label: '深色',
              checked: AppSettingsController.instance.themeMode.value == 2,
              onClicked: (menuItem) async {
                AppSettingsController.instance.setTheme(2);
                await _syncMenuState();
              },
            ),
          ],
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: '退出',
          onClicked: (menuItem) async {
            Log.d('Application exiting from tray');
            try {
              await _systemTray.destroy();
            } catch (e) {
              Log.logPrint('System tray destroy failed: $e');
            }
            try {
              await WindowManagerPlus.current.setPreventClose(false);
            } catch (e) {
              Log.logPrint('Disable prevent close failed: $e');
            }
            WindowManagerPlus.current.destroy();
            exit(0);
          },
        ),
      ]);

      // 设置右键菜单
      await _systemTray.setContextMenu(menu);
      _contextMenu = menu;
      Log.d('System tray context menu set successfully');

      // 监听托盘事件
      _systemTray.registerSystemTrayEventHandler((eventName) {
        Log.d('System tray event: $eventName');
        switch (eventName) {
          case kSystemTrayEventClick:
            // 左键点击：显示/隐藏窗口
            _toggleWindowVisibility();
            _syncMenuState();
            break;
          case kSystemTrayEventRightClick:
            // 右键点击：弹出菜单
            _syncMenuState();
            _systemTray.popUpContextMenu();
            Log.d('Context menu popped up');
            break;
          default:
            Log.d('Other tray event: $eventName');
            break;
        }
      });

      _isInitialized = true;
      await _syncMenuState();
      Log.d('System tray service fully initialized');
    } catch (e, stackTrace) {
      Log.e('System tray initialization failed: $e', stackTrace);
    }
  }

  Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized) return;
    await _systemTray.setSystemTrayInfo(
      toolTip: tooltip,
    );
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    await _systemTray.destroy();
    _contextMenu = null;
    _isInitialized = false;
    Log.d('System tray destroyed');
  }
}
