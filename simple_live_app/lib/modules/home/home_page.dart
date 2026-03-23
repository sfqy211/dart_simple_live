import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/home/home_list_view.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/widgets/app_shell.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  Widget _buildDesktopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
      child: AppPanel(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "直播推荐",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  AppStyle.vGap8,
                  Text(
                    "为长期观看准备的桌面首页，保留安静的层次，把注意力还给内容本身。",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppStyle.mutedTextColor(context),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  onPressed: controller.refreshOrScrollTop,
                  icon: const Icon(Icons.refresh),
                  label: const Text("刷新"),
                ),
                FilledButton.tonalIcon(
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
          )
        ],
      ),
      body: HomeListView(controller.site.id),
    );
  }
}
