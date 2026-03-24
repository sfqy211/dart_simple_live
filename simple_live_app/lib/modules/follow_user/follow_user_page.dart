import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/modules/follow_user/follow_user_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/desktop_page_header.dart';
import 'package:simple_live_app/widgets/filter_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';

class FollowUserPage extends GetView<FollowUserController> {
  const FollowUserPage({Key? key}) : super(key: key);

  List<PopupMenuEntry<int>> _buildPageActionItems() {
    return const [
      PopupMenuItem(
        value: 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.save_2_line),
            AppStyle.hGap12,
            Text("导出文件"),
          ],
        ),
      ),
      PopupMenuItem(
        value: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.folder_open_line),
            AppStyle.hGap12,
            Text("导入文件"),
          ],
        ),
      ),
      PopupMenuItem(
        value: 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.text),
            AppStyle.hGap12,
            Text("导出文本"),
          ],
        ),
      ),
      PopupMenuItem(
        value: 3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.file_text_line),
            AppStyle.hGap12,
            Text("导入文本"),
          ],
        ),
      ),
      PopupMenuItem(
        value: 4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.price_tag_line),
            AppStyle.hGap12,
            Text("标签管理"),
          ],
        ),
      ),
    ];
  }

  void _handlePageAction(int value) {
    if (value == 0) {
      FollowService.instance.exportFile();
    } else if (value == 1) {
      FollowService.instance.inputFile();
    } else if (value == 2) {
      FollowService.instance.exportText();
    } else if (value == 3) {
      FollowService.instance.inputText();
    } else if (value == 4) {
      showTagsManager();
    }
  }

  Widget _buildRefreshButton() {
    return Obx(
      () => FollowService.instance.updating.value
          ? const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : IconButton(
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh),
              tooltip: "刷新",
            ),
    );
  }

  Widget _buildDesktopRefreshAction() {
    return Obx(
      () => FollowService.instance.updating.value
          ? const DesktopPageHeaderBadge(text: "同步中")
          : DesktopPageHeaderButton(
              onTap: controller.refreshData,
              icon: Icons.refresh,
              label: "刷新",
            ),
    );
  }

  Widget _buildDesktopMoreAction() {
    return PopupMenuButton<int>(
      tooltip: "更多",
      itemBuilder: (_) => _buildPageActionItems(),
      onSelected: _handlePageAction,
      child: const DesktopPageHeaderIconButton(
        icon: Icons.more_horiz,
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, {required bool desktop}) {
    final theme = Theme.of(context);
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return Container(
      padding: EdgeInsets.fromLTRB(desktop ? 16 : 8, 10, desktop ? 16 : 8, 10),
      decoration: desktop
          ? BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            )
          : null,
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.tagList.map((option) {
              return FilterButton(
                text: option.tag,
                selected: controller.filterMode.value == option,
                onTap: () {
                  controller.setFilterMode(option);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowList(BuildContext context, {required int count}) {
    return PageGridView(
      padding: AppStyle.isDesktopLayout(context)
          ? const EdgeInsets.fromLTRB(12, 12, 12, 12)
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: count,
      pageController: controller,
      firstRefresh: true,
      showPCRefreshButton: false,
      itemBuilder: (_, i) {
        final item = controller.list[i];
        final site = Sites.allSites[item.siteId]!;
        return FollowUserItem(
          item: item,
          onRemove: () {
            controller.removeItem(item);
          },
          onTap: () {
            AppNavigator.toLiveRoomDetail(site: site, roomId: item.roomId);
          },
          onLongPress: () {
            setFollowTagDialog(item);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppStyle.isDesktopLayout(context);
    var count = MediaQuery.of(context).size.width ~/ (isDesktop ? 440 : 500);
    if (count < 1) {
      count = 1;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("关注用户"),
              actions: [
                PopupMenuButton<int>(
                  itemBuilder: (_) => _buildPageActionItems(),
                  onSelected: _handlePageAction,
                ),
              ],
              leading: _buildRefreshButton(),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            DesktopPageHeader(
              title: "关注用户",
              actions: [
                _buildDesktopRefreshAction(),
                _buildDesktopMoreAction(),
              ],
            ),
          _buildFilterBar(context, desktop: isDesktop),
          Expanded(
            child: _buildFollowList(context, count: count),
          ),
        ],
      ),
    );
  }

  void setFollowTagDialog(FollowUser item) {
    final copiedList = [
      controller.tagList.first,
      ...controller.tagList.skip(3),
    ];
    final Rx<FollowUserTag> checkTag =
        controller.tagList.indexOf(controller.filterMode.value) < 3
            ? copiedList.first.obs
            : controller.filterMode.value.obs;
    final scrollController = ScrollController();
    Get.dialog(
      AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "设置标签",
                  style: TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    controller.setItemTag(item, checkTag.value);
                    Get.back();
                  },
                ),
              ],
            ),
            const Divider(),
            Obx(
              () {
                final selectedIndex = copiedList.indexOf(checkTag.value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (selectedIndex >= 0) {
                    scrollController.animateTo(
                      selectedIndex * 60.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
                return SizedBox(
                  height: 300,
                  width: 300,
                  child: RadioGroup(
                    groupValue: checkTag.value,
                    onChanged: (value) {
                      checkTag.value = value!;
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: copiedList.length,
                      itemBuilder: (context, index) {
                        final tagItem = copiedList[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: RadioListTile<FollowUserTag>(
                            title: Text(tagItem.tag),
                            value: tagItem,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void showTagsManager() {
    Utils.showBottomSheet(
      title: "标签管理",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppStyle.divider,
          ListTile(
            title: const Text("添加标签"),
            leading: const Icon(Icons.add),
            onTap: () {
              editTagDialog("添加标签");
            },
          ),
          AppStyle.divider,
          Expanded(
            child: Obx(
              () => ReorderableListView.builder(
                itemCount: controller.userTagList.length,
                itemBuilder: (context, index) {
                  final item = controller.userTagList[index];
                  return ListTile(
                    key: ValueKey(item.id),
                    title: GestureDetector(
                      onLongPress: () {
                        editTagDialog("修改标签", followUserTag: item);
                      },
                      child: Text(item.tag),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        controller.removeTag(item);
                      },
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  controller.updateTagOrder(oldIndex, newIndex);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void editTagDialog(String title, {FollowUserTag? followUserTag}) {
    final tagEditController = TextEditingController(text: followUserTag?.tag);
    final upMode = title == "添加标签";
    Get.dialog(
      AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        content: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
              TextField(
                controller: tagEditController,
                minLines: 1,
                maxLines: 1,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: AppStyle.edgeInsetsA12,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withAlpha(51),
                    ),
                  ),
                ),
                onSubmitted: (tag) {
                  if (upMode) {
                    controller.addTag(tagEditController.text);
                  } else {
                    controller.updateTagName(
                      followUserTag!,
                      tagEditController.text,
                    );
                  }
                  Get.back();
                },
              ),
              Container(
                margin: AppStyle.edgeInsetsB4,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: const Text("否"),
                    ),
                    TextButton(
                      onPressed: () {
                        if (upMode) {
                          controller.addTag(tagEditController.text);
                        } else {
                          controller.updateTagName(
                            followUserTag!,
                            tagEditController.text,
                          );
                        }
                        Get.back();
                      },
                      child: const Text("是"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
