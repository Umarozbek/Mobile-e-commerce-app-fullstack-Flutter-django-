import 'package:flutter/material.dart';

import '../constans/app_colors.dart';
import '../constans/app_sizes.dart';
import '../constans/app_text_styles.dart';

/// Dizayn tizimiga asoslangan tema (001 Colors, 002 Typescale, 004 Spacing)
class AppTheme {
  static TextTheme _textTheme({
    required Color primaryText,
    required Color secondaryText,
  }) {
    return TextTheme(
      headlineLarge: AppTextStyles.h1.copyWith(color: primaryText),
      headlineMedium: AppTextStyles.h2.copyWith(color: primaryText),
      headlineSmall: AppTextStyles.h3.copyWith(color: primaryText),
      bodyLarge: AppTextStyles.bodyL.copyWith(color: primaryText),
      bodyMedium: AppTextStyles.bodyM.copyWith(color: primaryText),
      bodySmall: AppTextStyles.bodyS.copyWith(color: primaryText),
      labelLarge: AppTextStyles.button.copyWith(color: Colors.white),
      labelSmall: AppTextStyles.caption.copyWith(color: secondaryText),
    );
  }

  static AppBarTheme _appBarTheme({
    required Color background,
    required Color iconColor,
    required Color titleColor,
  }) {
    return AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: iconColor),
      titleTextStyle: AppTextStyles.h3.copyWith(color: titleColor),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bgColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, AppDimens.s50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
        ),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(Color fgColor) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: fgColor,
        textStyle: AppTextStyles.bodyM,
      ),
    );
  }

  static CardThemeData _cardTheme(Color color) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      color: color,
    );
  }

  static DividerThemeData _dividerTheme(Color color) {
    return DividerThemeData(
      color: color,
      thickness: AppDimens.divider,
    );
  }

  // -------------------- Light Theme (001, 002, 004) --------------------
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bgMain,
    fontFamily: 'SF Pro Display',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.success,
      error: AppColors.error,
      surface: AppColors.bgSecondary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: AppColors.primaryText,
      onSurfaceVariant: AppColors.secondaryText,
    ),
    appBarTheme: _appBarTheme(
      background: AppColors.bgTertiary,
      iconColor: AppColors.primaryText,
      titleColor: AppColors.primaryText,
    ),
    textTheme: _textTheme(
      primaryText: AppColors.primaryText,
      secondaryText: AppColors.secondaryText,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary),
    textButtonTheme: _textButtonTheme(AppColors.primary),
    cardTheme: _cardTheme(AppColors.bgTertiary),
    dividerTheme: _dividerTheme(AppColors.border),
  );

  // -------------------- Dark Theme --------------------
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bgMainDark,
    fontFamily: 'SF Pro Display',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.success,
      error: AppColors.error,
      surface: AppColors.bgSecondaryDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: AppColors.primaryTextDark,
      onSurfaceVariant: AppColors.secondaryTextDark,
    ),
    appBarTheme: _appBarTheme(
      background: AppColors.bgTertiaryDark,
      iconColor: AppColors.primaryTextDark,
      titleColor: AppColors.primaryTextDark,
    ),
    textTheme: _textTheme(
      primaryText: AppColors.primaryTextDark,
      secondaryText: AppColors.secondaryTextDark,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary),
    textButtonTheme: _textButtonTheme(AppColors.primary),
    cardTheme: _cardTheme(AppColors.bgSecondaryDark),
    dividerTheme: _dividerTheme(AppColors.borderDark),
  );
}
