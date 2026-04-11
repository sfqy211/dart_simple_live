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

  void _triggerInitialRefresh() {
    if (!mounted || !widget.firstRefresh || _initialRefreshTriggered) {
      return;
    }
    if (widget.pageController.loadding || widget.pageController.list.isNotEmpty) {
      _initialRefreshTriggered = true;
      return;
    }
    _initialRefreshTriggered = true;
    widget.pageController.refreshData();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (!widget.pageController.canLoadMore.value ||
        widget.pageController.loadding ||
        widget.pageController.pageEmpty.value ||
        widget.pageController.pageError.value) {
      return false;
    }
    if (notification.metrics.extentAfter <= 180) {
      widget.pageController.loadData();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    );

    return RefreshIndicator(
      onRefresh: widget.pageController.refreshData,
      notificationPredicate: (notification) => notification.depth == 0,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: widget.builder(widget.pageController.scrollController, physics),
      ),
    );
  }
}
