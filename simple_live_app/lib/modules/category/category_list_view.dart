import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
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

class CategoryListView extends StatelessWidget {
  final String tag;

  const CategoryListView(this.tag, {Key? key}) : super(key: key);

  CategoryListController get controller =>
      Get.find<CategoryListController>(tag: tag);

  @override
  Widget build(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return KeepAliveWrapper(
      child: Obx(
        () => Stack(
          children: [
            EasyRefresh(
              firstRefresh: true,
              controller: controller.easyRefreshController,
              onRefresh: controller.refreshData,
              header: MaterialHeader(
                completeDuration: const Duration(milliseconds: 400),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                controller: controller.scrollController,
                itemCount: controller.list.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                ),
                itemBuilder: (_, i) => _CategorySection(
                  item: controller.list[i],
                  onTap: (subCategory) {
                    AppNavigator.toCategoryDetail(
                      site: controller.site,
                      category: subCategory,
                    );
                  },
                ),
              ),
            ),
            Offstage(
              offstage: !controller.pageEmpty.value,
              child: AppEmptyWidget(
                onRefresh: () => controller.refreshData(),
              ),
            ),
            Offstage(
              offstage: !controller.pageError.value,
              child: AppErrorWidget(
                errorMsg: controller.errorMsg.value,
                onRefresh: () => controller.refreshData(),
              ),
            ),
            Offstage(
              offstage: !controller.pageLoadding.value,
              child: const AppLoaddingWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AppLiveCategory item;
  final ValueChanged<LiveSubCategory> onTap;

  const _CategorySection({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = AppStyle.isDesktopLayout(context);

    return Container(
      color: theme.cardColor,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 20 : 12,
        14,
        isDesktop ? 20 : 12,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${item.children.length} 个子分区",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppStyle.mutedTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final visibleItems =
                  item.showAll.value ? item.children : item.take15;
              final hiddenCount = item.children.length - visibleItems.length;
              final hasMore = hiddenCount > 0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = math.max(
                    2,
                    math.min(
                      isDesktop ? 5 : 4,
                      (constraints.maxWidth / (isDesktop ? 220 : 168)).floor(),
                    ),
                  );
                  final totalCount = visibleItems.length + (hasMore ? 1 : 0);
                  final borderColor = AppStyle.borderColor(context)
                      .withAlpha(Get.isDarkMode ? 120 : 180);

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(1),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                        mainAxisExtent: isDesktop ? 58 : 60,
                      ),
                      itemBuilder: (_, index) {
                        if (hasMore && index == visibleItems.length) {
                          return _ShowMoreTile(
                            hiddenCount: hiddenCount,
                            onTap: () {
                              item.showAll.value = true;
                            },
                          );
                        }

                        return _CategoryTile(
                          item: visibleItems[index],
                          onTap: () => onTap(visibleItems[index]),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final LiveSubCategory item;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconBg = Get.isDarkMode
        ? scheme.primary.withAlpha(18)
        : scheme.primary.withAlpha(10);

    return Material(
      color: theme.cardColor,
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: (item.pic ?? "").isNotEmpty
                    ? NetImage(
                        item.pic ?? "",
                        width: 28,
                        height: 28,
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
              const SizedBox(width: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowMoreTile extends StatelessWidget {
  final int hiddenCount;
  final VoidCallback onTap;

  const _ShowMoreTile({
    required this.hiddenCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: theme.cardColor,
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppStyle.borderColor(context)
                        .withAlpha(Get.isDarkMode ? 120 : 180),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: AppStyle.mutedTextColor(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "显示全部",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "+$hiddenCount",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppStyle.mutedTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
