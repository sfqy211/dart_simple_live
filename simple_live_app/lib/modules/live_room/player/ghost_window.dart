import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/widgets/net_image.dart';

enum _GhostWindowCollapseMode {
  none,
  miniButton,
}

class GhostWindow extends StatefulWidget {
  const GhostWindow({Key? key}) : super(key: key);

  @override
  State<GhostWindow> createState() => _GhostWindowState();
}

class _GhostWindowState extends State<GhostWindow> with WindowListener {
  static const Size _normalMinSize = Size(200, 150);
  static const Size _normalMaxSize = Size(1200, 900);
  static const double _windowBarHeight = 36.0;
  static const double _collapsedButtonWindowWidth = 84.0;
  static const double _collapsedButtonWindowHeight = 36.0;
  static const double _collapsedExpandButtonSize = 26.0;
  static const double _collapsedButtonRadius = 8.0;
  static const double _inputActionHeight = 36.0;
  static const double _inputIconButtonSize = 34.0;
  static const double _edgeInset = 6.0;

  double _opacity = 0.8;
  bool _locked = false;
  _GhostWindowCollapseMode _collapseMode = _GhostWindowCollapseMode.none;
  bool _showSubtitle = true;
  double _fontSize = 16.0;
  double _volume = 100.0;
  double _danmakuOpacity = 1.0;
  int _fontWeight = 4;
  bool _useDefaultDanmakuColor = false;
  int _panelColor = 0xBFD0D0D0;
  String _subtitleText = '';
  bool _subtitleIsPartial = false;
  final List<DanmakuContentItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _autoSpamTextController = TextEditingController();
  final TextEditingController _autoSpamFavoriteController =
      TextEditingController();
  final GlobalKey _windowBarKey = GlobalKey();
  final GlobalKey _inputBarKey = GlobalKey();
  Rect? _expandedBounds;
  bool _pendingAutoSpamPanelOpen = false;
  bool _autoSpamTextRunning = false;
  bool _autoSpamEmotionRunning = false;
  bool _autoSpamFavoritesRunning = false;
  String _autoSpamTextMsg = '';
  int _autoSpamTextInterval = 5;
  int _autoSpamTextChunkSize = 20;
  int _autoSpamTextDuration = 0;
  int _autoSpamEmotionInterval = 5;
  int _autoSpamEmotionDuration = 0;
  int _autoSpamFavoritesInterval = 5;
  int _autoSpamFavoritesDuration = 0;
  int _autoSpamFavoritesIndex = 0;
  List<Map<String, dynamic>> _autoSpamEmotions = [];
  List<Map<String, dynamic>> _autoSpamFavorites = [
    {'id': 1, 'name': '第1组', 'msg': ''}
  ];
  bool _autoSpamEmotionsMode = false;
  bool _passthroughEnabled = true;
  bool _passthroughPausedForOverlay = false;
  bool _passthroughSyncScheduled = false;
  bool _lastPassthroughEnabled = false;
  double _lastPassthroughTopHeight = -1;
  double _lastPassthroughBottomHeight = -1;

  bool get _collapsed => _collapseMode != _GhostWindowCollapseMode.none;

  bool get _miniButtonCollapsed =>
      _collapseMode == _GhostWindowCollapseMode.miniButton;

  MethodChannel get _windowChannel =>
      MethodChannel('window_manager_plus_${WindowManagerPlus.current.id}');

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
    _autoSpamTextController.dispose();
    _autoSpamFavoriteController.dispose();
    super.dispose();
  }

  Future<void> initWindow() async {
    const windowOptions = WindowOptions(
      minimumSize: _normalMinSize,
      maximumSize: _normalMaxSize,
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
      await WindowManagerPlus.current.setOpacity(1.0);
      await WindowManagerPlus.current.setPreventClose(true);
      await _restoreWindowConstraints();
    });
  }

  Future<void> _restoreWindowConstraints() async {
    await WindowManagerPlus.current.setMinimumSize(_normalMinSize);
    await WindowManagerPlus.current.setMaximumSize(_normalMaxSize);
  }

  Future<void> _setCollapsedConstraints({
    required double minWidth,
    required double minHeight,
    double? maxWidth,
    double? maxHeight,
  }) async {
    await WindowManagerPlus.current.setMinimumSize(Size(minWidth, minHeight));
    await WindowManagerPlus.current.setMaximumSize(
      Size(
          maxWidth ?? _normalMaxSize.width, maxHeight ?? _normalMaxSize.height),
    );
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
        if (message.containsKey('volume')) {
          final value = message['volume'];
          if (value is num) {
            setState(() {
              _volume = value.toDouble();
            });
          }
        }
        if (message.containsKey('subtitleEnable')) {
          final value = message['subtitleEnable'];
          if (value is bool) {
            setState(() {
              _showSubtitle = value;
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
    } else if (eventName == 'subtitle') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        setState(() {
          _subtitleText = message['text']?.toString() ?? '';
          _subtitleIsPartial = message['partial'] == true;
        });
      }
    } else if (eventName == 'auto_spam_state') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        setState(() {
          _autoSpamTextMsg = message['textMsg']?.toString() ?? _autoSpamTextMsg;
          _autoSpamTextInterval = (message['textInterval'] as num?)?.toInt() ??
              _autoSpamTextInterval;
          _autoSpamTextChunkSize =
              (message['textChunkSize'] as num?)?.toInt() ??
                  _autoSpamTextChunkSize;
          _autoSpamTextDuration = (message['textDuration'] as num?)?.toInt() ??
              _autoSpamTextDuration;
          _autoSpamEmotionInterval =
              (message['emotionInterval'] as num?)?.toInt() ??
                  _autoSpamEmotionInterval;
          _autoSpamEmotionDuration =
              (message['emotionDuration'] as num?)?.toInt() ??
                  _autoSpamEmotionDuration;
          _autoSpamFavoritesInterval =
              (message['favoritesInterval'] as num?)?.toInt() ??
                  _autoSpamFavoritesInterval;
          _autoSpamFavoritesDuration =
              (message['favoritesDuration'] as num?)?.toInt() ??
                  _autoSpamFavoritesDuration;
          _autoSpamFavoritesIndex =
              (message['favoritesIndex'] as num?)?.toInt() ??
                  _autoSpamFavoritesIndex;
          _autoSpamTextRunning = message['textRunning'] == true;
          _autoSpamEmotionRunning = message['emotionRunning'] == true;
          _autoSpamFavoritesRunning = message['favoritesRunning'] == true;
          final emotions = message['emotions'];
          if (emotions is List) {
            _autoSpamEmotions = emotions
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          final favorites = message['favorites'];
          if (favorites is List) {
            _autoSpamFavorites = favorites
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          if (_autoSpamFavorites.isEmpty) {
            _autoSpamFavorites = [
              {'id': 1, 'name': '第1组', 'msg': ''}
            ];
          }
          if (_autoSpamFavoritesIndex >= _autoSpamFavorites.length) {
            _autoSpamFavoritesIndex = 0;
          }
          if (_autoSpamTextController.text != _autoSpamTextMsg) {
            _autoSpamTextController.text = _autoSpamTextMsg;
          }
          final currentMsg =
              _autoSpamFavorites[_autoSpamFavoritesIndex]['msg']?.toString() ??
                  '';
          if (_autoSpamFavoriteController.text != currentMsg) {
            _autoSpamFavoriteController.text = currentMsg;
          }
        });
        if (_pendingAutoSpamPanelOpen) {
          _pendingAutoSpamPanelOpen = false;
          _showAutoSpamPanel();
        }
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
        if (_autoSpamEmotionsMode) {
          _autoSpamEmotionsMode = false;
          _showAutoSpamEmotionsPanel(emoticonPackages);
        } else {
          _showEmotionPanel(emoticonPackages);
        }
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

  void _requestAutoSpamState() {
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'get_auto_spam_state',
      {},
    );
  }

  void _setAutoSpamState(Map<String, dynamic> settings) {
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'set_auto_spam_state',
      settings,
    );
  }

  void _sendAutoSpamAction(String type, bool start) {
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'auto_spam_action',
      {'type': type, 'start': start},
    );
    _requestAutoSpamState();
  }

  void _updateOpacity(double value) {
    setState(() {
      _opacity = value;
    });
    _sendGhostSettings({'opacity': value});
  }

  void _updateLocked(bool value) {
    setState(() {
      _locked = value;
    });
    _sendGhostSettings({'locked': value});
  }

  void _updateSubtitleVisibility(bool value) {
    setState(() {
      _showSubtitle = value;
    });
    _sendGhostSettings({'subtitleEnable': value});
  }

  void _updatePassthroughEnabled(bool value) {
    setState(() {
      _passthroughEnabled = value;
    });
    _schedulePassthroughSync();
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

  Color _applyPanelOpacity(Color color) {
    final alpha = (color.a * 255 * _opacity).round().clamp(0, 255);
    return color.withAlpha(alpha);
  }

  double? _measureWidgetHeight(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return null;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.size.height;
    }
    return null;
  }

  void _schedulePassthroughSync() {
    if (_passthroughSyncScheduled) {
      return;
    }
    _passthroughSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passthroughSyncScheduled = false;
      if (!mounted) {
        return;
      }
      unawaited(_syncPassthroughRegion());
    });
  }

  Future<void> _syncPassthroughRegion() async {
    final enabled =
        _passthroughEnabled && !_passthroughPausedForOverlay && !_collapsed;
    final topHeight = enabled
        ? (_measureWidgetHeight(_windowBarKey) ?? _windowBarHeight)
        : 0.0;
    final bottomHeight =
        enabled ? (_measureWidgetHeight(_inputBarKey) ?? 56.0) : 0.0;
    final changed = _lastPassthroughEnabled != enabled ||
        (_lastPassthroughTopHeight - topHeight).abs() > 0.5 ||
        (_lastPassthroughBottomHeight - bottomHeight).abs() > 0.5;
    if (!changed) {
      return;
    }
    _lastPassthroughEnabled = enabled;
    _lastPassthroughTopHeight = topHeight;
    _lastPassthroughBottomHeight = bottomHeight;
    try {
      await _windowChannel.invokeMethod(
        'setPartialPassthroughRegion',
        {
          'enabled': enabled,
          'topHeight': topHeight,
          'bottomHeight': bottomHeight,
        },
      );
    } catch (_) {}
  }

  Rect _displayVisibleBounds(Display display) {
    final position = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  double _distanceToRect(Rect rect, Offset point) {
    final dx = point.dx < rect.left
        ? rect.left - point.dx
        : point.dx > rect.right
            ? point.dx - rect.right
            : 0.0;
    final dy = point.dy < rect.top
        ? rect.top - point.dy
        : point.dy > rect.bottom
            ? point.dy - rect.bottom
            : 0.0;
    return (dx * dx) + (dy * dy);
  }

  Future<Rect> _resolveVisibleBoundsForWindow(Rect bounds) async {
    final displays = await screenRetriever.getAllDisplays();
    if (displays.isEmpty) {
      final display = await screenRetriever.getPrimaryDisplay();
      return _displayVisibleBounds(display);
    }
    final center = bounds.center;
    Display? bestDisplay;
    double? bestDistance;
    for (final display in displays) {
      final visibleBounds = _displayVisibleBounds(display);
      final distance = _distanceToRect(visibleBounds, center);
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestDisplay = display;
      }
    }
    return _displayVisibleBounds(bestDisplay ?? displays.first);
  }

  Future<void> _collapseWindow() async {
    if (_miniButtonCollapsed) {
      return;
    }
    final bounds = await WindowManagerPlus.current.getBounds();
    if (!_collapsed) {
      _expandedBounds = bounds;
    }
    final visibleBounds = await _resolveVisibleBoundsForWindow(bounds);
    const targetWidth = _collapsedButtonWindowWidth;
    const targetHeight = _collapsedButtonWindowHeight;
    final targetTop = bounds.top.clamp(
      visibleBounds.top + _edgeInset,
      visibleBounds.bottom - targetHeight - _edgeInset,
    );
    final targetLeft = (bounds.right - targetWidth).clamp(
      visibleBounds.left + _edgeInset,
      visibleBounds.right - targetWidth - _edgeInset,
    );
    await _setCollapsedConstraints(
      minWidth: targetWidth,
      minHeight: targetHeight,
      maxWidth: targetWidth,
      maxHeight: targetHeight,
    );
    await WindowManagerPlus.current.setIgnoreMouseEvents(false);
    await WindowManagerPlus.current.show();
    setState(() {
      _collapseMode = _GhostWindowCollapseMode.miniButton;
    });
    await WindowManagerPlus.current.setBounds(
      Rect.fromLTWH(targetLeft, targetTop, targetWidth, targetHeight),
      animate: false,
    );
  }

  Future<void> _expandWindow() async {
    if (!_collapsed) {
      return;
    }
    final currentBounds = await WindowManagerPlus.current.getBounds();
    final visibleBounds = await _resolveVisibleBoundsForWindow(currentBounds);
    final fallbackWidth = 400.0.clamp(260.0, visibleBounds.width - 24.0);
    final fallbackHeight = 300.0.clamp(180.0, visibleBounds.height - 24.0);
    final targetBounds = _expandedBounds ??
        Rect.fromLTWH(
          visibleBounds.left + _edgeInset,
          currentBounds.top.clamp(
            visibleBounds.top + _edgeInset,
            visibleBounds.bottom - fallbackHeight - _edgeInset,
          ),
          fallbackWidth,
          fallbackHeight,
        );
    final targetWidth =
        targetBounds.width.clamp(260.0, visibleBounds.width - 24.0).toDouble();
    final targetHeight = targetBounds.height
        .clamp(180.0, visibleBounds.height - 24.0)
        .toDouble();
    final targetLeft = targetBounds.left.clamp(
      visibleBounds.left + _edgeInset,
      visibleBounds.right - targetWidth - _edgeInset,
    );
    final targetTop = targetBounds.top.clamp(
      visibleBounds.top + _edgeInset,
      visibleBounds.bottom - targetHeight - _edgeInset,
    );
    await _restoreWindowConstraints();
    setState(() {
      _collapseMode = _GhostWindowCollapseMode.none;
    });
    await WindowManagerPlus.current.setBounds(
      Rect.fromLTWH(targetLeft, targetTop, targetWidth, targetHeight),
      animate: true,
    );
  }

  Future<void> _activateCollapsedButton() async {
    try {
      await WindowManagerPlus.current.setIgnoreMouseEvents(false);
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
      await WindowManagerPlus.current.setAlwaysOnTop(true);
    } catch (_) {}
    await _expandWindow();
  }

  @override
  void onWindowMoved([int? windowId]) {
    if (_collapsed) {
      return;
    }
    unawaited(() async {
      _expandedBounds = await WindowManagerPlus.current.getBounds();
    }());
  }

  @override
  void onWindowResized([int? windowId]) {
    _schedulePassthroughSync();
    if (_collapsed) {
      return;
    }
    unawaited(() async {
      _expandedBounds = await WindowManagerPlus.current.getBounds();
    }());
  }

  void _requestShowEmotions() {
    WindowManagerPlus.current.invokeMethodToWindow(
      0,
      'get_emoticons',
      {},
    );
  }

  void _requestAutoSpam() {
    _pendingAutoSpamPanelOpen = true;
    _requestAutoSpamState();
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

  Widget _buildWindowBar(
    ThemeData theme,
    Color chromeFill,
    Color outlineColor,
    Color muted,
  ) {
    return Container(
      key: _windowBarKey,
      height: _windowBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: chromeFill,
        border: Border(
          bottom: BorderSide(color: outlineColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _locked
                ? Container(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "已锁定",
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  )
                : const DragToMoveArea(
                    child: SizedBox.expand(),
                  ),
          ),
          IconButton(
            tooltip: _showSubtitle ? "隐藏字幕" : "显示字幕",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: Icon(
              _showSubtitle
                  ? Icons.closed_caption_outlined
                  : Icons.closed_caption_disabled_outlined,
              size: 18,
              color: _showSubtitle ? theme.colorScheme.primary : null,
            ),
            onPressed: () => _updateSubtitleVisibility(!_showSubtitle),
          ),
          IconButton(
            tooltip: _locked ? "关闭锁定" : "开启锁定",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: Icon(
              _locked ? Icons.lock : Icons.lock_open_outlined,
              size: 18,
              color: _locked ? theme.colorScheme.primary : null,
            ),
            onPressed: () => _updateLocked(!_locked),
          ),
          IconButton(
            tooltip: _passthroughEnabled ? "关闭透传" : "开启透传",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: Icon(
              _passthroughEnabled
                  ? Icons.ads_click_outlined
                  : Icons.block_outlined,
              size: 18,
              color: _passthroughEnabled ? theme.colorScheme.primary : null,
            ),
            onPressed: () => _updatePassthroughEnabled(!_passthroughEnabled),
          ),
          IconButton(
            tooltip: "收起",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(Icons.remove, size: 18),
            onPressed: _collapseWindow,
          ),
          IconButton(
            tooltip: "设置",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(Icons.settings, size: 18),
            onPressed: _showSettingsSheet,
          ),
          IconButton(
            tooltip: "退出",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(Icons.close, size: 18),
            onPressed: _requestExitGhostMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedButton(
    Color chromeFill,
    Color outlineColor,
    Color iconColor,
    bool panelIsDark,
  ) {
    final buttonIconColor =
        panelIsDark ? Colors.white.withAlpha(235) : Colors.black.withAlpha(210);
    final capsuleFill = _applyPanelOpacity(
      panelIsDark ? const Color(0xE632363C) : const Color(0xE63A4048),
    );
    final expandFill = Color.alphaBlend(
      panelIsDark ? Colors.white.withAlpha(16) : Colors.white.withAlpha(20),
      capsuleFill,
    );
    final gripColor = Colors.white.withAlpha(panelIsDark ? 164 : 150);
    final dividerColor = Colors.white.withAlpha(panelIsDark ? 42 : 52);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _collapsedButtonWindowWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : _collapsedButtonWindowHeight;
        final leftInset = width <= 80 ? 6.0 : 7.0;
        final rightInset = width <= 80 ? 2.0 : 3.0;
        final verticalInset = height <= 34 ? 2.0 : 3.0;
        final gap = width <= 80 ? 2.0 : 3.0;
        final dividerInset = height <= 34 ? 3.0 : 4.0;
        final expandButtonSize = (height - (verticalInset * 2))
            .clamp(22.0, _collapsedExpandButtonSize)
            .toDouble();
        final outerRadius = BorderRadius.circular(_collapsedButtonRadius);

        return MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: ClipRRect(
            borderRadius: outerRadius,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: capsuleFill,
                borderRadius: outerRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(panelIsDark ? 60 : 36),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                leftInset,
                verticalInset,
                rightInset,
                verticalInset,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.move,
                      child: DragToMoveArea(
                        child: SizedBox(
                          height: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == 2 ? 0 : 4,
                                ),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: index == 1
                                        ? gripColor
                                        : gripColor.withAlpha(
                                            panelIsDark ? 118 : 102,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: EdgeInsets.symmetric(vertical: dividerInset),
                    color: dividerColor,
                  ),
                  SizedBox(width: gap),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        unawaited(_activateCollapsedButton());
                      },
                      child: Container(
                        width: expandButtonSize,
                        height: expandButtonSize,
                        decoration: BoxDecoration(
                          color: expandFill,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.call_made_rounded,
                            color: buttonIconColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                        crossAxisCount: 3,
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

  void _showAutoSpamEmotionsPanel(List<dynamic> emoticonPackages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DefaultTabController(
              length: emoticonPackages.length,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "自动发送表情（${_autoSpamEmotions.length}）",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _autoSpamEmotions = [];
                            });
                            _setAutoSpamState({'emotions': []});
                            setSheetState(() {});
                          },
                          child: const Text("清空"),
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
                              : const Icon(
                                  Icons.emoji_emotions_outlined,
                                  size: 20,
                                ),
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
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          padding: const EdgeInsets.all(12),
                          itemCount: emoticonList.length,
                          itemBuilder: (context, index) {
                            final emoticon = emoticonList[index];
                            final id = _getAutoSpamEmoticonId(emoticon, index);
                            final text =
                                _getAutoSpamEmoticonText(emoticon).toString();
                            final url =
                                _getAutoSpamEmoticonUrl(emoticon).toString();
                            final options =
                                _getAutoSpamEmoticonOptions(emoticon);
                            final selected = _autoSpamEmotions
                                .any((item) => item['id']?.toString() == id);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  final list = List<Map<String, dynamic>>.from(
                                    _autoSpamEmotions,
                                  );
                                  final idx = list.indexWhere(
                                      (item) => item['id']?.toString() == id);
                                  if (idx >= 0) {
                                    list.removeAt(idx);
                                  } else {
                                    list.add({
                                      'id': id,
                                      'text': text,
                                      'url': url,
                                      if (options != null)
                                        'emoticonOptions': options,
                                    });
                                  }
                                  _autoSpamEmotions = list;
                                });
                                _setAutoSpamState(
                                    {'emotions': _autoSpamEmotions});
                                setSheetState(() {});
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.withAlpha(60),
                                  ),
                                  color: selected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withAlpha(24)
                                      : Colors.transparent,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Stack(
                                  children: [
                                    Align(
                                      child: NetImage(
                                        url,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    if (selected)
                                      const Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 16,
                                        ),
                                      ),
                                  ],
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
      },
    );
  }

  String _getAutoSpamEmoticonId(dynamic emoticon, int index) {
    if (emoticon is Map) {
      final id =
          emoticon['emoticon_unique'] ?? emoticon['text'] ?? emoticon['id'];
      final value = id?.toString() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return "index_$index";
  }

  String _getAutoSpamEmoticonText(dynamic emoticon) {
    if (emoticon is Map) {
      return (emoticon['emoticon_unique'] ?? emoticon['text'] ?? '').toString();
    }
    return "";
  }

  String _getAutoSpamEmoticonUrl(dynamic emoticon) {
    if (emoticon is Map) {
      return (emoticon['url'] ?? '').toString();
    }
    return "";
  }

  Map<String, dynamic>? _getAutoSpamEmoticonOptions(dynamic emoticon) {
    if (emoticon is Map && emoticon['emoticon_options'] is Map) {
      return Map<String, dynamic>.from(emoticon['emoticon_options']);
    }
    return null;
  }

  void _showAutoSpamPanel() {
    _showAutoSpamBottomSheet(
      title: "自动发送",
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              _buildAutoSpamEntry(
                icon: Icons.message_outlined,
                title: "文字弹幕",
                running: _autoSpamTextRunning,
                onTap: () {
                  Navigator.of(context).pop();
                  _showAutoSpamTextPanel();
                },
              ),
              Container(
                width: 1,
                height: 52,
                color: Colors.grey.withAlpha(40),
              ),
              _buildAutoSpamEntry(
                icon: Icons.emoji_emotions_outlined,
                title: "表情包",
                running: _autoSpamEmotionRunning,
                onTap: () {
                  Navigator.of(context).pop();
                  _showAutoSpamEmotionPanel();
                },
              ),
              Container(
                width: 1,
                height: 52,
                color: Colors.grey.withAlpha(40),
              ),
              _buildAutoSpamEntry(
                icon: Icons.bookmarks_outlined,
                title: "收藏夹",
                running: _autoSpamFavoritesRunning,
                onTap: () {
                  Navigator.of(context).pop();
                  _showAutoSpamFavoritesPanel();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAutoSpamTextPanel() {
    _autoSpamTextController.text = _autoSpamTextMsg;
    _showAutoSpamBottomSheet(
      title: "文字弹幕",
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildAutoSpamSectionHeader(
                "文字弹幕",
                _autoSpamTextRunning,
                () {
                  setState(() {
                    _autoSpamTextRunning = true;
                  });
                  _sendAutoSpamAction('text', true);
                  setSheetState(() {});
                },
                () {
                  setState(() {
                    _autoSpamTextRunning = false;
                  });
                  _sendAutoSpamAction('text', false);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _autoSpamTextController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "输入自动发送弹幕内容",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    _autoSpamTextMsg = value;
                  });
                  _setAutoSpamState({'textMsg': value});
                },
              ),
              const SizedBox(height: 8),
              _buildNumberRow(
                label: "发送间隔(秒)",
                value: _autoSpamTextInterval,
                min: 1,
                max: 300,
                onChanged: (value) {
                  setState(() {
                    _autoSpamTextInterval = value;
                  });
                  _setAutoSpamState({'textInterval': value});
                  setSheetState(() {});
                },
              ),
              _buildNumberRow(
                label: "单条长度",
                value: _autoSpamTextChunkSize,
                min: 5,
                max: 60,
                onChanged: (value) {
                  setState(() {
                    _autoSpamTextChunkSize = value;
                  });
                  _setAutoSpamState({'textChunkSize': value});
                  setSheetState(() {});
                },
              ),
              _buildNumberRow(
                label: "持续时长(秒)",
                value: _autoSpamTextDuration,
                min: 0,
                max: 3600,
                onChanged: (value) {
                  setState(() {
                    _autoSpamTextDuration = value;
                  });
                  _setAutoSpamState({'textDuration': value});
                  setSheetState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAutoSpamEmotionPanel() {
    _showAutoSpamBottomSheet(
      title: "表情包",
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildAutoSpamSectionHeader(
                "表情包",
                _autoSpamEmotionRunning,
                () {
                  setState(() {
                    _autoSpamEmotionRunning = true;
                  });
                  _sendAutoSpamAction('emotion', true);
                  setSheetState(() {});
                },
                () {
                  setState(() {
                    _autoSpamEmotionRunning = false;
                  });
                  _sendAutoSpamAction('emotion', false);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("已选 ${_autoSpamEmotions.length} 个"),
                trailing: TextButton(
                  onPressed: () {
                    _autoSpamEmotionsMode = true;
                    _requestShowEmotions();
                  },
                  child: const Text("选择表情"),
                ),
              ),
              _buildNumberRow(
                label: "发送间隔(秒)",
                value: _autoSpamEmotionInterval,
                min: 1,
                max: 300,
                onChanged: (value) {
                  setState(() {
                    _autoSpamEmotionInterval = value;
                  });
                  _setAutoSpamState({'emotionInterval': value});
                  setSheetState(() {});
                },
              ),
              _buildNumberRow(
                label: "持续时长(秒)",
                value: _autoSpamEmotionDuration,
                min: 0,
                max: 3600,
                onChanged: (value) {
                  setState(() {
                    _autoSpamEmotionDuration = value;
                  });
                  _setAutoSpamState({'emotionDuration': value});
                  setSheetState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAutoSpamFavoritesPanel() {
    final currentMsg =
        _autoSpamFavorites[_autoSpamFavoritesIndex]['msg']?.toString() ?? '';
    _autoSpamFavoriteController.text = currentMsg;
    _showAutoSpamBottomSheet(
      title: "收藏夹",
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          void updateFavoritesIndex(int index) {
            if (index < 0 || index >= _autoSpamFavorites.length) {
              return;
            }
            setState(() {
              _autoSpamFavoritesIndex = index;
            });
            _autoSpamFavoriteController.text =
                _autoSpamFavorites[index]['msg']?.toString() ?? '';
            _setAutoSpamState({'favoritesIndex': index});
            setSheetState(() {});
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildAutoSpamSectionHeader(
                "收藏夹",
                _autoSpamFavoritesRunning,
                () {
                  setState(() {
                    _autoSpamFavoritesRunning = true;
                  });
                  _sendAutoSpamAction('favorites', true);
                  setSheetState(() {});
                },
                () {
                  setState(() {
                    _autoSpamFavoritesRunning = false;
                  });
                  _sendAutoSpamAction('favorites', false);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      final nextId = _autoSpamFavorites.isEmpty
                          ? 1
                          : (_autoSpamFavorites
                                  .map((e) => e['id'] as int? ?? 0)
                                  .reduce((a, b) => a > b ? a : b) +
                              1);
                      setState(() {
                        _autoSpamFavorites.add({
                          'id': nextId,
                          'name': '第${_autoSpamFavorites.length + 1}组',
                          'msg': '',
                        });
                        _autoSpamFavoritesIndex = _autoSpamFavorites.length - 1;
                      });
                      _autoSpamFavoriteController.text = '';
                      _setAutoSpamState({
                        'favorites': _autoSpamFavorites,
                        'favoritesIndex': _autoSpamFavoritesIndex,
                      });
                      setSheetState(() {});
                    },
                    child: const Text("新增分组"),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      if (_autoSpamFavorites.length <= 1) {
                        return;
                      }
                      setState(() {
                        _autoSpamFavorites.removeAt(_autoSpamFavoritesIndex);
                        if (_autoSpamFavoritesIndex >=
                            _autoSpamFavorites.length) {
                          _autoSpamFavoritesIndex =
                              _autoSpamFavorites.length - 1;
                        }
                      });
                      _autoSpamFavoriteController.text =
                          _autoSpamFavorites[_autoSpamFavoritesIndex]['msg']
                                  ?.toString() ??
                              '';
                      _setAutoSpamState({
                        'favorites': _autoSpamFavorites,
                        'favoritesIndex': _autoSpamFavoritesIndex,
                      });
                      setSheetState(() {});
                    },
                    child: const Text("删除分组"),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _autoSpamFavorites.length,
                  itemBuilder: (context, index) {
                    final selected = index == _autoSpamFavoritesIndex;
                    final name =
                        _autoSpamFavorites[index]['name']?.toString() ??
                            '第${index + 1}组';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: selected,
                        label: Text(name),
                        onSelected: (_) {
                          updateFavoritesIndex(index);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _autoSpamFavoriteController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "输入当前分组弹幕内容",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    _autoSpamFavorites[_autoSpamFavoritesIndex]['msg'] = value;
                  });
                  _setAutoSpamState({'favorites': _autoSpamFavorites});
                },
              ),
              const SizedBox(height: 8),
              _buildNumberRow(
                label: "发送间隔(秒)",
                value: _autoSpamFavoritesInterval,
                min: 1,
                max: 300,
                onChanged: (value) {
                  setState(() {
                    _autoSpamFavoritesInterval = value;
                  });
                  _setAutoSpamState({'favoritesInterval': value});
                  setSheetState(() {});
                },
              ),
              _buildNumberRow(
                label: "持续时长(秒)",
                value: _autoSpamFavoritesDuration,
                min: 0,
                max: 3600,
                onChanged: (value) {
                  setState(() {
                    _autoSpamFavoritesDuration = value;
                  });
                  _setAutoSpamState({'favoritesDuration': value});
                  setSheetState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAutoSpamBottomSheet({
    required String title,
    required Widget child,
  }) {
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
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                Expanded(
                  child: child,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAutoSpamEntry({
    required IconData icon,
    required String title,
    required bool running,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(title),
              const SizedBox(height: 4),
              Text(
                running ? "运行中" : "已停止",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSpamSectionHeader(
    String title,
    bool running,
    VoidCallback onStart,
    VoidCallback onStop,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "$title（${running ? '运行中' : '已停止'}）",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: running ? null : onStart,
          child: const Text("开始"),
        ),
        TextButton(
          onPressed: running ? onStop : null,
          child: const Text("停止"),
        ),
      ],
    );
  }

  Widget _buildNumberRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value <= min ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline, size: 18),
        ),
        SizedBox(width: 36, child: Text(value.toString())),
        IconButton(
          onPressed: value >= max ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline, size: 18),
        ),
      ],
    );
  }

  void _showSettingsSheet() {
    int alpha = (_panelColor >> 24) & 0xFF;
    int red = (_panelColor >> 16) & 0xFF;
    int green = (_panelColor >> 8) & 0xFF;
    int blue = _panelColor & 0xFF;
    if (!_passthroughPausedForOverlay) {
      setState(() {
        _passthroughPausedForOverlay = true;
      });
      _schedulePassthroughSync();
      unawaited(_syncPassthroughRegion());
    }
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
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () {
                              final value =
                                  AppColors.ghostLightPanel.toARGB32();
                              alpha = (value >> 24) & 0xFF;
                              red = (value >> 16) & 0xFF;
                              green = (value >> 8) & 0xFF;
                              blue = value & 0xFF;
                              _updatePanelColor(value);
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.light_mode_outlined),
                            label: const Text("浅色面板"),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              final value = AppColors.ghostDarkPanel.toARGB32();
                              alpha = (value >> 24) & 0xFF;
                              red = (value >> 16) & 0xFF;
                              green = (value >> 8) & 0xFF;
                              blue = value & 0xFF;
                              _updatePanelColor(value);
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.dark_mode_outlined),
                            label: const Text("深色面板"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _applyPanelOpacity(Color(_panelColor)),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          border: Border.all(color: Colors.grey.withAlpha(60)),
                        ),
                        alignment: Alignment.center,
                        child: const Text("当前面板预览"),
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
                          const SizedBox(width: 64, child: Text("音量")),
                          Expanded(
                            child: Slider(
                              value: _volume,
                              min: 0,
                              max: 100,
                              onChanged: (value) {
                                setState(() {
                                  _volume = value;
                                });
                                WindowManagerPlus.current.invokeMethodToWindow(
                                  0,
                                  'ghost_volume',
                                  {'value': value},
                                );
                                setSheetState(() {});
                              },
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text("${_volume.toInt()}%"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 96, child: Text("统一弹幕颜色")),
                          Expanded(
                            child: Text(
                              "开启后全部弹幕使用默认文字颜色",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.withAlpha(180),
                              ),
                            ),
                          ),
                          Switch(
                            value: _useDefaultDanmakuColor,
                            onChanged: (value) {
                              setState(() {
                                _useDefaultDanmakuColor = value;
                              });
                              setSheetState(() {});
                            },
                          ),
                        ],
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
    ).whenComplete(() {
      if (!mounted || !_passthroughPausedForOverlay) {
        return;
      }
      setState(() {
        _passthroughPausedForOverlay = false;
      });
      _schedulePassthroughSync();
      unawaited(_syncPassthroughRegion());
    });
  }

  @override
  Widget build(BuildContext context) {
    final weightIndex =
        _fontWeight.clamp(0, FontWeight.values.length - 1).toInt();
    final panelColor = Color(_panelColor);
    final panelIsDark = panelColor.computeLuminance() < 0.4;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: panelIsDark ? Brightness.dark : Brightness.light,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: panelIsDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
    );

    final fontFamily = AppStyle.defaultFontFamily;

    final onPanel =
        panelIsDark ? const Color(0xFFE9EEF5) : const Color(0xFF0B0F14);
    final muted =
        panelIsDark ? Colors.white.withAlpha(160) : Colors.black.withAlpha(140);
    final borderColor =
        panelIsDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(36);

    final chromeFillBase = Color.alphaBlend(
      panelIsDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
      panelColor,
    );
    final inputFillBase = Color.alphaBlend(
      panelIsDark ? Colors.white.withAlpha(14) : Colors.black.withAlpha(10),
      panelColor,
    );
    final shellFill = _applyPanelOpacity(panelColor);
    final chromeFill = _applyPanelOpacity(chromeFillBase);
    final inputFill = _applyPanelOpacity(inputFillBase);
    final outlineColor = borderColor.withAlpha(
      (borderColor.a * 255 * _opacity).round().clamp(0, 255),
    );

    final theme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
      dividerColor: borderColor,
      iconTheme: IconThemeData(color: onPanel),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onPanel,
        ),
      ),
    );

    Color normalizeItemColor(Color color) {
      final lum = color.computeLuminance();
      if (!panelIsDark && lum > 0.86) {
        return onPanel;
      }
      if (panelIsDark && lum < 0.16) {
        return onPanel;
      }
      return color;
    }

    _schedulePassthroughSync();

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _miniButtonCollapsed
            ? ClipRRect(
                borderRadius: BorderRadius.circular(_collapsedButtonRadius),
                child: _buildCollapsedButton(
                  chromeFill,
                  outlineColor,
                  onPanel,
                  panelIsDark,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.zero,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: shellFill,
                    border: Border.all(color: outlineColor),
                  ),
                  child: Column(
                    children: [
                      _buildWindowBar(
                        theme,
                        chromeFill,
                        outlineColor,
                        muted,
                      ),
                      if (_showSubtitle && _subtitleText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _applyPanelOpacity(
                                Colors.black.withAlpha(170),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: scheme.primary.withAlpha(220),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              _subtitleText,
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: 1.25,
                                fontWeight: _subtitleIsPartial
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                color: Colors.white,
                                fontFamily: fontFamily,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(120),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final baseColor = _useDefaultDanmakuColor
                                  ? onPanel
                                  : normalizeItemColor(item.color);
                              final color =
                                  baseColor.withValues(alpha: _danmakuOpacity);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  item.text,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: _fontSize,
                                    height: 1.25,
                                    fontWeight: FontWeight.values[weightIndex],
                                    fontFamily: fontFamily,
                                    shadows: [
                                      Shadow(
                                        color: panelIsDark
                                            ? Colors.black.withAlpha(140)
                                            : Colors.black.withAlpha(90),
                                        offset: const Offset(0, 1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        key: _inputBarKey,
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                        decoration: BoxDecoration(
                          color: chromeFill,
                          border: Border(
                            top: BorderSide(color: outlineColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _requestShowEmotions,
                              tooltip: "表情包",
                              constraints: const BoxConstraints(
                                minWidth: _inputIconButtonSize,
                                minHeight: _inputIconButtonSize,
                              ),
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                size: 17,
                              ),
                            ),
                            IconButton(
                              onPressed: _requestAutoSpam,
                              tooltip: "自动发送",
                              constraints: const BoxConstraints(
                                minWidth: _inputIconButtonSize,
                                minHeight: _inputIconButtonSize,
                              ),
                              icon: const Icon(Icons.auto_mode, size: 17),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: _inputActionHeight,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: inputFill,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: outlineColor.withAlpha(
                                      panelIsDark ? 90 : 110,
                                    ),
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: TextField(
                                  controller: _inputController,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TextStyle(color: onPanel),
                                  decoration: InputDecoration(
                                    hintText: "发送弹幕...",
                                    hintStyle: TextStyle(color: muted),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: _inputActionHeight,
                              child: FilledButton.tonal(
                                onPressed: _sendMessage,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("发送"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
