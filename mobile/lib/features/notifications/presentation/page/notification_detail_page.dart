import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_text_styles.dart';
import '../../data/models/notification_model.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgMainDark : AppColors.bgMain;
    final bgAppBar = isDark ? AppColors.bgMainDark : Colors.white;
    final textPrimary = isDark ? AppColors.primaryTextDark : AppColors.primaryText;
    final textSecondary = isDark ? AppColors.secondaryTextDark : AppColors.secondaryText;
    final placeholderBg = isDark ? AppColors.bgTertiaryDark : AppColors.bgSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Bildirishnoma Tafsilotlari',
          style: AppTextStyles.h3.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: bgAppBar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notification.image != null && notification.image!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: notification.image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: placeholderBg,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: placeholderBg,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported_outlined, size: 40, color: textSecondary),
                ),
              ),
            if (notification.image != null && notification.image!.isNotEmpty)
              const SizedBox(height: AppDimens.s20),
            Text(
              notification.title ?? 'Bildirishnoma',
              style: AppTextStyles.h2.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
            ),
            if (notification.createdAt != null && notification.createdAt!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.s8),
              Text(
                _formatDate(notification.createdAt),
                style: AppTextStyles.bodyS.copyWith(color: textSecondary),
              ),
            ],
            const SizedBox(height: AppDimens.s16),
            Text(
              notification.message ?? '',
              style: AppTextStyles.bodyL.copyWith(color: textPrimary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
