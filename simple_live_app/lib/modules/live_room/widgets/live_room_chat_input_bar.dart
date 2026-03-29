import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';

class LiveRoomChatInputBar extends StatelessWidget {
  final LiveRoomController controller;
  final bool overlayStyle;
  final double inputHeight;
  final double actionButtonSize;
  final double spacing;
  final bool expandedSendButton;

  const LiveRoomChatInputBar({
    super.key,
    required this.controller,
    this.overlayStyle = false,
    this.inputHeight = 44,
    this.actionButtonSize = 44,
    this.spacing = 12,
    this.expandedSendButton = false,
  });

  void _submitChatMessage() {
    final message = controller.chatInputController.text.trim();
    if (message.isNotEmpty) {
      controller.sendChatMessage(message);
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = overlayStyle
        ? Colors.white.withAlpha(active ? 130 : 90)
        : AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 90 : 140);
    final iconColor = overlayStyle
        ? Colors.white
        : (active ? scheme.primary : scheme.onSurfaceVariant);
    final fillColor = overlayStyle
        ? (active ? Colors.white.withAlpha(24) : Colors.white.withAlpha(8))
        : (active
            ? scheme.primary.withAlpha(Get.isDarkMode ? 36 : 18)
            : Colors.transparent);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppStyle.radius12,
        child: InkWell(
          borderRadius: AppStyle.radius12,
          onTap: onPressed,
          child: Ink(
            width: actionButtonSize,
            height: actionButtonSize,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: AppStyle.radius12,
              border: Border.all(
                color: active && !overlayStyle
                    ? scheme.primary.withAlpha(120)
                    : borderColor,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = overlayStyle
        ? Colors.white.withAlpha(90)
        : AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    final inputBackground = overlayStyle
        ? Colors.white.withAlpha(14)
        : scheme.surfaceContainerHighest.withAlpha(Get.isDarkMode ? 70 : 120);
    final inputShape = RoundedRectangleBorder(borderRadius: AppStyle.radius12);
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.maxWidth.isFinite;
        final inputField = SizedBox(
          height: inputHeight,
          child: TextField(
            controller: controller.chatInputController,
            maxLines: 1,
            textInputAction: TextInputAction.send,
            textAlignVertical: TextAlignVertical.center,
            style: overlayStyle ? const TextStyle(color: Colors.white) : null,
            decoration: InputDecoration(
              hintText: "发送弹幕...",
              hintStyle: overlayStyle
                  ? TextStyle(color: Colors.white.withAlpha(170))
                  : null,
              isDense: true,
              filled: true,
              fillColor: inputBackground,
              constraints: BoxConstraints(
                minHeight: inputHeight,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppStyle.radius12,
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppStyle.radius12,
                borderSide: BorderSide(
                  color: overlayStyle
                      ? Colors.white
                      : scheme.primary.withAlpha(Get.isDarkMode ? 180 : 220),
                ),
              ),
            ),
            onSubmitted: (_) => _submitChatMessage(),
          ),
        );

        final inputWidget = hasBoundedWidth
            ? Expanded(child: inputField)
            : SizedBox(width: 320, child: inputField);

        return Row(
          mainAxisSize: hasBoundedWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _buildActionButton(
              context,
              icon: Remix.emotion_line,
              tooltip: "表情包",
              onPressed: controller.showEmotionPanel,
            ),
            SizedBox(width: spacing == 12 ? 8 : spacing),
            Obx(
              () {
                final running = controller.autoSpamTextRunning.value ||
                    controller.autoSpamEmotionRunning.value ||
                    controller.autoSpamFavoritesRunning.value;
                return _buildActionButton(
                  context,
                  icon: Icons.repeat,
                  tooltip: running ? "自动发送运行中" : "自动发送",
                  onPressed: controller.showAutoSpamSheet,
                  active: running,
                );
              },
            ),
            SizedBox(width: spacing),
            inputWidget,
            SizedBox(width: spacing),
            Tooltip(
              message: "发送",
              child: FilledButton(
                onPressed: _submitChatMessage,
                style: FilledButton.styleFrom(
                  minimumSize: Size(
                    expandedSendButton ? 68 : actionButtonSize,
                    inputHeight,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: expandedSendButton ? 18 : 12,
                  ),
                  shape: inputShape,
                  backgroundColor:
                      overlayStyle ? const Color(0xFF0AA7E8) : scheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: expandedSendButton
                    ? const Text("发送")
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ),
          ],
        );
      },
    );
  }
}
