import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dizayn tizimi 002 — Typescale / App
class AppTextStyles {
  AppTextStyles._();

  // -------------------- Base Font --------------------
  /// SF Pro (iOS). Boshqa platformalarda Metro yoki system default.
  static const String fontFamily = 'Metro';

  // -------------------- Headings --------------------
  /// 24px / SemiBold / H1 — line height 29px
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 29 / 24,
    fontFamily: fontFamily,
  );

  /// 20px / Medium / H2 — line height 26px
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 26 / 20,
    fontFamily: fontFamily,
  );

  /// 18px / Medium / H3 — line height 24px
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    fontFamily: fontFamily,
  );

  // -------------------- Body --------------------
  /// 16px / Regular / Body LG — line height 22px
  static const TextStyle bodyL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 22 / 16,
    fontFamily: fontFamily,
  );

  /// 14px / Regular / Body MD — line height 20px
  static const TextStyle bodyM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    fontFamily: fontFamily,
  );

  /// 12px / Regular / Body SM — line height 16px
  static const TextStyle bodyS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    fontFamily: fontFamily,
  );

  // -------------------- Overline --------------------
  /// 12px / Regular / Overline Upper — line height 15px
  static const TextStyle overline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 15 / 12,
    fontFamily: fontFamily,
  );

  // -------------------- Button --------------------
  /// 16px / Semibold / Button — line height 20px
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    fontFamily: fontFamily,
  );

  // -------------------- Input --------------------
  /// 16px / Regular / Input — line height 22px
  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 22 / 16,
    fontFamily: fontFamily,
  );

  // -------------------- Caption (alias) --------------------
  static const TextStyle caption = bodyS;
  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    fontFamily: fontFamily,
  );

  // -------------------- Hint & Error --------------------
  static TextStyle hint({Color? color}) =>
      bodyM.copyWith(color: color ?? AppColors.disabledText);

  static TextStyle error({Color? color}) =>
      caption.copyWith(color: color ?? AppColors.error);

  // -------------------- Theme helpers --------------------
  static TextStyle bodyMLight() =>
      bodyM.copyWith(color: AppColors.primaryText);

  static TextStyle bodyMDark() =>
      bodyM.copyWith(color: AppColors.darkTextPrimary);

  static TextStyle bodySLight() =>
      bodyS.copyWith(color: AppColors.secondaryText);

  static TextStyle bodySDark() =>
      bodyS.copyWith(color: AppColors.darkTextSecondary);
}
