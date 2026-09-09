import 'dart:convert';
import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Pending (background da saqlanadi) va dismissed announcement lar.
/// Pending ro'yxati faylda — background va main isolate bir xil fayldan o'qiydi.
class AnnouncementStorage {
  static const String _keyDismissedIds = 'dismissed_announcement_ids';
  static const String _pendingFileName = 'pending_announcements.json';

  static final GetStorage _box = GetStorage();

  /// Background handler da chaqirish shart emas; pending faylga yoziladi.
  static void ensureInit() {
    GetStorage.init();
  }

  static Future<File> _pendingFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_pendingFileName');
  }

  /// Pending ro'yxatiga qo'shish (background da chaqiriladi — faylga yozadi).
  static Future<void> addPending(Map<String, dynamic> data) async {
    ensureInit();
    final file = await _pendingFile();
    List<Map<String, dynamic>> list = [];
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final decoded = jsonDecode(content) as List<dynamic>?;
        list = decoded?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      } catch (_) {
        list = [];
      }
    }
    list.add(data);
    await file.writeAsString(jsonEncode(list));
  }

  /// Pending ro'yxatini olish (fayldan — main isolate).
  static Future<List<Map<String, dynamic>>> getPendingListRaw() async {
    final file = await _pendingFile();
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as List<dynamic>?;
      return decoded?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Pending dan bitta olib tashlash (ko'rsatilgach).
  static Future<void> removeFirstPending() async {
    final list = await getPendingListRaw();
    if (list.isEmpty) return;
    list.removeAt(0);
    final file = await _pendingFile();
    await file.writeAsString(jsonEncode(list));
  }

  /// "Qayta ko'rsatilmasin" bosilgan id larni saqlash (faqat main isolate).
  static Future<void> addDismissedId(String id) async {
    final list = List<String>.from((_box.read(_keyDismissedIds) as List<dynamic>?)?.cast<String>() ?? []);
    if (!list.contains(id)) {
      list.add(id);
      await _box.write(_keyDismissedIds, list);
    }
  }

  /// Berilgan id avval "qayta ko'rsatilmasin" da bormi.
  static bool isDismissed(String id) {
    final list = (_box.read(_keyDismissedIds) as List<dynamic>?)?.cast<String>() ?? [];
    return list.contains(id);
  }
}
