import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_text_styles.dart';

/// Foreground da kelgan oddiy push — Instagram uslubida yuqorida banner.
/// Bosilsa NotificationDetailPage ga boradi; 4 sekunddan keyin avtomatik yopiladi.
class ForegroundNotificationBanner extends StatefulWidget {
  final RemoteMessage message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const ForegroundNotificationBanner({
    super.key,
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<ForegroundNotificationBanner> createState() =>
      _ForegroundNotificationBannerState();
}

class _ForegroundNotificationBannerState extends State<ForegroundNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    _slideController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  void _handleTap() {
    _autoDismissTimer?.cancel();
    widget.onTap();
    _slideController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.message.notification?.title ??
        widget.message.data['title']?.toString() ??
        '';
    final body = widget.message.notification?.body ??
        widget.message.data['body']?.toString() ??
        widget.message.data['message']?.toString() ??
        '';
    final bg = isDark ? AppColors.bgSecondaryDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    // Title + body bitta qatorda (title • body) yoki faqat biri
    final subtitle = title.isNotEmpty && body.isNotEmpty
        ? '$title • $body'
        : (title.isNotEmpty ? title : body);
    final displayLine = subtitle.length > 80 ? '${subtitle.substring(0, 80)}…' : subtitle;

    // Overlay da Positioned bilan yuqorida — faqat ixcham kartochka
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _handleTap,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -100) {
              _dismiss();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.s12,
              vertical: AppDimens.s10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDimens.r12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.r8),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDimens.s12),
                Expanded(
                  child: Text(
                    displayLine,
                    style: AppTextStyles.bodyS.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.primaryTextDark
                          : AppColors.primaryText,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimens.s4),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.secondaryTextDark
                      : AppColors.secondaryText,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
