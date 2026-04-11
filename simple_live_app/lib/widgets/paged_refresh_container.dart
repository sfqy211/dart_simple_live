import 'package:flutter/material.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';

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
  static const double _loadMoreThreshold = 240;

  bool _initialRefreshTriggered = false;
  bool _loadMoreQueued = false;
  bool _postFrameCheckQueued = false;

  @override
  void initState() {
    super.initState();
    widget.pageController.scrollController.addListener(_handleScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialRefresh();
      _scheduleLoadMoreCheck();
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
      _loadMoreQueued = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialRefresh();
      _scheduleLoadMoreCheck();
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
    await widget.pageController.refreshData();
    _scheduleLoadMoreCheck();
  }

  void _handleScrollChanged() {
    _scheduleLoadMoreCheck();
  }

  void _scheduleLoadMoreCheck() {
    if (!mounted || _postFrameCheckQueued) {
      return;
    }
    _postFrameCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameCheckQueued = false;
      _maybeLoadMore();
    });
  }

  bool _canTriggerLoadMore() {
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

    return position.extentAfter <= _loadMoreThreshold;
  }

  void _maybeLoadMore() {
    if (!mounted || _loadMoreQueued || !_canTriggerLoadMore()) {
      return;
    }

    _loadMoreQueued = true;
    widget.pageController.loadData().whenComplete(() {
      if (!mounted) {
        return;
      }
      _loadMoreQueued = false;
      _scheduleLoadMoreCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    );
    _scheduleLoadMoreCheck();

    return RefreshIndicator(
      onRefresh: widget.pageController.refreshData,
      notificationPredicate: (notification) => notification.depth == 0,
      child: widget.builder(widget.pageController.scrollController, physics),
    );
  }
}
