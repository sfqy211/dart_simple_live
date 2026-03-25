import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/category/category_controller.dart';
import 'package:simple_live_app/modules/category/category_list_controller.dart';
import 'package:simple_live_app/modules/category/category_list_view.dart';
import 'package:simple_live_app/widgets/desktop_page_header.dart';
import 'package:simple_live_app/widgets/desktop_workbench.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';
import 'package:simple_live_core/simple_live_core.dart';

class CategoryPage extends GetView<CategoryController> {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppStyle.isDesktopLayout(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            DesktopPageHeader(
              title: "分类",
              actions: [
                DesktopPageHeaderButton(
                  onTap: controller.refreshOrScrollTop,
                  icon: Icons.refresh,
                  label: "刷新",
                ),
              ],
            ),
            Expanded(
              child: _DesktopCategoryWorkbench(site: controller.site),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("分类"),
        actions: [
          IconButton(
            onPressed: controller.refreshOrScrollTop,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: CategoryListView(controller.site.id),
    );
  }
}

class _DesktopCategoryWorkbench extends StatefulWidget {
  final Site site;

  const _DesktopCategoryWorkbench({
    required this.site,
  });

  @override
  State<_DesktopCategoryWorkbench> createState() =>
      _DesktopCategoryWorkbenchState();
}

class _DesktopCategoryWorkbenchState extends State<_DesktopCategoryWorkbench> {
  late final CategoryListController categoryController;
  late final _CategoryRoomsController roomController;

  AppLiveCategory? selectedCategory;
  LiveSubCategory? selectedSubCategory;
  bool secondaryExpanded = true;

  @override
  void initState() {
    super.initState();
    categoryController = Get.find<CategoryListController>(tag: widget.site.id);
    roomController = _CategoryRoomsController(widget.site);
    if (categoryController.list.isEmpty &&
        !categoryController.pageLoadding.value) {
      categoryController.refreshData();
    }
  }

  void _syncSelection(List<AppLiveCategory> categories) {
    if (categories.isEmpty) {
      return;
    }

    final matchedCategory = selectedCategory == null
        ? null
        : categories
            .where((item) => item.id == selectedCategory!.id)
            .firstOrNull;

    if (matchedCategory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectCategory(categories.first);
      });
      return;
    }

    if (selectedSubCategory != null) {
      final matchedSubCategory = matchedCategory.children
          .where((item) => item.id == selectedSubCategory!.id)
          .firstOrNull;

      if (matchedSubCategory == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            selectedCategory = matchedCategory;
            selectedSubCategory = null;
            secondaryExpanded = true;
          });
          roomController.setSubCategory(null);
        });
      }
    }
  }

  void _selectCategory(AppLiveCategory category) {
    setState(() {
      selectedCategory = category;
      selectedSubCategory = null;
      secondaryExpanded = true;
    });
    roomController.setSubCategory(null);
  }

  void _selectSubCategory(LiveSubCategory subCategory) {
    setState(() {
      selectedSubCategory = subCategory;
      secondaryExpanded = false;
    });
    roomController.setSubCategory(subCategory);
  }

  void _toggleSecondaryExpanded() {
    setState(() {
      secondaryExpanded = !secondaryExpanded;
    });
  }

  void _refreshCurrentPane() {
    categoryController.refreshData();

    if (selectedSubCategory == null) {
      return;
    }

    if (roomController.scrollController.hasClients &&
        roomController.scrollController.offset > 0) {
      roomController.scrollToTopOrRefresh();
      return;
    }

    roomController.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = categoryController.list.toList();
      _syncSelection(categories);

      return DesktopWorkbenchLayout(
        sidebar: DesktopWorkbenchSidebar(
          sections: [
            DesktopWorkbenchSectionData(
              title: "直播分区",
              description: "左侧选择一级分区，右侧切换二级子分区与直播间。",
              items: categories
                  .map(
                    (item) => DesktopWorkbenchItemData(
                      icon: Icons.grid_view_rounded,
                      title: item.name,
                      hint: "${item.children.length}项",
                      selected: selectedCategory?.id == item.id,
                      onTap: () => _selectCategory(item),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        content: _buildContent(context, categories),
      );
    });
  }

  Widget _buildContent(BuildContext context, List<AppLiveCategory> categories) {
    if (categoryController.pageError.value && categories.isEmpty) {
      return _CategoryStatusView(
        message: categoryController.errorMsg.value,
        buttonLabel: "重试",
        onTap: categoryController.refreshData,
      );
    }

    if (categoryController.pageLoadding.value && categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (categories.isEmpty || selectedCategory == null) {
      return _CategoryStatusView(
        message: "暂无可用分区",
        buttonLabel: "刷新",
        onTap: categoryController.refreshData,
      );
    }

    return SettingsWorkspace(
      title: selectedCategory!.name,
      subtitle: selectedSubCategory == null
          ? "请选择一个二级分区"
          : "已选择 ${selectedSubCategory!.name}",
      actions: [
        DesktopPageHeaderButton(
          onTap: _toggleSecondaryExpanded,
          icon: secondaryExpanded ? Icons.unfold_less : Icons.unfold_more,
          label: secondaryExpanded ? "收起二级菜单" : "展开二级菜单",
        ),
        DesktopPageHeaderButton(
          onTap: _refreshCurrentPane,
          icon: Icons.refresh,
          label: "刷新",
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (secondaryExpanded) ...[
                  SettingsSectionTitle(
                    title: "二级分区",
                    subtitle:
                        "点击切换 ${selectedCategory!.name} 下的具体分类，未选中前不会请求直播间。",
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  _DesktopSubCategoryGrid(
                    items: selectedCategory!.children,
                    selectedSubCategoryId: selectedSubCategory?.id,
                    onTap: _selectSubCategory,
                  ),
                ] else ...[
                  const SettingsSectionTitle(
                    title: "当前二级分区",
                    subtitle: "已自动收起二级菜单，方便继续选择直播间。",
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  SettingsCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(selectedSubCategory?.name ?? "未选择"),
                      subtitle: Text(selectedCategory!.name),
                      trailing: TextButton(
                        onPressed: _toggleSecondaryExpanded,
                        child: const Text("重新选择"),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppStyle.borderColor(context)
                .withAlpha(Get.isDarkMode ? 120 : 180),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedSubCategory == null
                              ? "直播间"
                              : "${selectedSubCategory!.name} 直播间",
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      Text(
                        selectedSubCategory == null ? "等待选择二级分区" : "桌面端工作台视图",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppStyle.mutedTextColor(context),
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedSubCategory == null
                      ? const _CategoryStatusView(
                          message: "请选择一个二级分区后再查看直播间",
                          buttonLabel: "",
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = math.max(
                              2,
                              math.min(5, (constraints.maxWidth / 240).floor()),
                            );

                            return PageGridView(
                              pageController: roomController,
                              firstRefresh: false,
                              showPageLoadding: true,
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              crossAxisCount: crossAxisCount,
                              itemBuilder: (_, index) {
                                return LiveRoomCard(
                                  widget.site,
                                  roomController.list[index],
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSubCategoryGrid extends StatelessWidget {
  final List<LiveSubCategory> items;
  final String? selectedSubCategoryId;
  final ValueChanged<LiveSubCategory> onTap;

  const _DesktopSubCategoryGrid({
    required this.items,
    required this.selectedSubCategoryId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SettingsCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("当前一级分区下暂无二级分区。"),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = math.max(
          2,
          math.min(5, (constraints.maxWidth / 220).floor()),
        );
        final rowCount = (items.length / crossAxisCount).ceil();
        final maxVisibleRows = math.min(rowCount, 4);
        final gridHeight =
            (maxVisibleRows * 60) + ((maxVisibleRows - 1) * 1) + 2;

        return Container(
          constraints: BoxConstraints(
            maxHeight: gridHeight.toDouble(),
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppStyle.borderColor(context)
                  .withAlpha(Get.isDarkMode ? 120 : 180),
            ),
          ),
          child: GridView.builder(
            primary: false,
            padding: const EdgeInsets.all(1),
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              mainAxisExtent: 60,
            ),
            itemBuilder: (_, index) {
              final item = items[index];
              final selected = item.id == selectedSubCategoryId;
              return _DesktopSubCategoryTile(
                item: item,
                selected: selected,
                onTap: () => onTap(item),
              );
            },
          ),
        );
      },
    );
  }
}

class _DesktopSubCategoryTile extends StatelessWidget {
  final LiveSubCategory item;
  final bool selected;
  final VoidCallback onTap;

  const _DesktopSubCategoryTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bgColor = selected
        ? scheme.primary.withAlpha(Get.isDarkMode ? 22 : 12)
        : theme.cardColor;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        hoverColor: scheme.primary.withAlpha(Get.isDarkMode ? 18 : 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withAlpha(Get.isDarkMode ? 26 : 16)
                      : scheme.primary.withAlpha(Get.isDarkMode ? 16 : 8),
                ),
                child: (item.pic ?? "").isNotEmpty
                    ? NetImage(
                        item.pic ?? "",
                        width: 28,
                        height: 28,
                        borderRadius: 0,
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStatusView extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback? onTap;

  const _CategoryStatusView({
    required this.message,
    required this.buttonLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppStyle.mutedTextColor(context),
                ),
          ),
          if (buttonLabel.isNotEmpty && onTap != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onTap,
              child: Text(buttonLabel),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRoomsController extends BasePageController<LiveRoomItem> {
  final Site site;
  LiveSubCategory? subCategory;

  _CategoryRoomsController(this.site);

  void setSubCategory(LiveSubCategory? next) {
    subCategory = next;
    list.value = [];
    currentPage = 1;
    canLoadMore.value = false;
    pageError.value = false;
    pageEmpty.value = false;
    if (next == null) {
      return;
    }
    refreshData();
  }

  @override
  Future<List<LiveRoomItem>> getData(int page, int pageSize) async {
    if (subCategory == null) {
      return [];
    }
    final result =
        await site.liveSite.getCategoryRooms(subCategory!, page: page);
    return result.items;
  }
}
