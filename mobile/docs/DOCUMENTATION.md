# Mart — Flutter loyihasi bo‘yicha batafsil dokumentatsiya

Bu hujjat **Mart** ilovasi uchun arxitektura, sozlash, kod tuzilishi va ishlatiladigan patternlar haqida to‘liq qo‘llanma hisoblanadi.

---

## Mundarija

1. [Loyiha haqida](#1-loyiha-haqida)
2. [Talablar va sozlash](#2-talablar-va-sozlash)
3. [Loyiha arxitekturasi](#3-loyiha-arxitekturasi)
4. [Papka tuzilishi](#4-papka-tuzilishi)
5. [State management (BLoC/Cubit)](#5-state-management-bloccubit)
6. [Dependency Injection (GetIt)](#6-dependency-injection-getit)
7. [Tarmoq qatlami (API)](#7-tarmoq-qatlami-api)
8. [Feature modullari](#8-feature-modullari)
9. [Ko‘p tillilik (Localization)](#9-ko‘p-tillilik-localization)
10. [Tema va dizayn tizimi](#10-tema-va-dizayn-tizimi)
11. [Firebase](#11-firebase)
12. [Xavfsizlik va storage](#12-xavfsizlik-va-storage)
13. [Yangi feature qo‘shish](#13-yangi-feature-qoshish)
14. [Build va reliz](#14-build-va-reliz)

---

## 1. Loyiha haqida

**Mart** — **millionhalal.uz** backend API ga ulangan e-commerce mobil ilova. Foydalanuvchilar mahsulotlarni ko‘rishi, qidirishi, savatga qo‘shishi, buyurtma berishi, loyalty bonus va B2B funksiyalaridan foydalanishi mumkin.

| Parametr | Qiymat |
|----------|--------|
| **Ilova nomi** | mart |
| **Versiya** | 2.0.3+1601 |
| **Flutter SDK** | >=3.0.5 <4.0.0 |
| **Platformalar** | Android, iOS |
| **Asosiy API** | https://millionhalal.uz/api/ |

---

## 2. Talablar va sozlash

### 2.1 Kerakli dasturlar

- **Flutter SDK** 3.x (masalan 3.0.5 yoki yuqori)
- **Dart** 3.0.5+
- **Android Studio** yoki **VS Code** + Flutter extension
- **Git**

### 2.2 Loyihani ishga tushirish

```bash
# Repozitoriyani klonlash (yoki mavjud papkaga o‘tish)
cd mart

# Bog‘liqliklar o‘rnatish
flutter pub get

# Asset va kod generatsiyasi (agar kerak bo‘lsa)
flutter pub run build_runner build --delete-conflicting-outputs
# yoki
dart run build_runner build --delete-conflicting-outputs

# Ilovani ishga tushirish
flutter run
```

### 2.3 Firebase sozlash

- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS)
- `lib/firebase_options.dart` — `flutterfire configure` yoki qo‘lda yozilgan

Firebase loyihasi Console da yaratilgan va Messaging, Analytics yoqilgan bo‘lishi kerak.

### 2.4 Muhim environment

- **API base URL** — `lib/core/constans/api_consts.dart` ichida `ApiConsts.baseUrl`
- Token va maxfiy ma’lumotlar `flutter_secure_storage` orqali saqlanadi (device da)

---

## 3. Loyiha arxitekturasi

Loyiha **Clean Architecture** va **feature-based** tuzilishni qo‘llaydi: har bir funksional modul o‘z papkasida va **data / domain / presentation** qatlamlariga bo‘linadi.

### 3.1 Umumiy sxema

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation                          │
│  (UI: Pages, Widgets | State: Cubit, State/Event)        │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                      Domain                              │
│  (Repository interfaces, Entities)                      │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                        Data                              │
│  (Repository impl, Models, DataSource, API)              │
└─────────────────────────────────────────────────────────┘
```

- **Presentation:** foydalanuvchi bilan muloqat, Cubit orqali holat, Repository ga emas, boshqa Cubitga ham bevosita bog‘lanmaydi (faqat context orqali kerakli Cubit ishlatiladi).
- **Domain:** biznes logika interfeyslari (abstract Repository), entity lar. Hech qanday framework yoki tashqi kutubxona bog‘lanmasligi ma’qul.
- **Data:** API chaqiriqlar, ma’lumotni model ga parse qilish, Repository implementatsiyalari. Barcha tashqi manbalar shu qatlamda.

### 3.2 Oqim (flow) misoli

Foydalanuvchi login qiladi:

1. **LoginPage** → `AuthCubit.login(number, password)` chaqiradi.
2. **AuthCubit** → `AuthRepository.login(...)` chaqiradi (domain interfeysi orqali).
3. **AuthRepositoryImpl** (data) → `ApiClient.post(MainUrls.login, body)` orqali API ga so‘rov yuboradi.
4. API javobini parse qilib `Either<Failure, bool>` qaytaradi.
5. **AuthCubit** natijani qabul qiladi: `response.fold((l) => emit(AuthError(...)), (r) => emit(AuthSuccess(...)))`.
6. **LoginPage** `BlocBuilder` yoki `BlocListener` bilan yangi state ga qarab UI ni yangilaydi yoki boshqa sahifaga o‘tkazadi.

---

## 4. Papka tuzilishi

```
lib/
├── main.dart                      # Kirish nuqtasi, Firebase, EasyLocalization, BlocProvider
├── dependencies_injection.dart     # GetIt: barcha service, repository, cubit ro‘yxatdan o‘tishi
├── firebase_options.dart           # Firebase konfiguratsiyasi (generate)
│
├── core/                           # Umumiy komponentlar
│   ├── constans/                   # API URL, ranglar, o‘lchamlar, matn stillari
│   ├── error/                      # Failure, umumiy xato modellari
│   ├── extention/                  # Padding va boshqa extension lar
│   ├── network/                    # ApiClient (Dio), interceptor lar
│   ├── service/                    # SecureStorage, SessionExpired, FCM, Announcement, Logout
│   ├── theme/                      # AppTheme, ThemeCubit
│   ├── utils/                      # Logger, error utils, language cubit, b2b_helper, sizer
│   └── widgets/                    # Umumiy widget lar (CommonErrorWidget, AppTextField, Shimmer)
│
├── gen/                            # flutter_gen — assets.gen.dart
│
└── features/                       # Har bir funksionallik alohida modul
    ├── auth/                       # Kirish, ro‘yxatdan o‘tish, OTP, token yangilash
    │   ├── data/                   # AuthRepositoryImpl, model lar
    │   ├── domain/                 # AuthRepository (abstract), entities
    │   └── presentation/           # LoginPage, AuthCubit, AuthState
    ├── intro/                      # Til tanlash, onboarding, splash
    ├── main/                       # MainPage (bottom nav), MainCubit, MainBottom
    ├── home/                       # Bosh sahifa: kategoriyalar, banner, mahsulotlar
    ├── search/                     # Qidiruv
    ├── product_detail/             # Mahsulot tafsiloti
    ├── cart/                       # Savat
    ├── orders/                     # Buyurtmalar, to‘lov
    ├── checkout/                   # Checkout
    ├── favourites/                 # Sevimlilar
    ├── profile/                    # Profil
    ├── settings/                   # Sozlamalar (til, mavzu)
    ├── notifications/              # Yangiliklar, FCM, announcement
    ├── loyalty_card/               # Bonus / loyalty kartochka
    ├── referral/                   # Referral
    ├── b2b/                        # B2B ro‘yxatdan o‘tish
    ├── locations/                  # Manzillar
    └── help/                       # Yordam
```

Har bir **feature** ichida:

- **data:** `repository` (impl), `models`, `datasource` (agar bor bo‘lsa)
- **domain:** `repository` (abstract), `entities`
- **presentation:** `page`, `widget`, `cubit`, `state` (va kerak bo‘lsa `event`)

---

## 5. State management (BLoC/Cubit)

Loyihada asosiy state management **flutter_bloc** va **Cubit** dan foydalaniladi.

### 5.1 Cubit tuzilishi

- **Cubit** — `Bloc` ning soddaroq varianti (event yo‘q, faqat method lar orqali state o‘zgaradi).
- Har bir Cubit bitta **State** tipiga ega (masalan `AuthState`, `HomeState`).
- Repository **GetIt** orqali inject qilinadi, Cubit faqat domain (abstract) repository bilan ishlaydi.

Misol (AuthCubit):

```dart
// AuthCubit — domain repository orqali
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  void login({required String number, required String password}) async {
    emit(AuthLoading(type: AuthType.login));
    final response = await _authRepository.login(number: number, password: password);
    response.fold(
      (l) => emit(AuthError(failure: l, type: AuthType.login)),
      (r) => emit(AuthSuccess(type: AuthType.login)),
    );
  }
}
```

### 5.2 State dizayni

- **Equatable** dan foydalanilsa state lar taqqoslash oson bo‘ladi va keraksiz rebuild kamayadi.
- State lar odatda: `Initial`, `Loading`, `Success`, `Error` (va feature ga xos maydonlar).

### 5.3 UI da ishlatish

- **BlocProvider** — Cubit ni context ga berish (loyihada asosan `main.dart` da `MultiBlocProvider`).
- **BlocBuilder\<Cubit, State>** — state o‘zgarganda widget ni qayta qurish.
- **BlocListener\<Cubit, State>** — state o‘zgarganda bir martalik side-effect (snackbar, navigatsiya).
- **context.read\<AuthCubit>()** — Cubit ga kirish va method chaqirish.

### 5.4 Logout va session tugashi

- **SessionExpiredService** — 401 yoki session tugaganda stream orqali xabar beradi.
- **main.dart** da listener: session tugasa `resetAllCubitsOnLogout(context)`, `LogoutStorage.clearForLogout()`, keyin `LoginPage` ga `pushAndRemoveUntil` bilan o‘tkaziladi.

---

## 6. Dependency Injection (GetIt)

Barcha service, repository va cubit lar **GetIt** (`get_it`) orqali ro‘yxatdan o‘tkaziladi. Kirish: `sl<T>()` (masalan `sl<AuthRepository>()`).

### 6.1 Ro‘yxatdan o‘tish turlari

- **registerSingleton** — bir marta yaratiladi, butun ilova davomida bir xil instance (ApiClient, SessionExpiredService, FirebaseMessagingService).
- **registerLazySingleton** — birinchi marta so‘ralganda yaratiladi (repository lar, ba’zi cubit lar).
- **registerFactory** — har safar so‘ralganda yangi instance (AuthCubit, SearchCubit, ProductDetailCubit).

### 6.2 Tartib (dependencies_injection.dart)

1. **Service lar:** `SessionExpiredService`, `ApiClient`, `FirebaseMessagingService`
2. **Data source lar:** masalan `B2BRemoteDataSource`
3. **Repository lar:** barcha `*RepositoryImpl` → abstract `*Repository`
4. **Cubit/Bloc lar:** ularga kerakli repository inject qilinadi

Yangi repository yoki cubit qo‘shilganda shu tartibda `dependencies_injection.dart` ga qo‘shiladi.

---

## 7. Tarmoq qatlami (API)

### 7.1 ApiClient

- **Dio** asosida, `lib/core/network/api_client.dart`.
- Base URL: `ApiConsts.baseUrl` (`api_consts.dart`).
- Header: `Authorization: Bearer <token>` — token `SecureStorage` dan olinadi.
- **CustomErrorInterceptor** — xatolarni qayta ishlash, 401 da `SessionExpiredService` orqali session tugashi ishlatiladi.

### 7.2 So‘rov turlari

- `get(path, queryParams, ...)`
- `post(path, body, ...)`
- `put`, `delete` — kerak bo‘lsa

Javob **StatusModel** (yoki loyihadagi wrapper) orqali: `isSuccess`, `response`, `code` va hokazo.

### 7.3 URL lar

Barcha endpoint lar `lib/core/constans/urls.dart` (MainUrls) da: masalan `MainUrls.login`, `MainUrls.goodsList`, `MainUrls.favoriteList`. Yangi endpoint qo‘shilganda shu yerga const qo‘shiladi.

### 7.4 Xato qaytarish

- Repository lar **dartz** `Either<Failure, T>` qaytaradi.
- **Failure** — `error` (matn) va ixtiyoriy `statusCode` (`core/error/failure.dart`).
- UI da `state is AuthError` yoki `state.failure` orqali xato ko‘rsatiladi.

---

## 8. Feature modullari

Qisqacha ma’lumot:

| Feature | Vazifasi |
|--------|----------|
| **auth** | Login, register, OTP, setPassword, updateToken (eski token → JWT) |
| **intro** | Til tanlash, onboarding, splash |
| **main** | 5 tab: Home, Search, Loyalty, Cart, Profile |
| **home** | Kategoriyalar, banner, mahsulotlar (barcha/top/sale/yangi), tab |
| **search** | Mahsulot qidiruv |
| **product_detail** | Bitta mahsulot tafsiloti |
| **cart** | Savat, buyurtma tasdiqlash |
| **orders** | Buyurtmalar ro‘yxati, to‘lov, payment method |
| **checkout** | Checkout jarayoni |
| **favourites** | Sevimlilar ro‘yxati |
| **profile** | Profil ma’lumoti, chiqish |
| **settings** | Til, mavzu (qorong‘u/yorug‘) |
| **notifications** | Yangiliklar, FCM, announcement dialog |
| **loyalty_card** | Bonus/loyalty kartochka |
| **referral** | Referral kod |
| **b2b** | B2B ro‘yxatdan o‘tish va status |
| **locations** | Manzillar ro‘yxati |
| **help** | Yordam sahifasi |

Har birida: **data** (repository impl, models), **domain** (repository interface), **presentation** (page, cubit, state).

---

## 9. Ko‘p tillilik (Localization)

- **easy_localization** ishlatiladi.
- Tillar: **uz** (default), **ru**, **en**, **ko**.
- Tarjima fayllari: `assets/translations/uz.json`, `ru.json`, `en.json`, `ko.json`.
- Kodda: `'key'.tr()` — masalan `'app_title'.tr()`, `'all'.tr()`.
- Til o‘zgartirish: `context.setLocale(Locale('ru'))` va kerak bo‘lsa `SecureStorage` ga `languageCode` yozish.
- Sana formatlari: `initializeDateFormatting('uz')`, `'ru'`, `'en'`, `'ko'` — `main()` da chaqiriladi.

---

## 10. Tema va dizayn tizimi

- **ThemeCubit** — `ThemeMode` (light / dark) boshqaradi.
- **AppTheme** — `AppTheme.lightTheme`, `AppTheme.darkTheme` (MaterialApp da `theme`, `darkTheme`, `themeMode`).
- **app_colors.dart** — ranglar (light/dark).
- **app_sizes.dart** — `AppDimens`: padding, radius, button balandligi va boshqa o‘lchamlar.
- **app_text_styles.dart** — sarlavha, body, button, caption stillari.
- Font: **SF Pro Display** (`pubspec.yaml` fonts bo‘limida).

Dizayn tizimi “001 Colors, 002 Typescale, 004 Spacing” kabi ichki standartlarga moslashtirilgan.

---

## 11. Firebase

- **Firebase Core** — ilova ishga tushganda initialize.
- **Firebase Messaging** — push bildirishnomalar, foreground/background, notification tap.
- **FirebaseMessagingService** — FCM token, foreground banner, announcement dialog, “logout” action.
- **Firebase Analytics** — `FirebaseAnalyticsObserver` MaterialApp `navigatorObservers` da.
- **Firebase In-App Messaging** — konfiguratsiya bo‘yicha.

Background handler: `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` — `main.dart` da.

---

## 12. Xavfsizlik va storage

- **Token va maxfiy ma’lumotlar:** `flutter_secure_storage` (SecureStorage service orqali). Key lar: `accessToken`, `refreshToken`, `phone_number`, `full_name`, `languageCode`, `fcm_token`, `is_b2b_user` va hokazo.
- **Oddiy key-value:** `GetStorage` — masalan `is_first_time`, eski token migratsiyasi (keyin tozalanadi).
- Logout da: **LogoutStorage.clearForLogout()** — til va onboarding saqlanadi, token va user ma’lumotlari o‘chiriladi.

---

## 13. Yangi feature qo‘shish

Quyidagi tartibni saqlab yangi feature qo‘shish mumkin:

1. **Papka:** `lib/features/<feature_name>/`
2. **domain:**  
   - `repository/<feature_name>_repository.dart` (abstract class).  
   - Kerak bo‘lsa `entities/`.
3. **data:**  
   - `repository/<feature_name>_repository_impl.dart` — ApiClient va URL lar orqali API chaqiruvlari, `Either<Failure, T>` qaytarish.  
   - `models/` — API javob modellari.
4. **presentation:**  
   - `cubit/<feature_name>_cubit.dart` va `cubit/<feature_name>_state.dart`.  
   - `page/<feature_name>_page.dart`, `widget/` kerak bo‘lsa.
5. **GetIt:**  
   - `dependencies_injection.dart` da repository va cubit ro‘yxatdan o‘tkazish.  
   - Cubit global bo‘lishi kerak bo‘lsa `main.dart` da `MultiBlocProvider` ga `BlocProvider(create: (context) => sl<YourCubit>())` qo‘shish.
6. **URL:** yangi endpoint kerak bo‘lsa `urls.dart` ga const qo‘shish.
7. **Navigatsiya:** kerakli joydan `Navigator.push(...)` yoki named route orqali yangi sahifaga o‘tish.

---

## 14. Build va reliz

### 14.1 Debug

```bash
flutter run
# yoki
flutter run --flavor <flavor>  # agar flavor lar bo‘lsa
```

### 14.2 Release (APK / App Bundle)

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 14.3 Boshqa foydali buyruqlar

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

---

## Qisqacha xulosa

- **Mart** — millionhalal.uz API ga ulangan e-commerce ilovasi.
- **Clean Architecture** + **feature-based** tuzilish, **Cubit** (BLoC) + **GetIt**.
- API: **Dio** (ApiClient), URL lar **urls.dart** da, xatolar **Failure** + **Either**.
- Ko‘p tillilik: **easy_localization** (uz, ru, en, ko).
- Tema: **AppTheme** + **ThemeCubit** (light/dark).
- Session: **SessionExpiredService** + **LogoutStorage** + **SecureStorage**.

Yangi o‘zgarishlar va feature lar ushbu dokumentatsiyadagi tuzilish va pattern larga moslashtirilsa, loyiha barqaror va tushunarli bo‘lib qoladi.
