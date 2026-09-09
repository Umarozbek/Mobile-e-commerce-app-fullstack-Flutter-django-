
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:get_storage/get_storage.dart';

import 'core/service/announcement_storage.dart';
import 'core/service/firebase_messaging_service.dart';
import 'core/service/logout_storage.dart';
import 'core/service/secure_storage.dart';
import 'core/utils/logout_cubits_reset.dart';
import 'core/service/session_expired_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'dependencies_injection.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/page/login_page.dart';
import 'features/auth/presentation/page/update_token_page.dart';
import 'features/b2b/presentation/cubit/b2b_cubit.dart';
import 'features/intro/presentation/page/language_selection_page.dart';
import 'features/intro/presentation/page/onboarding_page.dart';
import 'features/intro/presentation/page/splash_page.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/favourites/presentation/cubit/favourites_cubit.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/locations/presentation/cubit/location_cubit.dart';
import 'features/loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import 'features/main/presentation/cubit/main_cubit.dart';
import 'features/main/presentation/page/main_page.dart';
import 'features/notifications/data/models/announcement_data.dart';
import 'features/notifications/data/models/notification_model.dart';
import 'features/notifications/domain/repository/news_repository.dart';
import 'features/notifications/presentation/cubit/news_cubit.dart';
import 'features/notifications/presentation/page/news_detail_page.dart';
import 'features/notifications/presentation/page/notification_detail_page.dart';
import 'features/notifications/presentation/widget/announcement_dialog.dart';
import 'features/notifications/presentation/widget/foreground_notification_banner.dart';
import 'features/orders/presentation/cubit/order_cubit.dart';
import 'features/orders/presentation/page/order_detail_page.dart';
import 'features/product_detail/presentation/cubit/product_detail_cubit.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/referral/presentation/cubit/referral_cubit.dart';
import 'features/search/presentation/cubit/search_cubit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await EasyLocalization.ensureInitialized();

  // Initialize date formatting for supported locales (month names: February → Fevral in uz, etc.)
  await initializeDateFormatting('uz');
  await initializeDateFormatting('ru');
  await initializeDateFormatting('en');
  await initializeDateFormatting('ko');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize dependency injection
  await serviceLocator();
  
  // Initialize Firebase Messaging Service
  final fcmService = sl<FirebaseMessagingService>();
  await fcmService.initialize();

  // Load saved language (if any) for optimal startup locale
  final savedLanguageCode = await SecureStorage().read(key: 'languageCode');
  final startLocale = (savedLanguageCode != null &&
          savedLanguageCode.isNotEmpty &&
          ['uz', 'ru', 'en', 'ko'].contains(savedLanguageCode))
      ? Locale(savedLanguageCode)
      : const Locale('uz');
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('uz'),
      startLocale:
          startLocale, // Default or saved value; keeps locale consistent across restarts
      child: MyApp(fcmService: fcmService),
    ),
  );
}

class MyApp extends StatefulWidget {
  final FirebaseMessagingService fcmService;
  
  const MyApp({super.key, required this.fcmService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<Map<String, String>> _initialDataFuture;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _sessionExpiredSubscription;
  StreamSubscription<RemoteMessage>? _foregroundNotificationSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;
  StreamSubscription<String>? _actionSubscription;
  StreamSubscription<RemoteMessage>? _announcementSubscription;
  OverlayEntry? _foregroundBannerEntry;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadInitialData();

    _sessionExpiredSubscription =
        sl<SessionExpiredService>().onSessionExpired.listen((_) {
      _handleLogoutAction();
    });

    _notificationTapSubscription =
        widget.fcmService.onNotificationTap.listen((remoteMessage) {
      _handleNotificationTap(remoteMessage);
    });

    // Terminated-state fix: agar ilova push bosilib butunlay yopiq holatdan
    // ochilgan bo'lsa, `initialize()` bu eventni runApp()dan oldin (hech kim
    // streamga obuna bo'lmasdan turib) chiqargan bo'lishi mumkin. Shu yerda
    // qo'lda tekshirib olamiz.
    final pending = widget.fcmService.pendingInitialMessage;
    if (pending != null) {
      widget.fcmService.pendingInitialMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(pending);
      });
    }

    _actionSubscription = widget.fcmService.onAction.listen((action) {
      if (action == 'logout') {
        _handleLogoutAction();
      }
    });

    _announcementSubscription =
        widget.fcmService.onAnnouncementDialog.listen(_showAnnouncementDialog);

    _foregroundNotificationSubscription =
        widget.fcmService.onForegroundNotificationDisplay.listen(_showForegroundNotificationBanner);
  }

  void _showForegroundNotificationBanner(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = _navigatorKey.currentState?.overlay;
      if (overlay == null) return;
      _foregroundBannerEntry?.remove();
      _foregroundBannerEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            // Ostidagi ekranga tegish o'tadi (banner emas joylar)
            IgnorePointer(child: SizedBox.expand()),
            // Banner faqat yuqorida — Positioned bilan
            Positioned(
              top: 15,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: ForegroundNotificationBanner(
                  message: message,
                  onTap: () {
                    _foregroundBannerEntry?.remove();
                    _foregroundBannerEntry = null;
                    _handleNotificationTap(message);
                  },
                  onDismiss: () {
                    _foregroundBannerEntry?.remove();
                    _foregroundBannerEntry = null;
                  },
                ),
              ),
            ),
          ],
        ),
      );
      overlay.insert(_foregroundBannerEntry!);
    });
  }

  void _showAnnouncementDialog(RemoteMessage message) {
    final data = AnnouncementData.fromRemoteMessage(message);
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push<void>(
      MaterialPageRoute(
        builder: (context) => AnnouncementDialog(
          data: data,
          onClose: ({required bool doNotShowAgain}) {
            if (doNotShowAgain) {
              AnnouncementStorage.addDismissedId(data.id);
            }
          },
        ),
      ),
    );
  }
  
  /// Push bosilganda: FCM data (notificationId/type/link) barchasi string
  /// va yo'q bo'lishi mumkin — hech qanday maydonga ishonib qolmasdan xavfsiz
  /// o'qiymiz. Backend (News jadvali) haqiqat manbai — notificationId orqali
  /// to'liq yozuvni qayta so'raymiz, FCM payloadiga to'liq tayanmaymiz.
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;

    // order_status push: {"type": "order_status", "order_id": "<id>", "status": "approved"|"rejected"}
    // Backendning haqiqiy DB statusi "cancelled" (push payloadidagi "rejected"
    // emas) — shuning uchun statusni o'zimiz UI uchun ishlatmaymiz, faqat
    // buyurtma sahifasiga o'tamiz; sahifa haqiqiy statusni backenddan
    // o'zi qayta so'rab oladi (OrderDetailPage.initState -> getOrderById).
    if (data['type']?.toString() == 'order_status') {
      final orderIdStr = data['order_id']?.toString().trim();
      final orderId = (orderIdStr != null && orderIdStr.isNotEmpty)
          ? int.tryParse(orderIdStr)
          : null;
      if (orderId != null) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => OrderDetailPage(orderId: orderId)),
        );
        return;
      }
      // order_id yo'q yoki noto'g'ri — pastdagi umumiy fallbackka tushadi.
    }

    final notificationIdStr = data['notificationId']?.toString().trim();
    final notificationId = (notificationIdStr != null && notificationIdStr.isNotEmpty)
        ? int.tryParse(notificationIdStr)
        : null;

    if (notificationId != null) {
      try {
        final result = await sl<NewsRepository>().getNewsById(notificationId);
        final news = result.fold((_) => null, (n) => n);
        if (news != null) {
          final link = news.link?.trim();
          if (link != null && link.isNotEmpty && link.startsWith('http')) {
            await _openExternalLink(link);
          } else {
            _navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => NewsDetailPage(news: news)),
            );
          }
          return;
        }
      } catch (_) {
        // Backend so'rovi muvaffaqiyatsiz — pastdagi fallback ishlaydi.
      }
    }

    // Fallback: notificationId yo'q, noto'g'ri, yoki backend topa olmadi —
    // hech bo'lmasa push payloadidagi title/body'ni ko'rsatamiz (navigatsiya
    // xatosi yoki bo'sh ekran hosil bo'lmasligi uchun).
    final notification = NotificationModel.fromRemoteMessage(message);
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationDetailPage(notification: notification),
      ),
    );
  }

  Future<void> _openExternalLink(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (_) {
      // Havola ochilmasa ham ilova ishlashda davom etadi.
    }
  }
  
  void _handleLogoutAction() async {
    // Cubitlardagi ma'lumotlarni tozalash (context navigator orqali MultiBlocProvider ichida)
    final ctx = _navigatorKey.currentContext;
    if (ctx != null) resetAllCubitsOnLogout(ctx);

    // Til va onboarding saqlanadi, qolgan barcha ma'lumotlar tozalanadi
    await LogoutStorage.clearForLogout();

    // Navigate to login page, removing all previous routes
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    _foregroundNotificationSubscription?.cancel();
    _notificationTapSubscription?.cancel();
    _actionSubscription?.cancel();
    _announcementSubscription?.cancel();
    _foregroundBannerEntry?.remove();
    widget.fcmService.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _loadInitialData() async {
    // 1. Check SecureStorage first (new storage method)
    String? token = await SecureStorage().read(key: "accessToken");
    String oldTokenValue = "";

    // 2. If not found in SecureStorage, check GetStorage (old storage method)
    if (token == null || token.isEmpty) {
      final box = GetStorage();
      final oldToken = box.read('access_token');
      if (oldToken != null && oldToken.toString().trim().isNotEmpty) {
        oldTokenValue = oldToken.toString().trim();
        if (kDebugMode) {
          print("old_token found, redirecting to UpdateTokenPage");
        }
      }
    }

    // Check B2B status (also check both storages for migration)
    String? isB2B = await SecureStorage().read(key: "is_b2b_user");
    if (isB2B == null || isB2B.isEmpty) {
      final box = GetStorage();
      final oldB2B = box.read('is_b2b_user');
      if (oldB2B != null && oldB2B.toString().isNotEmpty) {
        isB2B = oldB2B.toString();
        await SecureStorage().write(key: "is_b2b_user", value: isB2B);
        box.remove('is_b2b_user');
      }
    }

    return {
      "token": token ?? "",
      "isB2B": isB2B ?? "",
      "oldToken": oldTokenValue,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Check if it's the first time launch
    bool isFirstTime = GetStorage().read('is_first_time') ?? true;
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthCubit>()),
        BlocProvider(create: (context) => sl<B2BCubit>()),
        BlocProvider(create: (context) => sl<HomeCubit>()),
        BlocProvider(create: (context) => sl<FavouritesCubit>()..getFavouritesList()),
        BlocProvider(create: (context) => sl<SearchCubit>()),
        BlocProvider(create: (context) => sl<ProductDetailCubit>()),
        BlocProvider(create: (context) => sl<ProfileCubit>()),
        BlocProvider(create: (context) => sl<LoyaltyCardCubit>()),
        BlocProvider(create: (context) => sl<ReferralCubit>()),
        BlocProvider(create: (context) => sl<CartCubit>()),
        BlocProvider(create: (context) => sl<LocationCubit>()..loadLocations()),
        BlocProvider(create: (context) => sl<OrderCubit>()),
        BlocProvider(create: (context) => sl<NewsCubit>()),
        BlocProvider(create: (context) => sl<MainCubit>()),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: const TextScaler.linear(1.0), // 🔥 Font scale fix
                ),
                child: SafeArea(
                  bottom: true,
                  top: false,
                  right: false,
                  left: false,
                  child: child!,
                ),
              );
            },
            navigatorKey: _navigatorKey,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
            title: 'app_title'.tr(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale, // This is crucial for dynamic language switching
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: isFirstTime 
                ? const LanguageSelectionPage() 
                : FutureBuilder<Map<String, String>>(
                    future: _initialDataFuture,
                    builder: (context, snapshot) {
                      // Loading message while data is being fetched
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SplashPage();
                      }
    
                      final data = snapshot.data ?? {};
                      final token = data["token"] ?? "";
                      final oldToken = data["oldToken"] ?? "";

                      if (oldToken.isNotEmpty) {
                        return const UpdateTokenPage();
                      }
                      return token.isNotEmpty ? const MainPage() : const LoginPage();
                    },
                  ),
          );
        },
      ),
    );
  }
}

