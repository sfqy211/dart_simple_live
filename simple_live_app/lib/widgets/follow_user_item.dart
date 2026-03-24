import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/widgets/net_image.dart';

class FollowUserItem extends StatelessWidget {
  final FollowUser item;
  final Function()? onRemove;
  final Function()? onTap;
  final Function()? onLongPress;
  final bool playing;

  const FollowUserItem({
    required this.item,
    this.onRemove,
    this.onTap,
    this.onLongPress,
    this.playing = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final liveStatus = item.liveStatus.value;
      final isLive = liveStatus == 2;
      final borderColor = playing
          ? scheme.primary.withAlpha(isDark ? 82 : 58)
          : theme.dividerColor.withAlpha(isDark ? 120 : 180);
      final fillColor = playing
          ? scheme.primary.withAlpha(isDark ? 18 : 10)
          : theme.cardColor;
      final statusColor = isLive
          ? const Color(0xFF4CAF50)
          : (liveStatus == 0
              ? scheme.onSurfaceVariant.withAlpha(160)
              : scheme.onSurfaceVariant);

      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  NetImage(
                    item.face,
                    width: 46,
                    height: 46,
                    borderRadius: 23,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _statusText(liveStatus),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          playing
                              ? "正在观看"
                              : _metaText(liveStatus, item.liveStartTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: playing
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight:
                                playing ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (playing)
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: scheme.primary.withAlpha(isDark ? 28 : 16),
                        border: Border.all(
                          color: scheme.primary.withAlpha(isDark ? 70 : 50),
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 20,
                        color: scheme.primary,
                      ),
                    )
                  else if (onRemove != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: IconButton(
                        onPressed: () {
                          onRemove?.call();
                        },
                        tooltip: "取消关注",
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Remix.dislike_line,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _statusText(int status) {
    if (status == 0) {
      return "读取中";
    }
    if (status == 1) {
      return "未开播";
    }
    return "直播中";
  }

  String _metaText(int status, String? liveStartTime) {
    if (status == 0) {
      return "正在同步状态";
    }
    if (status == 2 && liveStartTime != null) {
      return "开播${formatLiveDuration(liveStartTime)}";
    }
    return "等待开播";
  }

  String formatLiveDuration(String? startTimeStampString) {
    if (startTimeStampString == null ||
        startTimeStampString.isEmpty ||
        startTimeStampString == "0") {
      return "";
    }
    try {
      final startTimeStamp = int.parse(startTimeStampString);
      final currentTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final durationInSeconds = currentTimeStamp - startTimeStamp;

      final hours = durationInSeconds ~/ 3600;
      final minutes = (durationInSeconds % 3600) ~/ 60;

      final hourText = hours > 0 ? "$hours小时" : "";
      final minuteText = minutes > 0 ? "$minutes分钟" : "";

      if (hours == 0 && minutes == 0) {
        return "不足1分钟";
      }

      return "$hourText$minuteText";
    } catch (e) {
      Log.logPrint("格式化开播时长出错: $e");
      return "--小时--分钟";
    }
  }
}
