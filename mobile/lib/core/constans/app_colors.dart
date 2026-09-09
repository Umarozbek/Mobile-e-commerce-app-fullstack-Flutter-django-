import 'package:flutter/material.dart';

/// Dizayn tizimi 001 — Colors
class AppColors {
  AppColors._();

  // -------------------- Primary --------------------
  /// Primary gradient: #3F6F8F → #D9CFA6
  ///
  ///
  /// ------Light Mode
  static const Color primaryGradientStart = Color(0xFF3F6F8F);
  static const Color primaryGradientEnd = Color(0xFFD9CFA6);

  // static const Color primary = Color(0xFFEBB755); // Primary Solid
  static const Color primary = Color(0xFF3F6E8E); // Primary Solid

  // -------------------- Text --------------------
  static const Color primaryText = Color(0xFF1E2A35);
  static const Color secondaryText = Color(0xFF5E6E7B);
  static const Color disabledText = Color(0xFF99A7B1);

  // -------------------- Background --------------------
  static const Color bgMain = Color(0xFFF5F7F9);

  static const Color bgSecondary = Color(0xFFECF0F4);
  static const Color bgTertiary = Color(0xFFFDFDFD);

  // -------------------- Border --------------------
  static const Color border = Color(0xFFE7E7E7);

  /// --------DarkMode

  // static const Color primary = Color(0xFFEBB755); // Primary Solid
  static const Color primaryDark = Color(0xFF3473A4); // Primary Solid

  // -------------------- Text --------------------
  static const Color primaryTextDark = Color(0xFFE6EEF4);
  static const Color secondaryTextDark = Color(0xFFB2C0CA);
  static const Color disabledTextDark = Color(0xFF7B8E9C);

  // -------------------- Background --------------------
  static const Color bgMainDark = Color(0xFF0E1720);
  static const Color bgSecondaryDark = Color(0xFF152230);
  static const Color bgTertiaryDark = Color(0xFF1B2C3A);

  static const Color borderDark = Color(0xFF2A2F36);

  // -------------------- Status (001) --------------------
  static const Color success = Color(0xFF045C55);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFC0423F);
  static const Color info = Color(0xFF4361EE);

  // -------------------- Grid / Status variants (005) --------------------
  static const Color successVariant = Color(0xFF10B981);
  static const Color warningVariant = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color infoVariant = Color(0xFF17A2B8);

  // -------------------- Light theme (alias) --------------------
  static const Color lightBackground = bgMain;
  static const Color greyBackground = bgSecondary;
  static const Color lightTextPrimary = primaryText;
  static const Color lightTextSecondary = secondaryText;
  static const Color lightTextHint = disabledText;
  static const Color borderLight = border;
  static const Color dividerLight = border;

  // -------------------- Dark theme --------------------
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF2C2C2E);
  static const Color darkBorder = Color(0xFF3A3A3C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);

  // -------------------- Misc --------------------
  static const Color transparent = Colors.transparent;
  static const Color progress = success;
  static const Color progressBackground = border;

  /// Primary gradient: #3F6F8F → #D9CFA6 (001)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomLeft,
    colors: [primaryGradientStart, primaryGradientEnd],
  );

  // -------------------- Loyalty VIP Card (gold/bronze) --------------------
  static const Color loyaltyCardGradientStart = Color(0xFFD2AE37);
  static const Color loyaltyCardGradientEnd = Color(0xFFA57B2D);
  static const LinearGradient loyaltyCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomLeft,
    colors: [ loyaltyCardGradientEnd,loyaltyCardGradientStart, loyaltyCardGradientEnd],
  );
}
