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
  bool _initialRefreshTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialRefresh();
    });
  }

  @override
  void didUpdateWidget(covariant PagedRefreshContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      _initialRefreshTriggered = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialRefresh();
    });
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

    return SmartRefresher(
      controller: widget.pageController.refreshController,
      enablePullDown: true,
      enablePullUp: widget.pageController.list.isNotEmpty,
      header: const MaterialClassicHeader(),
      footer: const ClassicFooter(),
      onRefresh: _handleRefresh,
      onLoading: _handleLoadMore,
      child: widget.builder(widget.pageController.scrollController, physics),
    );
  }
}
