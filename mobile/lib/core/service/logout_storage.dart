import 'package:get_storage/get_storage.dart';

import 'secure_storage.dart';

/// Logout paytida: til va onboarding (is_first_time, language_selected) saqlanadi,
/// qolgan barcha ma'lumotlar tozalanadi.
class LogoutStorage {
  static const String _keyFirstTime = 'is_first_time';
  static const String _keyLanguageSelected = 'language_selected';
  static const String _keyAccessToken = 'access_token';

  static Future<void> clearForLogout() async {
    await SecureStorage().clearAllExceptLanguage();

    final box = GetStorage();
    final isFirstTime = box.read(_keyFirstTime);
    final languageSelected = box.read(_keyLanguageSelected);

    await box.erase();

    if (isFirstTime != null) {
      await box.write(_keyFirstTime, isFirstTime);
    }
    if (languageSelected != null) {
      await box.write(_keyLanguageSelected, languageSelected);
    }

    // access_token endi GetStorage'ga yozilmaydi – tokenlar faqat SecureStorage'da
  }
}
