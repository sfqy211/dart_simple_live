import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';

class AudioModeCover extends GetView<LiveRoomController> {
  const AudioModeCover({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 音频图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Remix.music_fill,
                size: 48,
                color: Colors.blue,
              ),
            ),
            AppStyle.vGap24,
            // 直播间标题
            Padding(
              padding: AppStyle.edgeInsetsH24,
              child: Text(
                controller.detail.value?.title ?? "直播间",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppStyle.vGap12,
            // 主播信息
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.detail.value?.userName ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                AppStyle.hGap8,
                Image.asset(
                  controller.site.logo,
                  width: 16,
                  height: 16,
                ),
              ],
            ),
            AppStyle.vGap12,
            // 在线人数
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Remix.fire_fill,
                  size: 16,
                  color: Colors.orange,
                ),
                AppStyle.hGap4,
                Text(
                  Utils.onlineToString(controller.detail.value?.online ?? 0),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            AppStyle.vGap32,
            // 提示文字
            Text(
              "已开启纯净黑听模式",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}