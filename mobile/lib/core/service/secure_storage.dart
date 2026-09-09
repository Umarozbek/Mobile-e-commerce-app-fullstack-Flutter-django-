import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();

  factory SecureStorage() => _instance;

  FlutterSecureStorage? _storage;

  SecureStorage._internal() {
    _storage = FlutterSecureStorage();
  }

  Future<void> write({required String key, required String value}) async {
    await _storage?.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage?.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage?.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage?.deleteAll();
  }

  /// Logout paytida til saqlanib qolishi uchun: barcha ma'lumotlarni tozalaydi,
  /// faqat [languageCode] ni qayta yozadi.
  static const String _languageKey = 'languageCode';
  static const List<String> _supportedLocales = ['uz', 'ru', 'en', 'ko'];

  Future<void> clearAllExceptLanguage() async {
    final savedLang = await read(key: _languageKey);
    final keepLang = savedLang != null &&
        savedLang.isNotEmpty &&
        _supportedLocales.contains(savedLang);
    await deleteAll();
    if (keepLang) {
      await write(key: _languageKey, value: savedLang);
    }
  }

  Future<bool?> containsKey({required String key}) async {
    return await _storage?.containsKey(key: key);
  }
}