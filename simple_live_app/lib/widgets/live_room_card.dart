import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/shadow_card.dart';
import 'package:simple_live_core/simple_live_core.dart';

class LiveRoomCard extends StatelessWidget {
  final Site site;
  final LiveRoomItem item;
  const LiveRoomCard(this.site, this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ShadowCard(
      radius: 16,
      onTap: () {
        AppNavigator.toLiveRoomDetail(site: site, roomId: item.roomId);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: NetImage(
                          item.cover,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Remix.fire_fill,
                                color: Colors.white,
                                size: 12,
                              ),
                              AppStyle.hGap4,
                              Text(
                                Utils.onlineToString(item.online),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: 0.1,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    site.logo,
                    width: 16,
                    height: 16,
                    fit: BoxFit.cover,
                  ),
                ),
                AppStyle.hGap8,
                Expanded(
                  child: Text(
                    item.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
