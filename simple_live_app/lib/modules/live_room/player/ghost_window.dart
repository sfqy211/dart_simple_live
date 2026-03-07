import 'dart:io';
import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class GhostWindow extends StatefulWidget {
  const GhostWindow({Key? key}) : super(key: key);

  @override
  State<GhostWindow> createState() => _GhostWindowState();
}

class _GhostWindowState extends State<GhostWindow> with WindowListener {
  double _opacity = 0.8;
  bool _locked = false;
  DanmakuController? _danmakuController;

  @override
  void initState() {
    super.initState();
    initWindow();
    initDanmaku();
    WindowManagerPlus.current.addListener(this);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  Future<void> initWindow() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      const windowOptions = WindowOptions(
        minimumSize: Size(200, 150),
        maximumSize: Size(1200, 900),
        size: Size(400, 300),
        center: true,
        title: "Simple Live - 弹幕浮窗",
        backgroundColor: Colors.transparent,
        skipTaskbar: true,
      );
      await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions,
          () async {
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
        await WindowManagerPlus.current.setAlwaysOnTop(true);
        await WindowManagerPlus.current.setTitleBarStyle(TitleBarStyle.hidden);
        await WindowManagerPlus.current.setBackgroundColor(
            Colors.black.withAlpha((_opacity * 255).toInt()));
      });
    }
  }

  void initDanmaku() {
    _danmakuController = DanmakuController(
      onAddDanmaku: (item) {},
      onUpdateOption: (option) {},
      onPause: () {},
      onResume: () {},
      onClear: () {},
    );
  }

  @override
  Future<dynamic> onEventFromWindow(
    String eventName,
    int fromWindowId,
    dynamic arguments,
  ) async {
    if (eventName == 'update') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        if (message.containsKey('opacity')) {
          setState(() {
            _opacity = message['opacity'];
            if (!(Platform.isAndroid || Platform.isIOS)) {
              WindowManagerPlus.current.setBackgroundColor(
                  Colors.black.withAlpha((_opacity * 255).toInt()));
            }
          });
        }
        if (message.containsKey('locked')) {
          setState(() {
            _locked = message['locked'];
          });
        }
      }
    } else if (eventName == 'danmaku') {
      if (arguments is Map && arguments['text'] != null) {
        _danmakuController?.addDanmaku(arguments['text']);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onPanUpdate: _locked
            ? null
            : (details) async {
                final position = await WindowManagerPlus.current.getPosition();
                await WindowManagerPlus.current.setPosition(Offset(
                  position.dx + details.delta.dx,
                  position.dy + details.delta.dy,
                ));
              },
        child: Container(
          color: Colors.transparent,
          child: DanmakuScreen(
            createdController: (controller) {
              _danmakuController = controller;
            },
            option: DanmakuOption(
              fontSize: AppSettingsController.instance.danmuSize.value,
              area: AppSettingsController.instance.danmuArea.value,
              duration: AppSettingsController.instance.danmuSpeed.value.toInt(),
              opacity: AppSettingsController.instance.danmuOpacity.value,
              fontWeight: AppSettingsController.instance.danmuFontWeight.value,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> runGhostWindow() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!(Platform.isAndroid || Platform.isIOS)) {
    await Hive.initFlutter((await getApplicationSupportDirectory()).path);
    await Get.put(LocalStorageService()).init();
    Get.put(AppSettingsController());
  }
  runApp(const MaterialApp(
    home: GhostWindow(),
    debugShowCheckedModeBanner: false,
  ));
}
