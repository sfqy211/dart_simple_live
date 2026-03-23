import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/widgets/app_shell.dart';

import 'indexed_controller.dart';

class IndexedPage extends GetView<IndexedController> {
  const IndexedPage({Key? key}) : super(key: key);

  Widget _buildDesktopRail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isExtended = MediaQuery.of(context).size.width >= 1180;
    return SizedBox(
      width: isExtended ? 240 : 84,
      child: AppPanel(
        emphasized: true,
        clipBehavior: Clip.antiAlias,
        child: Obx(
          () => NavigationRail(
            extended: isExtended,
            selectedIndex: controller.index.value,
            onDestinationSelected: controller.setIndex,
            useIndicator: true,
            groupAlignment: -0.9,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      "assets/logo.png",
                      width: 28,
                      height: 28,
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            destinations: controller.items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.iconData),
                    label: Text(item.title),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                )
                .toList(),
            trailing: isExtended
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: AppStyle.borderColor(context).withAlpha(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 120
                                  : 180),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Desktop",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
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
            const SizedBox(width: 16),
            Expanded(
              child: AppPanel(
                emphasized: true,
                clipBehavior: Clip.antiAlias,
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
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    destinations: controller.items
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.iconData),
                            label: Text(item.title),
                            padding: AppStyle.edgeInsetsV8,
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
