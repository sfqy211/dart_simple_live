import 'dart:async';

import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/category/category_list_controller.dart';

class CategoryController extends GetxController {
  StreamSubscription<dynamic>? streamSubscription;
  Site get site => Sites.supportSites.first;

  @override
  void onInit() {
    streamSubscription = EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 2) {
          refreshOrScrollTop();
        }
      },
    );
    Get.put(CategoryListController(site), tag: site.id);

    super.onInit();
  }

  void refreshOrScrollTop() {
    BasePageController controller;
    controller = Get.find<CategoryListController>(tag: site.id);
    if (!controller.scrollController.hasClients) {
      controller.refreshData();
      return;
    }
    controller.scrollToTopOrRefresh();
  }

  @override
  void onClose() {
    streamSubscription?.cancel();
    super.onClose();
  }
}
