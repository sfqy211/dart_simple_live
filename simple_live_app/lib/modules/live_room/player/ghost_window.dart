import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';

class GhostWindow extends StatefulWidget {
  const GhostWindow({Key? key}) : super(key: key);

  @override
  State<GhostWindow> createState() => _GhostWindowState();
}

class _GhostWindowState extends State<GhostWindow> {
  double _opacity = 0.8;
  bool _locked = false;
  DanmakuController? _danmakuController;

  @override
  void initState() {
    super.initState();
    initWindow();
    initDanmaku();
    listenToMessages();
  }

  Future<void> initWindow() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      await WindowManagerPlus.ensureInitialized(1);
      WindowOptions windowOptions = WindowOptions(
        minimumSize: const Size(200, 150),
        maximumSize: const Size(1200, 900),
        size: const Size(400, 300),
        center: true,
        title: "Simple Live - 弹幕浮窗",
        backgroundColor: Colors.transparent,
        skipTaskbar: true,
      );
      await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
        await WindowManagerPlus.current.setAlwaysOnTop(true);
        await WindowManagerPlus.current.setTitleBarStyle(TitleBarStyle.hidden);
        await WindowManagerPlus.current.setBackgroundColor(Colors.black.withAlpha((_opacity * 255).toInt()));
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

  void listenToMessages() {
    // 使用 window_manager_plus 的方法通道处理消息
    MethodChannel('com.simple_live/ghost_window').setMethodCallHandler((call) async {
      if (call.method == 'update') {
        final message = call.arguments;
        if (message.containsKey('opacity')) {
          setState(() {
            _opacity = message['opacity'];
            if (!(Platform.isAndroid || Platform.isIOS)) {
              WindowManagerPlus.current.setBackgroundColor(Colors.black.withAlpha((_opacity * 255).toInt()));
            }
          });
        }
        if (message.containsKey('locked')) {
          setState(() {
            _locked = message['locked'];
          });
        }
      } else if (call.method == 'danmaku') {
        _danmakuController?.addDanmaku(call.arguments['text']);
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onPanUpdate: _locked ? null : (details) async {
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

void runGhostWindow() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: GhostWindow(),
    debugShowCheckedModeBanner: false,
  ));
}
