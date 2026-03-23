import 'dart:io';

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

  Widget _buildDesktopRail(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isExtended = MediaQuery.of(context).size.width >= 1180;
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Container(
      width: isExtended ? 252 : 92,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isExtended ? 16 : 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: isExtended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    "assets/logo.png",
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isExtended) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Simple Live",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => NavigationRail(
                extended: isExtended,
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                useIndicator: true,
                minWidth: 92,
                minExtendedWidth: 252,
                groupAlignment: -1,
                leading: const SizedBox(height: 8),
                backgroundColor: Colors.transparent,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                destinations: controller.items
                    .map(
                      (item) => NavigationRailDestination(
                        icon: _buildRailIcon(item.iconData),
                        label: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    )
                    .toList(),
                trailing: isExtended
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Desktop",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
        return Scaffold(
          backgroundColor: Colors.transparent,
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
