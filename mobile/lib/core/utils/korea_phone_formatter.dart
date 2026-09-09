import 'package:flutter/services.dart';

class KoreaBodyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'\D'), ''); // Faqat raqamlar
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 6) {
        buffer.write(' '); // 10 1234 5678 ko'rinishi uchun bo'shliqlar
      }
      buffer.write(text[i]);
    }

    String formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}