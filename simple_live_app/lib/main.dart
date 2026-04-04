import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/utils/listen_fourth_button.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:simple_live_app/modules/other/debug_log_page.dart';
import 'package:simple_live_app/modules/live_room/player/ghost_window.dart';
import 'package:simple_live_app/routes/app_pages.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_app/services/sync_service.dart';
import 'package:simple_live_app/services/system_tray_service.dart';
import 'package:simple_live_app/widgets/status/app_loadding_widget.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 window_manager_plus
  if (!Platform.isAndroid) {
    await WindowManagerPlus.ensureInitialized(
        args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0);
  }

  // 检查是否是主窗口（通过参数判断）
  bool isMainWindow = args.isEmpty || Platform.isAndroid;

  if (isMainWindow) {
    // 主窗口：运行完整应用
    await migrateData();
    await initWindow();
    MediaKit.ensureInitialized();
    await Hive.initFlutter(
      !Platform.isAndroid
          ? (await getApplicationSupportDirectory()).path
          : null,
    );
    //初始化服务
    await initServices();
    await _applyWindowsTrayIntegration(
      AppSettingsController.instance.windowsTrayIntegration.value,
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    //设置状态栏为透明
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    runApp(const MyApp());
  } else {
    // 新创建的窗口：运行幽灵窗口
    await runGhostWindow();
  }
}

/// 将Hive数据迁移到Application Support
Future migrateData() async {
  if (Platform.isAndroid) {
    return;
  }
  var hiveFileList = [
    "followuser",
    //旧版本写错成hostiry了
    "hostiry",
    "followusertag",
    "localstorage",
    "danmushield",
  ];
  try {
    var newDir = await getApplicationSupportDirectory();
    var hiveFile = File(p.join(newDir.path, "followuser.hive"));
    if (await hiveFile.exists()) {
      return;
    }

    var oldDir = await getApplicationDocumentsDirectory();
    for (var element in hiveFileList) {
      var oldFile = File(p.join(oldDir.path, "$element.hive"));
      if (await oldFile.exists()) {
        var fileName = "$element.hive";
        if (element == "hostiry") {
          fileName = "history.hive";
        }
        await oldFile.copy(p.join(newDir.path, fileName));
        await oldFile.delete();
      }
      var lockFile = File(p.join(oldDir.path, "$element.lock"));
      if (await lockFile.exists()) {
        await lockFile.delete();
      }
    }
  } catch (e) {
    Log.logPrint(e);
  }
}

class _WindowCloseListener with WindowListener {
  @override
  void onWindowClose([int? windowId]) async {
    bool isPreventClose = await WindowManagerPlus.current.isPreventClose();
    if (isPreventClose) {
      await WindowManagerPlus.current.hide();
      await SystemTrayManager().refreshState();
    } else {
      await WindowManagerPlus.current.destroy();
    }
  }

  @override
  void onWindowMinimize([int? windowId]) async {
    final isPreventClose = await WindowManagerPlus.current.isPreventClose();
    if (!isPreventClose) {
      return;
    }
    await WindowManagerPlus.current.hide();
    await SystemTrayManager().refreshState();
  }

  @override
  void onWindowRestore([int? windowId]) async {
    await SystemTrayManager().refreshState();
  }
}

final _windowCloseListener = _WindowCloseListener();
bool _windowsTrayListenerAttached = false;

Future initWindow() async {
  if (!Platform.isWindows) {
    return;
  }
  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size(280, 280),
    center: true,
    skipTaskbar: false,
    title: "Simple Live",
  );
  await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });
}

Future<void> _applyWindowsTrayIntegration(bool enabled) async {
  if (!Platform.isWindows) {
    return;
  }

  if (enabled) {
    await SystemTrayManager().initialize();
    if (!_windowsTrayListenerAttached) {
      WindowManagerPlus.current.addListener(_windowCloseListener);
      _windowsTrayListenerAttached = true;
    }
    await WindowManagerPlus.current.setPreventClose(true);
    await SystemTrayManager().refreshState();
    return;
  }

  if (_windowsTrayListenerAttached) {
    WindowManagerPlus.current.removeListener(_windowCloseListener);
    _windowsTrayListenerAttached = false;
  }
  await WindowManagerPlus.current.setPreventClose(false);
  await SystemTrayManager().dispose();
}

Future initServices() async {
  Hive.registerAdapter(FollowUserAdapter());
  Hive.registerAdapter(HistoryAdapter());
  Hive.registerAdapter(FollowUserTagAdapter());

  //包信息
  Utils.packageInfo = await PackageInfo.fromPlatform();
  //本地存储
  Log.d("Init LocalStorage Service");
  await Get.put(LocalStorageService()).init();
  await Get.put(DBService()).init();
  //初始化设置控制器
  Get.put(AppSettingsController());
  ever<bool>(
    AppSettingsController.instance.windowsTrayIntegration,
    (value) {
      _applyWindowsTrayIntegration(value);
    },
  );
  ever<int>(
    AppSettingsController.instance.themeMode,
    (value) {
      SystemTrayManager().refreshState();
    },
  );

  Get.put(BiliBiliAccountService());

  Get.put(SyncService());

  Get.put(FollowService());

  initCoreLog();
}

void initCoreLog() {
  //日志信息
  CoreLog.enableLog =
      !kReleaseMode || AppSettingsController.instance.logEnable.value;
  CoreLog.requestLogType = RequestLogType.short;
  CoreLog.onPrintLog = (level, msg) {
    switch (level) {
      case Level.debug:
        Log.d(msg);
        break;
      case Level.error:
        Log.e(msg, StackTrace.current);
        break;
      case Level.info:
        Log.i(msg);
        break;
      case Level.warning:
        Log.w(msg);
        break;
      default:
        Log.logPrint(msg);
    }
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Simple Live",
      theme: AppStyle.lightTheme,
      darkTheme: AppStyle.darkTheme,
      themeMode:
          ThemeMode.values[Get.find<AppSettingsController>().themeMode.value],
      initialRoute: RoutePath.kIndex,
      getPages: AppPages.routes,
      //国际化
      locale: const Locale("zh", "CN"),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale("zh", "CN")],
      logWriterCallback: (text, {bool? isError}) {
        Log.addDebugLog(text, (isError ?? false) ? Colors.red : Colors.grey);
        Log.writeLog(text, (isError ?? false) ? Level.error : Level.info);
      },
      // 升级后Android页面过渡动画似乎有BUG
      defaultTransition: Platform.isAndroid ? Transition.cupertino : null,
      //debugShowCheckedModeBanner: false,
      navigatorObservers: [FlutterSmartDialog.observer],
      // 禁用语义化调试覆盖层
      showSemanticsDebugger: false,
      builder: (context, child) {
        final smartDialogBuilder = FlutterSmartDialog.init(
          loadingBuilder: ((msg) => const AppLoaddingWidget()),
          builder: (context, child) {
            // Fix for HyperOS windowed-mode Flutter bug:
            // - Values > 50 indicate the bug (windowed mode on HyperOS)
            // - Values == 0 are valid for fullscreen/immersive mode and must NOT be treated as abnormal
            const fallbackPadding = EdgeInsets.only(top: 25, bottom: 35);
            const maxNormalPadding = 50.0;

            final mediaQueryData = MediaQuery.of(context);
            final hasAbnormalPadding =
                mediaQueryData.viewPadding.top > maxNormalPadding;

            final fixedMediaQueryData = hasAbnormalPadding
                ? mediaQueryData.copyWith(
                    viewPadding: fallbackPadding,
                    padding: fallbackPadding,
                    textScaler: const TextScaler.linear(1.0),
                  )
                : mediaQueryData.copyWith(
                    textScaler: const TextScaler.linear(1.0));

            return MediaQuery(
              data: fixedMediaQueryData,
              child: Stack(
                children: [
                  //侧键返回
                  RawGestureDetector(
                    excludeFromSemantics: true,
                    gestures: <Type, GestureRecognizerFactory>{
                      FourthButtonTapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              FourthButtonTapGestureRecognizer>(
                        () => FourthButtonTapGestureRecognizer(),
                        (FourthButtonTapGestureRecognizer instance) {
                          instance.onTapDown = (TapDownDetails details) async {
                            //如果处于全屏状态，退出全屏
                            if (!Platform.isAndroid) {
                              if (await WindowManagerPlus.current
                                  .isFullScreen()) {
                                await WindowManagerPlus.current
                                    .setFullScreen(false);
                                return;
                              }
                            }
                            Get.back();
                          };
                        },
                      ),
                    },
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (KeyEvent event) async {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.escape) {
                          // ESC退出全屏
                          // 如果处于全屏状态，退出全屏
                          if (!Platform.isAndroid) {
                            if (await WindowManagerPlus.current
                                .isFullScreen()) {
                              await WindowManagerPlus.current
                                  .setFullScreen(false);
                              return;
                            }
                          }
                        }
                      },
                      child: child!,
                    ),
                  ),

                  //查看DEBUG日志按钮
                  //只在Debug、Profile模式显示
                  Visibility(
                    visible: !kReleaseMode,
                    child: Positioned(
                      right: 12,
                      bottom: 100 + context.mediaQueryViewPadding.bottom,
                      child: Opacity(
                        opacity: 0.4,
                        child: ElevatedButton(
                          child: const Text("DEBUG LOG"),
                          onPressed: () {
                            Get.bottomSheet(
                              const DebugLogPage(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        child = smartDialogBuilder(context, child);

        if (!Platform.isAndroid) {
          return ExcludeSemantics(child: child);
        }
        return child;
      },
    );
  }
}
