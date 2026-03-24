import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/category/category_controller.dart';
import 'package:simple_live_app/modules/category/category_list_view.dart';
import 'package:simple_live_app/widgets/desktop_page_header.dart';

class CategoryPage extends GetView<CategoryController> {
  const CategoryPage({Key? key}) : super(key: key);

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
              child: CategoryListView(controller.site.id),
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
