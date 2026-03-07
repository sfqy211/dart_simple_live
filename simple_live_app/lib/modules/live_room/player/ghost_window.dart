import 'dart:io';
import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:simple_live_app/widgets/net_image.dart';

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
  int _panelColor = 0xBFD0D0D0;
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
        await WindowManagerPlus.current.setPreventClose(true);
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
          final value = message['opacity'];
          if (value is num) {
            setState(() {
              _opacity = value.toDouble();
              if (!(Platform.isAndroid || Platform.isIOS)) {
                WindowManagerPlus.current.setOpacity(_opacity);
              }
            });
          }
        }
        if (message.containsKey('locked')) {
          final value = message['locked'];
          if (value is bool) {
            setState(() {
              _locked = value;
            });
          }
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
        if (message.containsKey('panelColor')) {
          final colorValue = message['panelColor'];
          if (colorValue is int) {
            setState(() {
              _panelColor = colorValue;
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
        final user = message['user']?.toString();
        final displayText =
            user == null || user.isEmpty ? text : '$user: $text';
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
          displayText,
          color: color,
          type: type,
          selfSend: selfSend,
        ));
      } else if (arguments is String) {
        _appendItem(DanmakuContentItem(arguments));
      }
    } else if (eventName == 'emoticons') {
      List<dynamic>? emoticonPackages;
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        final packages = message['packages'];
        if (packages is List) {
          emoticonPackages = packages;
        }
      } else if (arguments is List) {
        emoticonPackages = arguments;
      }
      if (emoticonPackages != null && emoticonPackages.isNotEmpty) {
        _showEmotionPanel(emoticonPackages);
      }
    }
    return null;
  }

  @override
  void onWindowClose([int? windowId]) async {
    await WindowManagerPlus.current.hide();
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'ghost_closed',
      {},
    );
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

  void _sendGhostSettings(Map<String, dynamic> settings) {
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'ghost_settings',
      settings,
    );
  }

  void _updateOpacity(double value) {
    setState(() {
      _opacity = value;
    });
    if (!(Platform.isAndroid || Platform.isIOS)) {
      WindowManagerPlus.current.setOpacity(_opacity);
    }
    _sendGhostSettings({'opacity': value});
  }

  void _updateLocked(bool value) {
    setState(() {
      _locked = value;
    });
    _sendGhostSettings({'locked': value});
  }

  void _updatePanelColor(int value) {
    setState(() {
      _panelColor = value;
    });
    _sendGhostSettings({'panelColor': value});
  }

  void _requestExitGhostMode() {
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'ghost_exit',
      {},
    );
  }

  void _requestShowEmotions() {
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'get_emoticons',
      {},
    );
  }

  void _sendEmotion(String emotion, {Map<String, dynamic>? emoticonOptions}) {
    if (emotion.isEmpty) {
      return;
    }
    final payload = {
      'text': emotion,
      if (emoticonOptions != null) 'emoticonOptions': emoticonOptions,
    };
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'send_emotion',
      payload,
    );
  }

  void _showEmotionPanel(List<dynamic> emoticonPackages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: emoticonPackages.length,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "表情包",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                isScrollable: true,
                tabs: emoticonPackages.map((pkg) {
                  var cover = '';
                  if (pkg is Map) {
                    cover = pkg['current_cover'] ?? '';
                  }
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: cover.isNotEmpty
                          ? NetImage(
                              cover,
                              width: 32,
                              height: 32,
                              borderRadius: 4,
                            )
                          : const Icon(Icons.emoji_emotions_outlined, size: 20),
                    ),
                  );
                }).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: emoticonPackages.map((pkg) {
                    dynamic emoticons;
                    if (pkg is Map) {
                      emoticons = pkg['emoticons'];
                    }
                    final emoticonList =
                        emoticons is List ? emoticons : <dynamic>[];

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      padding: const EdgeInsets.all(12),
                      itemCount: emoticonList.length,
                      itemBuilder: (context, index) {
                        final emoticon = emoticonList[index];
                        var url = '';
                        if (emoticon is Map) {
                          url = emoticon['url'] ?? '';
                        }
                        var text = '';
                        if (emoticon is Map) {
                          text = emoticon['emoticon_unique'] ??
                              emoticon['text'] ??
                              '';
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Map<String, dynamic>? options;
                            if (emoticon is Map) {
                              options = Map<String, dynamic>.from(emoticon);
                            }
                            _sendEmotion(text, emoticonOptions: options);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: NetImage(
                              url,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet() {
    int alpha = (_panelColor >> 24) & 0xFF;
    int red = (_panelColor >> 16) & 0xFF;
    int green = (_panelColor >> 8) & 0xFF;
    int blue = _panelColor & 0xFF;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                void updateColor({
                  int? a,
                  int? r,
                  int? g,
                  int? b,
                }) {
                  alpha = a ?? alpha;
                  red = r ?? red;
                  green = g ?? green;
                  blue = b ?? blue;
                  final value =
                      (alpha << 24) | (red << 16) | (green << 8) | blue;
                  _updatePanelColor(value);
                  setSheetState(() {});
                }

                return SafeArea(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        "透明浮窗设置",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(width: 64, child: Text("透明度")),
                          Expanded(
                            child: Slider(
                              value: _opacity,
                              min: 0.2,
                              max: 1.0,
                              divisions: 8,
                              label: "${(_opacity * 100).toInt()}%",
                              onChanged: (value) {
                                _updateOpacity(value);
                                setSheetState(() {});
                              },
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text("${(_opacity * 100).toInt()}%"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 64, child: Text("锁定")),
                          Expanded(child: Container()),
                          Switch(
                            value: _locked,
                            onChanged: (value) {
                              _updateLocked(value);
                              setSheetState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(_panelColor),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(color: Colors.grey.withAlpha(60)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(width: 24, child: Text("A")),
                          Expanded(
                            child: Slider(
                              value: alpha.toDouble(),
                              min: 40,
                              max: 255,
                              onChanged: (value) {
                                updateColor(a: value.round());
                              },
                            ),
                          ),
                          SizedBox(width: 36, child: Text("$alpha")),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 24, child: Text("R")),
                          Expanded(
                            child: Slider(
                              value: red.toDouble(),
                              min: 0,
                              max: 255,
                              onChanged: (value) {
                                updateColor(r: value.round());
                              },
                            ),
                          ),
                          SizedBox(width: 36, child: Text("$red")),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 24, child: Text("G")),
                          Expanded(
                            child: Slider(
                              value: green.toDouble(),
                              min: 0,
                              max: 255,
                              onChanged: (value) {
                                updateColor(g: value.round());
                              },
                            ),
                          ),
                          SizedBox(width: 36, child: Text("$green")),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 24, child: Text("B")),
                          Expanded(
                            child: Slider(
                              value: blue.toDouble(),
                              min: 0,
                              max: 255,
                              onChanged: (value) {
                                updateColor(b: value.round());
                              },
                            ),
                          ),
                          SizedBox(width: 36, child: Text("$blue")),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _requestExitGhostMode();
                        },
                        child: const Text("退出透明模式"),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightIndex =
        _fontWeight.clamp(0, FontWeight.values.length - 1).toInt();
    final panelColor = Color(_panelColor);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _locked
                        ? const SizedBox.expand()
                        : const DragToMoveArea(
                            child: SizedBox.expand(),
                          ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: const Icon(Icons.settings, size: 18),
                    onPressed: _showSettingsSheet,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _requestExitGhostMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: panelColor,
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
                color: panelColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _requestShowEmotions,
                    icon: const Icon(Icons.emoji_emotions_outlined, size: 18),
                    tooltip: "表情包",
                  ),
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
