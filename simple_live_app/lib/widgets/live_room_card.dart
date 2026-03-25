import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/shadow_card.dart';
import 'package:simple_live_core/simple_live_core.dart';

class LiveRoomCard extends StatelessWidget {
  final Site site;
  final LiveRoomItem item;
  final int titleMaxLines;
  final bool reserveTitleHeight;
  const LiveRoomCard(
    this.site,
    this.item, {
    this.titleMaxLines = 2,
    this.reserveTitleHeight = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = theme.dividerColor.withAlpha(165);
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
    final titleBoxHeight = (titleStyle?.fontSize ?? 14) *
        (titleStyle?.height ?? 1.25) *
        titleMaxLines;
    final titleText = Text(
      item.title,
      maxLines: titleMaxLines,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );

    return ShadowCard(
      radius: 4,
      onTap: () {
        AppNavigator.toLiveRoomDetail(site: site, roomId: item.roomId);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: NetImage(
              item.cover,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            height: 1,
            color: borderColor,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reserveTitleHeight)
                  SizedBox(
                    height: titleBoxHeight,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: titleText,
                    ),
                  )
                else
                  titleText,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Remix.fire_fill,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Utils.onlineToString(item.online),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
