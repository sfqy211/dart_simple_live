import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/home/home_list_view.dart';
import 'package:simple_live_app/routes/route_path.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

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
                  "首页推荐",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: controller.refreshOrScrollTop,
                icon: const Icon(Icons.refresh),
                label: const Text("刷新"),
              ),
              OutlinedButton.icon(
                onPressed: controller.toSearch,
                icon: const Icon(Icons.search),
                label: const Text("搜索"),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(RoutePath.kAppstyleSetting),
                icon: const Icon(Icons.tune),
                label: const Text("外观"),
              ),
            ],
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
              child: HomeListView(controller.site.id),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 8,
        title: const Text("首页"),
        actions: [
          IconButton(
            onPressed: controller.toSearch,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: HomeListView(controller.site.id),
    );
  }
}
