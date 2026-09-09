import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/service/secure_storage.dart';

class LanguageSelectionBottomSheet extends StatefulWidget {
  const LanguageSelectionBottomSheet({super.key});

  /// Settings sahifasidan chaqirish uchun static metod
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LanguageSelectionBottomSheet(),
    );
  }

  @override
  State<LanguageSelectionBottomSheet> createState() =>
      _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState
    extends State<LanguageSelectionBottomSheet> {
  String? _selectedLanguage;

  final List<Map<String, String>> _languages = [
    {
      'code': 'uz',
      'name': "O'zbekcha",
      'flag': Assets.icons.flags.flagUz,
    },
    {
      'code': 'ru',
      'name': 'Русский',
      'flag': Assets.icons.flags.flagRu,
    },
    {
      'code': 'en',
      'name': 'English',
      'flag': Assets.icons.flags.flagUk,
    },
    {
      'code': 'ko',
      'name': '한국어',
      'flag': Assets.icons.flags.flagKr,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Joriy tilni aniqlash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedLanguage = context.locale.languageCode;
        });
      }
    });
  }

  Future<void> _onLanguageSelected(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });

    // Tilni o'zgartirish
    await context.setLocale(Locale(languageCode));

    // Saqlash
    await SecureStorage().write(key: 'languageCode', value: languageCode);

    // Bottom sheet'ni yopish
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.r24),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.s20,
        vertical: AppDimens.s20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(AppDimens.r4),
            ),
          ),
          const SizedBox(height: AppDimens.s20),

          // Title
          Row(
            children: [
              Icon(
                Icons.language,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
                size: AppDimens.icon24,
              ),
              const SizedBox(width: AppDimens.s12),
              Text(
                'language'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.primaryTextDark
                      : AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),

          // Language list
          ...List.generate(_languages.length, (index) {
            final lang = _languages[index];
            final isSelected = _selectedLanguage == lang['code'];
            return _buildLanguageItem(
              context: context,
              code: lang['code']!,
              name: lang['name']!,
              flag: lang['flag']!,
              isSelected: isSelected,
              isDark: isDark,
            );
          }),

          const SizedBox(height: AppDimens.s8),
        ],
      ),
    );
  }

  Widget _buildLanguageItem({
    required BuildContext context,
    required String code,
    required String name,
    required String flag,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _onLanguageSelected(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: AppDimens.s10),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.s16,
          vertical: AppDimens.s14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark : AppColors.primary)
                  .withOpacity(0.12)
              : (isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary),
          borderRadius: BorderRadius.circular(AppDimens.r12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primary)
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgMainDark : AppColors.bgMain,
                borderRadius: BorderRadius.circular(AppDimens.r8),
              ),
              child: Center(
                child: SvgPicture.asset(
                  flag,
                  width: 24,
                  height: 18,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.s16),

            // Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: AppDimens.s16,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.primaryDark : AppColors.primary)
                      : (isDark
                          ? AppColors.primaryTextDark
                          : AppColors.primaryText),
                ),
              ),
            ),

            // Check icon
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.check_circle,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
                size: AppDimens.icon24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
