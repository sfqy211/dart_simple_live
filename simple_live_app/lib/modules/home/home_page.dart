import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/home/home_list_view.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/widgets/app_shell.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  Widget _buildTabBar(BuildContext context, {required bool desktop}) {
    final scheme = Theme.of(context).colorScheme;
    final border = BorderSide(
      color:
          AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180),
    );
    return Container(
      decoration: desktop
          ? BoxDecoration(
              color: scheme.surface.withAlpha(Get.isDarkMode ? 70 : 160),
              borderRadius: BorderRadius.circular(16),
              border: Border.fromBorderSide(border),
            )
          : null,
      padding: desktop
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
          : EdgeInsets.zero,
      child: TabBar(
        controller: controller.tabController,
        labelPadding: desktop
            ? const EdgeInsets.symmetric(horizontal: 8)
            : AppStyle.edgeInsetsH20,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: desktop ? TabAlignment.start : TabAlignment.center,
        indicator: desktop
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: scheme.primary.withAlpha(Get.isDarkMode ? 28 : 20),
                border: Border.all(
                  color: scheme.primary.withAlpha(Get.isDarkMode ? 70 : 55),
                ),
              )
            : null,
        tabs: Sites.supportSites
            .map(
              (e) => Tab(
                child: Row(
                  children: [
                    Image.asset(
                      e.logo,
                      width: desktop ? 18 : 24,
                    ),
                    AppStyle.hGap8,
                    Text(e.name),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

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
                  AppStyle.vGap20,
                  _buildTabBar(context, desktop: true),
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
              child: TabBarView(
                controller: controller.tabController,
                children: Sites.supportSites
                    .map(
                      (e) => HomeListView(
                        e.id,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 8,
        title: _buildTabBar(context, desktop: false),
        actions: [
          IconButton(
            onPressed: controller.toSearch,
            icon: const Icon(Icons.search),
          )
        ],
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: Sites.supportSites
            .map(
              (e) => HomeListView(
                e.id,
              ),
            )
            .toList(),
      ),
    );
  }
}
