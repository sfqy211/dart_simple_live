import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/widgets/app_shell.dart';

import 'indexed_controller.dart';

class IndexedPage extends GetView<IndexedController> {
  const IndexedPage({Key? key}) : super(key: key);

  Widget _buildRailIcon(IconData iconData) {
    return SizedBox.square(
      dimension: 22,
      child: Icon(iconData, size: 20),
    );
  }

  Widget _buildDesktopNavItem(
    BuildContext context, {
    required int index,
    required bool selected,
    required bool extended,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = controller.items[index];
    final fillColor = selected
        ? scheme.primary.withAlpha(Get.isDarkMode ? 24 : 14)
        : Colors.transparent;
    final borderColor = selected
        ? scheme.primary.withAlpha(Get.isDarkMode ? 72 : 48)
        : Colors.transparent;
    final foregroundColor =
        selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.setIndex(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 0),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment:
                extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                item.iconData,
                size: 20,
                color: foregroundColor,
              ),
              if (extended) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRail(BuildContext context) {
    final theme = Theme.of(context);
    final isExtended = MediaQuery.of(context).size.width >= 1180;
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Container(
      width: isExtended ? 224 : 84,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Obx(
          () {
            final selectedIndex = controller.index.value;
            final items = controller.items.toList(growable: false);
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => Padding(
                padding: EdgeInsets.symmetric(horizontal: isExtended ? 6 : 10),
                child: Divider(
                  height: 10,
                  thickness: 1,
                  color: borderColor.withAlpha(Get.isDarkMode ? 96 : 150),
                ),
              ),
              itemBuilder: (context, index) => _buildDesktopNavItem(
                context,
                index: index,
                selected: selectedIndex == index,
                extended: isExtended,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppStyle.isDesktopLayout(context)) {
      return AppShellFrame(
        child: Row(
          children: [
            _buildDesktopRail(context),
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Obx(
                  () => IndexedStack(
                    index: controller.index.value,
                    children: controller.pages,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
        return Scaffold(
          backgroundColor: scaffoldColor,
          body: Row(
            children: [
              Visibility(
                visible: orientation == Orientation.landscape,
                child: Obx(
                  () => NavigationRail(
                    selectedIndex: controller.index.value,
                    onDestinationSelected: controller.setIndex,
                    labelType: NavigationRailLabelType.none,
                    useIndicator: true,
                    minWidth: 92,
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    destinations: controller.items
                        .map(
                          (item) => NavigationRailDestination(
                            icon: _buildRailIcon(item.iconData),
                            label: Text(item.title),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: scaffoldColor,
                      border: Border(
                        left: orientation == Orientation.landscape
                            ? BorderSide(
                                color: AppStyle.borderColor(context)
                                    .withAlpha(Get.isDarkMode ? 120 : 180),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: IndexedStack(
                      index: controller.index.value,
                      children: controller.pages,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Visibility(
            visible: orientation == Orientation.portrait,
            child: Obx(
              () => NavigationBar(
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                height: 56,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                backgroundColor: Theme.of(context).colorScheme.surface,
                destinations: controller.items
                    .map(
                      (item) => NavigationDestination(
                        icon: Icon(item.iconData),
                        label: item.title,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
