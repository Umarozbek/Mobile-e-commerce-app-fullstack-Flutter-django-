import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_text_styles.dart';
import '../../data/models/announcement_data.dart';

/// In-app announcement dialog: push orqali kelgan ma'lumot (data-only).
/// "Qayta ko'rsatilmasin" va "Berkitish" tugmasi.
class AnnouncementDialog extends StatefulWidget {
  final AnnouncementData data;
  final void Function({required bool doNotShowAgain}) onClose;

  const AnnouncementDialog({
    super.key,
    required this.data,
    required this.onClose,
  });

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog> {
  bool _doNotShowAgain = false;

  void _handleClose() {
    widget.onClose(doNotShowAgain: _doNotShowAgain);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary;
    final textColor = isDark ? AppColors.primaryTextDark : AppColors.primaryText;

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.s20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(AppDimens.r16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sarlavha: bell + title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.s16,
                      AppDimens.s16,
                      AppDimens.s16,
                      AppDimens.s8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 24,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppDimens.s8),
                        Expanded(
                          child: Text(
                            widget.data.title,
                            style: AppTextStyles.h3.copyWith(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body (matn yoki HTML)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
                    child: _buildBody(textColor),
                  ),
                  if (widget.data.imageUrl != null && widget.data.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.s12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        child: Image.network(
                          widget.data.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimens.s20),
                  // Checkbox: Qayta ko'rsatilmasin
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
                    child: InkWell(
                      onTap: () => setState(() => _doNotShowAgain = !_doNotShowAgain),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _doNotShowAgain,
                            onChanged: (v) => setState(() => _doNotShowAgain = v ?? false),
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: Text(
                              'announcement_do_not_show'.tr(),
                              style: AppTextStyles.bodyM.copyWith(color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.s12),
                  // Tugma: Berkitish
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.s16,
                      0,
                      AppDimens.s16,
                      AppDimens.s20,
                    ),
                    child: SizedBox(
                      height: AppDimens.s50,
                      child: ElevatedButton(
                        onPressed: _handleClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.r12),
                          ),
                        ),
                        child: Text('announcement_close'.tr(), style: AppTextStyles.button),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Color textColor) {
    final body = widget.data.body;
    if (body.trim().isEmpty) return const SizedBox.shrink();
    // Agar HTML bo'lsa (tag bilan boshlansa) HTML render qilamiz
    final trimmed = body.trim().toLowerCase();
    if (trimmed.startsWith('<') && (trimmed.contains('</') || trimmed.contains('/>'))) {
      return HtmlWidget(
        body,
        textStyle: AppTextStyles.bodyM.copyWith(color: textColor),
      );
    }
    return Text(
      body,
      style: AppTextStyles.bodyM.copyWith(color: textColor),
    );
  }
}
