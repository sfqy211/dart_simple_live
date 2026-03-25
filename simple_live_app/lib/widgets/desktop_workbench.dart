import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';

class DesktopWorkbenchLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget content;

  const DesktopWorkbenchLayout({
    required this.sidebar,
    required this.content,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        sidebar,
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: content,
          ),
        ),
      ],
    );
  }
}

class DesktopWorkbenchSidebar extends StatelessWidget {
  final List<DesktopWorkbenchSectionData> sections;
  final double width;

  const DesktopWorkbenchSidebar({
    required this.sections,
    this.width = 312,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              child: Text(
                section.title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (section.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  section.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppStyle.mutedTextColor(context),
                      ),
                ),
              ),
            ...section.items.map(
              (item) => _DesktopWorkbenchSidebarItem(item: item),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DesktopWorkbenchSidebarItem extends StatelessWidget {
  final DesktopWorkbenchItemData item;

  const _DesktopWorkbenchSidebarItem({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fillColor = item.selected
        ? scheme.primary.withAlpha(Get.isDarkMode ? 24 : 14)
        : Colors.transparent;
    final borderColor = item.selected
        ? scheme.primary.withAlpha(Get.isDarkMode ? 72 : 48)
        : Colors.transparent;
    final textColor =
        item.selected ? scheme.onSurface : theme.colorScheme.onSurface;
    final hintColor = item.selected
        ? scheme.onSurfaceVariant
        : AppStyle.mutedTextColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight:
                          item.selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.hint.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    item.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopWorkbenchSectionData {
  final String title;
  final String description;
  final List<DesktopWorkbenchItemData> items;

  const DesktopWorkbenchSectionData({
    required this.title,
    required this.description,
    required this.items,
  });
}

class DesktopWorkbenchItemData {
  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const DesktopWorkbenchItemData({
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });
}
