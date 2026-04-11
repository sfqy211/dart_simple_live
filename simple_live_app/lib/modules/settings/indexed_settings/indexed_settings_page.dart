import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/settings/indexed_settings/indexed_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

class IndexedSettingsPage extends GetView<IndexedSettingsController> {
  const IndexedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "导航设置",
      subtitle: "侧边栏与底部栏顺序",
      body: IndexedSettingsView(),
    );
  }
}

class IndexedSettingsView extends GetView<IndexedSettingsController> {
  const IndexedSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final showSiteSort = Sites.supportSites.length > 1;

    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        const SettingsSectionTitle(
          title: "导航排序",
          subtitle: "长按拖动以调整关注、分类和我的显示顺序。",
        ),
        SettingsCard(
          child: Obx(
            () => ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: controller.updateHomeSort,
              children: controller.homeSort.map(
                (key) {
                  final item = Constant.allHomePages[key]!;
                  return ListTile(
                    key: ValueKey(item.title),
                    title: Text(item.title),
                    visualDensity: VisualDensity.compact,
                    leading: Icon(item.iconData),
                    trailing: const Icon(Icons.drag_indicator_rounded),
                  );
                },
              ).toList(),
            ),
          ),
        ),
        if (showSiteSort) ...[
          AppStyle.vGap24,
          const SettingsSectionTitle(
            title: "平台排序",
          ),
          SettingsCard(
            child: Obx(
              () => ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: controller.updateSiteSort,
                children: controller.siteSort.map(
                  (key) {
                    final item = Sites.allSites[key]!;
                    return ListTile(
                      key: ValueKey(item.id),
                      visualDensity: VisualDensity.compact,
                      title: Text(item.name),
                      leading: Image.asset(
                        item.logo,
                        width: 24,
                        height: 24,
                      ),
                      trailing: const Icon(Icons.drag_indicator_rounded),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
