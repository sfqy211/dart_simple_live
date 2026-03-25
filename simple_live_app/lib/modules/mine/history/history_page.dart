import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/mine/history/history_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

class HistoryPage extends GetView<HistoryController> {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: "观看记录",
      subtitle: "最近访问过的直播间",
      actions: [
        TextButton.icon(
          onPressed: controller.clean,
          icon: const Icon(Icons.delete_outline),
          label: const Text("清空"),
        ),
      ],
      body: const HistoryView(),
    );
  }
}

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowCount = math.max(1, (constraints.maxWidth / 480).floor());

        return PageGridView(
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          crossAxisCount: rowCount,
          pageController: controller,
          padding: AppStyle.contentPadding(context),
          firstRefresh: true,
          itemBuilder: (_, index) {
            final item = controller.list[index];
            final site = Sites.allSites[item.siteId]!;

            return Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                padding: AppStyle.edgeInsetsA12,
                alignment: Alignment.centerRight,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (_) async {
                return Utils.showAlertDialog(
                  "确定要删除此记录吗?",
                  title: "删除记录",
                );
              },
              onDismissed: (_) {
                controller.removeItem(item);
              },
              child: _HistoryCard(
                userName: item.userName,
                roomId: item.roomId,
                face: item.face,
                siteName: site.name,
                siteLogo: site.logo,
                updateTime: Utils.parseTime(item.updateTime),
                onTap: () {
                  AppNavigator.toLiveRoomDetail(
                      site: site, roomId: item.roomId);
                },
                onDelete: () async {
                  final result = await Utils.showAlertDialog(
                    "确定要删除此记录吗?",
                    title: "删除记录",
                  );
                  if (!result) return;
                  controller.removeItem(item);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String userName;
  final String roomId;
  final String face;
  final String siteName;
  final String siteLogo;
  final String updateTime;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.userName,
    required this.roomId,
    required this.face,
    required this.siteName,
    required this.siteLogo,
    required this.updateTime,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return Material(
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NetImage(
                    face,
                    width: 44,
                    height: 44,
                    borderRadius: 2,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "房间号 $roomId",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppStyle.mutedTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Image.asset(
                    siteLogo,
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      siteName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppStyle.mutedTextColor(context),
                      ),
                    ),
                  ),
                  Text(
                    updateTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppStyle.mutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
