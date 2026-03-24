import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/home/home_list_view.dart';
import 'package:simple_live_app/modules/settings/appstyle_setting_page.dart';
import 'package:simple_live_app/widgets/desktop_page_header.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppStyle.isDesktopLayout(context);
    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            DesktopPageHeader(
              title: "首页推荐",
              actions: [
                DesktopPageHeaderButton(
                  onTap: controller.refreshOrScrollTop,
                  icon: Icons.refresh,
                  label: "刷新",
                ),
                DesktopPageHeaderButton(
                  onTap: controller.toSearch,
                  icon: Icons.search,
                  label: "搜索",
                ),
                const DesktopPageHeaderButton(
                  onTap: showAppstyleSettingsPanel,
                  icon: Icons.tune,
                  label: "外观",
                ),
              ],
            ),
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
