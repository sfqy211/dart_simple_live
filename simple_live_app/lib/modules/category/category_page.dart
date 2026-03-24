import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/category/category_controller.dart';
import 'package:simple_live_app/modules/category/category_list_view.dart';

class CategoryPage extends GetView<CategoryController> {
  const CategoryPage({Key? key}) : super(key: key);

  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "分类",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: controller.refreshOrScrollTop,
            icon: const Icon(Icons.refresh),
            label: const Text("刷新"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppStyle.isDesktopLayout(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildDesktopHeader(context),
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
