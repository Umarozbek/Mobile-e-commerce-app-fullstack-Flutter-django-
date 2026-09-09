import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class ErrorUtils {
  /// "Exception: Connection Error" kabi matnlarni olib tashlaydi va tarmoq/server
  /// xatolarini tarjima qiladi. Foydalanuvchiga texnik so'zlar chiqmasligi kerak.
  static String _normalizeTechnicalMessage(String text) {
    String s = text.trim();
    // "Exception: ..." yoki "Error: ..." prefiksini olib tashlash
    const prefixes = ['Exception:', 'Error:', 'Exception :', 'Error :'];
    for (final prefix in prefixes) {
      if (s.toLowerCase().startsWith(prefix.toLowerCase())) {
        s = s.substring(prefix.length).trim();
        break;
      }
    }
    return s;
  }

  /// Tarmoq/server va boshqa texnik xabarlarni tilga mos matnga o'giradi
  static String getErrorMessage(String errorString, BuildContext context) {
    final raw = errorString.trim();
    if (raw.isEmpty) return 'error'.tr();

    // Avval JSON (backend dan kelgan ko'p tilli xato) bo'lsa qaytaramiz
    try {
      if (raw.startsWith('{') || raw.startsWith('[')) {
        final dynamic error = jsonDecode(raw);

        if (error is Map) {
          final locale = context.locale.languageCode;
          String key = locale;
          if (locale == 'ko' && error.containsKey('kr')) key = 'kr';
          if (error.containsKey(key)) return error[key].toString();
          if (error.containsKey('en')) return error['en'].toString();
          if (error.containsKey('uz')) return error['uz'].toString();
          if (error.containsKey('ru')) return error['ru'].toString();
          if (error.isNotEmpty) return error.values.first.toString();
        }
      }
    } catch (_) {}

    // Texnik prefikslarni olib tashlash
    final normalized = _normalizeTechnicalMessage(raw);

    // Tarmoq / ulanish xatolari
    final lower = normalized.toLowerCase();
    if (lower.contains('connection error') ||
        lower.contains('connection refused') ||
        lower.contains('connection timeout') ||
        lower.contains('socket') ||
        lower.contains('network') && lower.contains('error') ||
        lower == 'connection error') {
      return 'network_error'.tr();
    }

    // Server xatosi (5xx)
    if (lower.contains('server error') || lower.contains('500') || lower.contains('503')) {
      return 'server_error'.tr();
    }

    // Umumiy "Error" yoki juda qisqa texnik matn
    if (normalized.isEmpty || normalized.toLowerCase() == 'error') {
      return 'error'.tr();
    }

    return normalized;
  }
}
