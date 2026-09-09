import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../constans/app_colors.dart';
import '../constans/app_sizes.dart';
import '../utils/error_utils.dart';

class CommonErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData? icon;
  final String? title;
  final String? buttonText;

  const CommonErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon,
    this.title,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.wifi_off_rounded,
                size: 48,
                color: isDark ? Colors.red.shade300 : Colors.red.shade400,
              ),
            ),
            const SizedBox(height: AppDimens.s24),
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              ErrorUtils.getErrorMessage(message, context),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.s32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(
                  buttonText ?? 'retry'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
