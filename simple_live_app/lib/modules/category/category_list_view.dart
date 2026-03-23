import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';

import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/category/category_list_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/shadow_card.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:sticky_headers/sticky_headers.dart';

class CategoryListView extends StatelessWidget {
  final String tag;

  const CategoryListView(this.tag, {Key? key}) : super(key: key);

  CategoryListController get controller =>
      Get.find<CategoryListController>(tag: tag);

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: Obx(
        () => EasyRefresh(
          firstRefresh: true,
          controller: controller.easyRefreshController,
          onRefresh: controller.refreshData,
          header: MaterialHeader(
            completeDuration: const Duration(milliseconds: 400),
          ),
          child: ListView.builder(
            padding: AppStyle.edgeInsetsA12,
            itemCount: controller.list.length,
            controller: controller.scrollController,
            itemBuilder: (_, i) {
              final item = controller.list[i];
              return StickyHeader(
                header: Container(
                  padding: AppStyle.edgeInsetsV8.copyWith(left: 4),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                content: Obx(
                  () {
                    final visibleItems =
                        item.showAll.value ? item.children : item.take15;
                    final itemCount =
                        visibleItems.length + (item.showAll.value ? 0 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      padding: AppStyle.edgeInsetsV8,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent:
                            AppStyle.isDesktopLayout(context) ? 92 : 104,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: 96,
                      ),
                      itemCount: itemCount,
                      itemBuilder: (_, index) {
                        if (!item.showAll.value &&
                            index == visibleItems.length) {
                          return buildShowMore(item);
                        }
                        return buildSubCategory(visibleItems[index]);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildSubCategory(LiveSubCategory item) {
    return ShadowCard(
      onTap: () {
        AppNavigator.toCategoryDetail(site: controller.site, category: item);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NetImage(
              item.pic ?? "",
              width: 40,
              height: 40,
              borderRadius: 8,
            ),
            AppStyle.vGap4,
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShowMore(AppLiveCategory item) {
    return ShadowCard(
      onTap: () {
        item.showAll.value = true;
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Center(
          child: Text(
            "显示全部",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.1),
          ),
        ),
      ),
    );
  }
}
