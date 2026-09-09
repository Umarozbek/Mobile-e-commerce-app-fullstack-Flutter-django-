

import '../service/secure_storage.dart';

/// B2BHelper - tez tekshirish uchun helper class
/// 
/// DIQQAT: Yangi kod uchun B2BCubit ishlatish tavsiya etiladi!
/// Bu class faqat tez tekshirish uchun qoldirilgan.
class B2BHelper {
  static final SecureStorage _storage = SecureStorage();

  /// B2B user holatini tekshirish
  /// 
  /// Yangi kod uchun B2BCubit.checkB2BStatus() ishlatish tavsiya etiladi
  static Future<bool> isB2BUser() async {
    final isB2B = await _storage.read(key: 'is_b2b_user');
    return isB2B == 'true';
  }

  /// B2B user holatini o'chirish (logout yoki boshqa holatda)
  /// 
  /// Yangi kod uchun B2BCubit.clearB2BStatus() ishlatish tavsiya etiladi
  static Future<void> clearB2BStatus() async {
    await _storage.delete(key: 'is_b2b_user');
    await _storage.delete(key: 'b2b_company_name');
    await _storage.delete(key: 'b2b_inn');
    await _storage.delete(key: 'b2b_address');
    await _storage.delete(key: 'b2b_contact_person');
    await _storage.delete(key: 'b2b_phone_number');
  }
}





