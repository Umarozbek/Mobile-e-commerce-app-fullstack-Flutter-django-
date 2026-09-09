# Ilova xavfsizligi tekshiruvi – Million Halal Mart

Tekshiruv sanasi: 2025. Qisqa xulosa: **yaxshi** (SecureStorage, HTTPS, allowBackup=false), lekin bir nechta muhim kamchiliklar va yaxshilashlar bor.

---

## Yaxshi qilingan ishlar

1. **Tokenlar SecureStorage da** – JWT va FCM token `FlutterSecureStorage` (Android: EncryptedSharedPreferences, iOS: Keychain) da saqlanadi.
2. **HTTPS** – Asosiy API `https://million-halal-mart-6jij.onrender.com` orqali ishlatiladi.
3. **Android allowBackup=false** – Ilova ma’lumotlari backup ga kirmaydi, tokenlar taqdimotdan himoyalangan.
4. **Parol maydonlari** – Login va parol o‘rnatish sahifalarida `obscureText: true`.
5. **Logout** – Til va onboarding saqlanib, qolgan ma’lumotlar tozalanadi.
6. **401 va refresh** – Sessiya tugaganda refresh token ishlatiladi, ishlamasa logout qilinadi.

---

## Kamchiliklar va tavsiyalar

### 1. **JUDDA MUHIM: Debug rejimida token va parol loglarda**

**Qayerda:** `lib/core/network/api_client.dart` 67–70 qatorlar.

```dart
if (kDebugMode) {
  logger.i("$method request URL: $url\nStatus: ... \nHeaders: ${headers}  \nResponse: ${response.data}");
}
```

**Muammo:** `headers` ichida `Authorization: Bearer <JWT>` bor; `response.data` da parol, token yoki shaxsiy ma’lumotlar bo‘lishi mumkin. Debug build’da bu ma’lumotlar logga yoziladi (adb logcat, IDE console). Boshqa ilovalar yoki root qurilmalarda loglar o‘qilishi mumkin.

**Tavsiya:** Debug logda **hech qachon** token, parol va PII chiqarmang. Faqat URL va status code loglang; body/headers ni loglamang yoki tokenlarni `***` bilan almashtiring.

---

### 2. **Firebase API kalitlari repozitoriyda**

**Qayerda:** `lib/firebase_options.dart` – barcha platformalar uchun `apiKey` va boshqa ma’lumotlar ochiq.

**Muammo:** Repo public bo‘lsa, kalitlar ko‘rinadi. Firebase client API kalitlari odatda “public” hisoblanadi va Firebase Console’da qisob (SHA, package name) bilan cheklanadi, lekin maxsus kalitlar yoki boshqa secret’lar shu faylda bo‘lmasligi kerak.

**Tavsiya:** Repo private bo‘lishi yoki Firebase App Check yoqilishi; kalitlar faqat loyiha a’zolariga ochiq bo‘lsin.

---

### 3. **Cleartext (HTTP) ruxsat etilgan domenlar**

**Qayerda:** `android/app/src/main/res/xml/network_security_config.xml` – `209.38.109.22`, localhost va boshqa domenlar uchun `cleartextTrafficPermitted="true"`.

**Muammo:** Agar ilova yoki backend qandaydir sabab bilan shu IP/host’ga HTTP orqali so‘rov yuborsa, tarmoqda sniffing orqali token va ma’lumotlar o‘g‘irlanishi mumkin.

**Tavsiya:** Barcha production API’lar faqat HTTPS orqali ishlatilsin; HTTP faqat development (masalan, localhost) uchun qolsin va production build’da ishlatilmasin.

---

### 4. **SSL/TLS certificate pinning yo‘q**

**Muammo:** Hozir tizim va foydalanuvchi sertifikatlariga ishoniladi. Yaqin tarmoqda (masalan, zararli Wi‑Fi) MITM proxy orqali trafikni qayta yo‘naltirish va JWT’ni o‘g‘irlash mumkin.

**Tavsiya:** Production ilova uchun HTTPS certificate pinning qo‘shish (masalan, `dio_http2_adapter` yoki `HttpCertificatePinning`). Pinning xato konfiguratsiyasi servisni sindirishi mumkin, shuning uchun ehtiyotkorlik bilan joriy qiling.

---

### 5. **GetStorage’da eski token migratsiyasi**

**Qayerda:** `main.dart` va `update_token_page.dart` – eski token `GetStorage()` (oddiy key-value) da o‘qiladi.

**Muammo:** GetStorage shifrlangan emas. Eski token hali device’da bo‘lsa, root yoki backup orqali o‘qilishi mumkin (allowBackup=false faqat yangi backup’larni oldini oladi).

**Tavsiya:** Migratsiya tugagach, GetStorage’dagi `access_token` va boshqa token kalitlarini butunlay o‘chirib, faqat SecureStorage ishlatilishini ta’minlang.

---

### 6. **Parol minimal uzunlik va format**

**Qayerda:** `set_password_page.dart` – faqat “6 ta belgi” tekshiriladi; `login_page.dart` – faqat bo‘sh-emasligi.

**Muammo:** Juda oddiy parollar (123456, 000000) ruxsat etiladi; telefon raqami formatı (masalan, faqat raqam, ma’lum uzunlik) qat’iy tekshirilmaydi.

**Tavsiya:** Parol uchun minimal murakkablik (katta/kichik, raqam, belgi), max uzunlik va telefon uchun format (masalan, 9–12 ta raqam) qo‘shish; serverda ham bir xil qoidalar bo‘lsin.

---

### 7. **Session timeout (ilova ichida) yo‘q**

**Muammo:** Foydalanuvchi ilovani uzoq vaqt ochib qoldirsa ham, token amal qilish muddati tugaguncha sessiya davom etadi. JWT o‘g‘irlansa, muddat tugaguncha ishlatilishi mumkin.

**Tavsiya:** Backend’da access token muddati qisqa (masalan, 15–60 daqiqa), refresh token esa alohida, max muddat va bir marta ishlatish (rotation) qoidalari qo‘llanadi. Ilovada ixtiyoriy: uzoq inactive’dan keyin “qayta kirish” so‘rashi.

---

### 8. **FCM token va boshqa tokenlar release’da loglanmasligi**

**Holat:** `firebase_messaging_service.dart` da FCM token faqat `kDebugMode` da loglanadi; token yozuv esa endi har doim bajariladi (bug tuzatildi).

**Tavsiya:** Boshqa joylarda ham token, parol yoki shaxsiy ma’lumotlar hech qachon release build’da logga chiqmasin; faqat `kDebugMode` ichida va token/parol olib tashlangan holda loglang.

---

## Qilingan tuzatishlar (ushbu tekshiruv davomida)

1. **loyalty_card_repository_impl.dart** – Kommentariyadagi **to‘liq JWT token** o‘chirildi (token o‘g‘irlansa sessiya buzilishi mumkin edi).
2. **firebase_messaging_service.dart** – FCM token **release** build’da ham SecureStorage’ga yoziladi; log esa faqat `kDebugMode` da chiqadi.

---

## Qisqa prioritet ro‘yxati

| Prioritet | Tavsiya |
|----------|--------|
| Yuqori   | Api_client da debug log’dan token/headers/response body ni olib tashlash yoki maskalash. |
| Yuqori   | GetStorage’dagi token migratsiyasini to‘liq tugatib, faqat SecureStorage ishlatish. |
| O‘rta     | Parol va telefon validatsiyasini kuchaytirish (format, murakkablik). |
| O‘rta     | Barcha production API’ni faqat HTTPS’ga o‘tkazish; HTTP ni faqat dev uchun qoldirish. |
| Past     | Certificate pinning ni joriy qilish (ehtiyotkorlik bilan). |
| Past     | Firebase App Check va repo private ekanligini tekshirish. |

---

Agar xohlasangiz, keyingi qadamda `api_client.dart` dagi log’ni xavfsiz (token/parol chiqmasdan) qilish uchun aniq kod o‘zgarishlarini yozib beraman.
