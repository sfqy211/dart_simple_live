import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:smart_refresher/smart_refresher.dart';

typedef PagedScrollableBuilder = Widget Function(
  ScrollController scrollController,
  ScrollPhysics physics,
);

class PagedRefreshContainer extends StatefulWidget {
  final BasePageController pageController;
  final bool firstRefresh;
  final PagedScrollableBuilder builder;

  const PagedRefreshContainer({
    required this.pageController,
    required this.builder,
    this.firstRefresh = false,
    super.key,
  });

  @override
  State<PagedRefreshContainer> createState() => _PagedRefreshContainerState();
}

class _PagedRefreshContainerState extends State<PagedRefreshContainer> {
  static const double _loadMoreTriggerExtent = 240;
  static const double _wheelRefreshTriggerOffset = 120;

  bool _initialRefreshTriggered = false;
  bool _autoLoadQueued = false;
  bool _refreshQueued = false;
  double _topWheelOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.scrollController.addListener(_handleScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialRefresh();
    });
  }

  @override
  void didUpdateWidget(covariant PagedRefreshContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController.scrollController.removeListener(
        _handleScrollChanged,
      );
      widget.pageController.scrollController.addListener(_handleScrollChanged);
      _initialRefreshTriggered = false;
      _autoLoadQueued = false;
      _refreshQueued = false;
      _topWheelOffset = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialRefresh();
    });
  }

  @override
  void dispose() {
    widget.pageController.scrollController.removeListener(_handleScrollChanged);
    super.dispose();
  }

  Future<void> _triggerInitialRefresh() async {
    if (!mounted || !widget.firstRefresh || _initialRefreshTriggered) {
      return;
    }
    if (widget.pageController.loadding ||
        widget.pageController.list.isNotEmpty) {
      _initialRefreshTriggered = true;
      return;
    }
    _initialRefreshTriggered = true;
    await _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    final status = await widget.pageController.refreshData();
    final controller = widget.pageController.refreshController;
    switch (status) {
      case PageLoadStatus.success:
      case PageLoadStatus.empty:
      case PageLoadStatus.noMore:
      case PageLoadStatus.skipped:
        controller.refreshCompleted();
        controller.resetNoData();
        break;
      case PageLoadStatus.error:
        controller.refreshFailed();
        break;
    }
  }

  void _handleScrollChanged() {
    if (_autoLoadQueued || !_canAutoLoadMore()) {
      return;
    }

    _autoLoadQueued = true;
    _handleLoadMore().whenComplete(() {
      if (!mounted) {
        return;
      }
      _autoLoadQueued = false;
    });
  }

  bool _canAutoLoadMore() {
    if (!widget.pageController.canLoadMore.value ||
        widget.pageController.loadding ||
        widget.pageController.pageEmpty.value ||
        widget.pageController.pageError.value) {
      return false;
    }

    final scrollController = widget.pageController.scrollController;
    if (!scrollController.hasClients) {
      return false;
    }

    final position = scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return false;
    }

    return position.extentAfter <= _loadMoreTriggerExtent;
  }

  bool _isAtTop() {
    final scrollController = widget.pageController.scrollController;
    if (!scrollController.hasClients) {
      return false;
    }

    final position = scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return false;
    }

    return position.pixels <= position.minScrollExtent + 1;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    final delta = event.scrollDelta.dy;
    if (delta >= 0) {
      _topWheelOffset = 0;
      return;
    }

    if (!_isAtTop() || widget.pageController.loadding || _refreshQueued) {
      _topWheelOffset = 0;
      return;
    }

    _topWheelOffset += delta.abs();
    if (_topWheelOffset < _wheelRefreshTriggerOffset) {
      return;
    }

    _topWheelOffset = 0;
    _refreshQueued = true;
    _handleRefresh().whenComplete(() {
      if (!mounted) {
        return;
      }
      _refreshQueued = false;
    });
  }

  Future<void> _handleLoadMore() async {
    final status = await widget.pageController.loadData();
    final controller = widget.pageController.refreshController;
    switch (status) {
      case PageLoadStatus.success:
      case PageLoadStatus.skipped:
        controller.loadComplete();
        break;
      case PageLoadStatus.noMore:
      case PageLoadStatus.empty:
        controller.loadNoData();
        break;
      case PageLoadStatus.error:
        controller.loadFailed();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: SmartRefresher(
        controller: widget.pageController.refreshController,
        enablePullDown: true,
        enablePullUp: widget.pageController.list.isNotEmpty,
        header: const MaterialClassicHeader(),
        footer: const ClassicFooter(),
        onRefresh: _handleRefresh,
        onLoading: _handleLoadMore,
        child: widget.builder(widget.pageController.scrollController, physics),
      ),
    );
  }
}
