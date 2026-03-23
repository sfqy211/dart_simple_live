import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/home/home_list_controller.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';

class HomeListView extends StatelessWidget {
  final String tag;
  const HomeListView(this.tag, {Key? key}) : super(key: key);
  HomeListController get controller => Get.find<HomeListController>(tag: tag);
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AppStyle.isDesktopLayout(context);
        final columnWidth = isDesktop ? 250.0 : 200.0;
        var c = (constraints.maxWidth / columnWidth).floor();
        if (c < 2) {
          c = 2;
        }
        return KeepAliveWrapper(
          child: PageGridView(
            pageController: controller,
            padding: isDesktop
                ? const EdgeInsets.fromLTRB(16, 16, 16, 16)
                : AppStyle.edgeInsetsA12,
            firstRefresh: true,
            showPCRefreshButton: !isDesktop,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            crossAxisCount: c,
            itemBuilder: (_, i) {
              var item = controller.list[i];
              return LiveRoomCard(controller.siteInfo, item);
            },
          ),
        );
      },
    );
  }
}
