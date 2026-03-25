import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/category/category_list_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/status/app_empty_widget.dart';
import 'package:simple_live_app/widgets/status/app_error_widget.dart';
import 'package:simple_live_app/widgets/status/app_loadding_widget.dart';
import 'package:simple_live_core/simple_live_core.dart';

class CategoryListView extends StatefulWidget {
  final String tag;

  const CategoryListView(this.tag, {Key? key}) : super(key: key);

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  String? selectedCategoryId;

  CategoryListController get controller =>
      Get.find<CategoryListController>(tag: widget.tag);

  @override
  void initState() {
    super.initState();
    if (controller.list.isEmpty && !controller.pageLoadding.value) {
      controller.refreshData();
    }
  }

  void _backToPrimary() {
    setState(() {
      selectedCategoryId = null;
    });
    _scrollToTop();
  }

  void _openCategory(AppLiveCategory item) {
    setState(() {
      selectedCategoryId = item.id;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!controller.scrollController.hasClients) {
      return;
    }
    controller.scrollController.jumpTo(0);
  }

  AppLiveCategory? _resolveSelectedCategory(List<AppLiveCategory> categories) {
    if (selectedCategoryId == null) {
      return null;
    }

    final matched =
        categories.where((item) => item.id == selectedCategoryId).firstOrNull;
    if (matched != null) {
      return matched;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        selectedCategoryId = null;
      });
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedCategoryId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedCategoryId != null) {
          _backToPrimary();
        }
      },
      child: KeepAliveWrapper(
        child: Obx(() {
          final categories = controller.list.toList();
          final selectedCategory = _resolveSelectedCategory(categories);
          final content = _buildContent(categories, selectedCategory);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: KeyedSubtree(
              key: ValueKey(
                "${selectedCategory?.id ?? 'primary'}-${categories.length}-${controller.pageLoadding.value}-${controller.pageError.value}",
              ),
              child: content,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent(
    List<AppLiveCategory> categories,
    AppLiveCategory? selectedCategory,
  ) {
    if (controller.pageLoadding.value && categories.isEmpty) {
      return const AppLoaddingWidget();
    }

    if (controller.pageError.value && categories.isEmpty) {
      return _CategoryStatusScrollView(
        controller: controller.scrollController,
        child: AppErrorWidget(
          errorMsg: controller.errorMsg.value,
          onRefresh: controller.refreshData,
        ),
      );
    }

    if (categories.isEmpty) {
      return _CategoryStatusScrollView(
        controller: controller.scrollController,
        child: AppEmptyWidget(
          onRefresh: controller.refreshData,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: selectedCategory == null
          ? _PrimaryCategoryList(
              controller: controller.scrollController,
              items: categories,
              onTap: _openCategory,
            )
          : _SecondaryCategoryList(
              controller: controller.scrollController,
              category: selectedCategory,
              onBack: _backToPrimary,
              onTap: (subCategory) {
                AppNavigator.toCategoryDetail(
                  site: controller.site,
                  category: subCategory,
                );
              },
            ),
    );
  }
}

class _CategoryStatusScrollView extends StatelessWidget {
  final ScrollController controller;
  final Widget child;

  const _CategoryStatusScrollView({
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => null),
      notificationPredicate: (_) => false,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PrimaryCategoryList extends StatelessWidget {
  final ScrollController controller;
  final List<AppLiveCategory> items;
  final ValueChanged<AppLiveCategory> onTap;

  const _PrimaryCategoryList({
    required this.controller,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return ListView.separated(
      padding: EdgeInsets.zero,
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: borderColor,
      ),
      itemBuilder: (_, index) => _PrimaryCategoryTile(
        item: items[index],
        onTap: () => onTap(items[index]),
      ),
    );
  }
}

class _PrimaryCategoryTile extends StatelessWidget {
  final AppLiveCategory item;
  final VoidCallback onTap;

  const _PrimaryCategoryTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedColor = AppStyle.mutedTextColor(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(Get.isDarkMode ? 18 : 10),
                  border: Border.all(
                    color: AppStyle.borderColor(context)
                        .withAlpha(Get.isDarkMode ? 80 : 120),
                  ),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item.children.length} 个小分区",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryCategoryList extends StatelessWidget {
  final ScrollController controller;
  final AppLiveCategory category;
  final VoidCallback onBack;
  final ValueChanged<LiveSubCategory> onTap;

  const _SecondaryCategoryList({
    required this.controller,
    required this.category,
    required this.onBack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    final items = category.children;

    return ListView.separated(
      padding: EdgeInsets.zero,
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: borderColor,
      ),
      itemBuilder: (_, index) {
        if (index == 0) {
          return _SecondaryCategoryHeader(
            category: category,
            onBack: onBack,
          );
        }

        final subCategory = items[index - 1];
        return _SecondaryCategoryTile(
          item: subCategory,
          onTap: () => onTap(subCategory),
        );
      },
    );
  }
}

class _SecondaryCategoryHeader extends StatelessWidget {
  final AppLiveCategory category;
  final VoidCallback onBack;

  const _SecondaryCategoryHeader({
    required this.category,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            splashRadius: 20,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "选择小分区后进入具体直播间",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppStyle.mutedTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${category.children.length} 个小分区",
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppStyle.mutedTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryCategoryTile extends StatelessWidget {
  final LiveSubCategory item;
  final VoidCallback onTap;

  const _SecondaryCategoryTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedColor = AppStyle.mutedTextColor(context);
    final iconBg = Get.isDarkMode
        ? scheme.primary.withAlpha(18)
        : scheme.primary.withAlpha(10);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: (item.pic ?? "").isNotEmpty
                    ? NetImage(
                        item.pic ?? "",
                        width: 32,
                        height: 32,
                        borderRadius: 4,
                      )
                    : Center(
                        child: Text(
                          item.name.characters.first,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
