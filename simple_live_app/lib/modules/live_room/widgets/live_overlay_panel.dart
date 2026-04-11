import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';

void showLiveOverlayPanel({
  required String title,
  required Widget child,
  double width = 400,
  bool forceBottomSheet = false,
}) {
  final context = Get.context;
  if (!forceBottomSheet &&
      context != null &&
      AppStyle.isDesktopLayout(context)) {
    Utils.showRightDialog(
      title: title,
      width: width,
      useSystem: true,
      child: child,
    );
    return;
  }

  Utils.showBottomSheet(
    title: title,
    child: child,
  );
}
