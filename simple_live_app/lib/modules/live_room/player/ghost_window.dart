import 'dart:io';
import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class GhostWindow extends StatefulWidget {
  const GhostWindow({Key? key}) : super(key: key);

  @override
  State<GhostWindow> createState() => _GhostWindowState();
}

class _GhostWindowState extends State<GhostWindow> with WindowListener {
  double _opacity = 0.8;
  bool _locked = false;
  double _fontSize = 16.0;
  double _danmakuOpacity = 1.0;
  int _fontWeight = 4;
  final List<DanmakuContentItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initWindow();
    WindowManagerPlus.current.addListener(this);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    _scrollController.dispose();
    _inputController.dispose();
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
        await WindowManagerPlus.current.setBackgroundColor(Colors.transparent);
        await WindowManagerPlus.current.setOpacity(_opacity);
      });
    }
  }

  @override
  Future<dynamic> onEventFromWindow(
    String eventName,
    int fromWindowId,
    dynamic arguments,
  ) async {
    if (eventName == 'update' || eventName == 'config') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        if (message.containsKey('opacity')) {
          setState(() {
            _opacity = message['opacity'];
            if (!(Platform.isAndroid || Platform.isIOS)) {
              WindowManagerPlus.current.setOpacity(_opacity);
            }
          });
        }
        if (message.containsKey('locked')) {
          setState(() {
            _locked = message['locked'];
          });
        }
        if (message.containsKey('danmaku')) {
          final danmaku = message['danmaku'];
          if (danmaku is Map) {
            final map = Map<String, dynamic>.from(danmaku);
            setState(() {
              _fontSize = (map['fontSize'] as num?)?.toDouble() ?? _fontSize;
              _danmakuOpacity =
                  (map['opacity'] as num?)?.toDouble() ?? _danmakuOpacity;
              _fontWeight = (map['fontWeight'] as num?)?.toInt() ?? _fontWeight;
            });
          }
        }
      }
    } else if (eventName == 'danmaku') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        final text = message['text']?.toString();
        if (text == null || text.isEmpty) {
          return null;
        }
        final colorValue = message['color'];
        final typeIndex = message['type'];
        final selfSend = message['selfSend'] == true;
        final color = colorValue is int ? Color(colorValue) : Colors.white;
        final type = typeIndex is int &&
                typeIndex >= 0 &&
                typeIndex < DanmakuItemType.values.length
            ? DanmakuItemType.values[typeIndex]
            : DanmakuItemType.scroll;
        _appendItem(DanmakuContentItem(
          text,
          color: color,
          type: type,
          selfSend: selfSend,
        ));
      } else if (arguments is String) {
        _appendItem(DanmakuContentItem(arguments));
      }
    }
    return null;
  }

  void _appendItem(DanmakuContentItem item) {
    setState(() {
      _items.add(item);
      if (_items.length > 200) {
        _items.removeAt(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'send_chat',
      {'text': text},
    );
    _inputController.clear();
    _appendItem(DanmakuContentItem(
      text,
      color: Theme.of(context).colorScheme.primary,
      selfSend: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final weightIndex =
        _fontWeight.clamp(0, FontWeight.values.length - 1).toInt();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: _locked
                  ? const SizedBox.expand()
                  : const DragToMoveArea(
                      child: SizedBox.expand(),
                    ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        item.text,
                        style: TextStyle(
                          color: item.color.withValues(alpha: _danmakuOpacity),
                          fontSize: _fontSize,
                          fontWeight: FontWeight.values[weightIndex],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: "发送弹幕...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  TextButton(
                    onPressed: _sendMessage,
                    child: const Text("发送"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> runGhostWindow() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: GhostWindow(),
    debugShowCheckedModeBanner: false,
  ));
}
