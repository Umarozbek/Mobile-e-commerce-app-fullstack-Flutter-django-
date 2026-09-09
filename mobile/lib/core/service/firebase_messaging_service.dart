import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:mart/core/constans/urls.dart';
import 'package:mart/core/network/api_client.dart';
import 'package:mart/core/service/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'announcement_storage.dart';
import 'logout_storage.dart';

/// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate da GetStorage ishlashi uchun
  await GetStorage.init();
  final logger = Logger();
  logger.i('Background message received: ${message.messageId}');
  logger.i('Title: ${message.notification?.title}');
  logger.i('Body: ${message.notification?.body}');
  logger.i('Data: ${message.data}');
  
  // Handle silent notifications (data-only)
  if (message.notification == null || 
      (message.notification?.title == null && message.notification?.body == null)) {
    logger.i('Silent notification detected, executing data action');
    await _handleBackgroundDataActionStatic(message.data, logger);
  }
}

/// Static helper for handling data actions in background
Future<void> _handleBackgroundDataActionStatic(Map<String, dynamic> data, Logger logger) async {
  if (data.isEmpty) {
    logger.w('No data in silent notification');
    return;
  }

  final action = data['action'];
  logger.i('Executing action: $action');

  switch (action) {
    case 'refresh_cart':
      logger.i('Action: Refresh cart triggered');
      // Cart refresh logic will be handled by the app when it comes to foreground
      break;
    case 'refresh_orders':
      logger.i('Action: Refresh orders triggered');
      // Orders refresh logic will be handled by the app
      break;
    case 'refresh_profile':
      logger.i('Action: Refresh profile triggered');
      // Profile refresh logic will be handled by the app
      break;
    case 'custom_action':
      logger.i('Action: Custom action triggered with data: $data');
      // Custom action handling
      break;
    case 'logout':
      logger.i('Action: Logout triggered');
      await LogoutStorage.clearForLogout();
      logger.i('Storage cleared in background (language & onboarding kept)');
      break;
    case 'announcement':
      logger.i('Action: Announcement — saving to local, no notification');
      await AnnouncementStorage.addPending(data);
      break;
    default:
      logger.w('Unknown action: $action');
  }
}


class FirebaseMessagingService {
  final ApiClient _apiClient;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SecureStorage _secureStorage = SecureStorage();
  final Logger _logger = Logger();

  FirebaseMessagingService(this._apiClient);

  /// Ilova butunlay yopiq holatda push orqali ochilgan bo'lsa, shu yerda
  /// saqlanadi. `initialize()` runApp()dan OLDIN chaqirilgani uchun,
  /// onNotificationTap streamiga hali hech kim obuna bo'lmagan bo'lishi
  /// mumkin — main.dart o'zining listenerini ulagach buni tekshirib olishi
  /// kerak (keyin bu yerni null qilib qo'yadi, ikki marta ishlov berilmasin).
  RemoteMessage? pendingInitialMessage;

  /// SecureStorage key: oxirgi marta backendga muvaffaqiyatli ro'yxatdan
  /// o'tkazilgan FCM token (takroriy so'rovlarni oldini olish uchun).
  static const _kSyncedTokenKey = 'fcm_token_synced';

  // Stream controller for notification taps
  final StreamController<RemoteMessage> _notificationTapController =
      StreamController<RemoteMessage>.broadcast();

  // Stream controller for actions (logout, etc.)
  final StreamController<String> _actionController =
      StreamController<String>.broadcast();

  // Data-only announcement: dialog ko'rsatish (foreground), notification chiqmaydi
  final StreamController<RemoteMessage> _announcementDialogController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onNotificationTap =>
      _notificationTapController.stream;
  
  Stream<String> get onAction => _actionController.stream;

  /// Foreground da announcement kelganda: dialog orqali ko'rsatish (notification emas).
  Stream<RemoteMessage> get onAnnouncementDialog =>
      _announcementDialogController.stream;

  /// Foreground da oddiy push (title/body) kelganda: Instagram uslubida banner ko'rsatish.
  Stream<RemoteMessage> get onForegroundNotificationDisplay =>
      _foregroundNotificationDisplayController.stream;

  final StreamController<RemoteMessage> _foregroundNotificationDisplayController =
      StreamController<RemoteMessage>.broadcast();

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      await _requestPermission();

      // Get FCM token
      final token = await getToken();
      if (token != null) {
        if (kDebugMode) _logger.i('FCM Token: $token');
        await _secureStorage.write(key: 'fcm_token', value: token);
        // App start bilan: agar foydalanuvchi allaqachon tizimga kirgan bo'lsa
        // (masalan ilova yopib-ochilgan), tokenni backend bilan sinxronlaymiz.
        // Kirmagan bo'lsa hech narsa qilinmaydi — login/set-password muvaffaqiyatli
        // bo'lganda alohida chaqiriladi.
        unawaited(registerDeviceToken());
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) _logger.i('FCM Token refreshed: $newToken');
        _secureStorage.write(key: 'fcm_token', value: newToken);
        unawaited(registerDeviceToken());
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state.
      // MUHIM: bu `initialize()` main()da runApp()dan OLDIN chaqiriladi,
      // shu paytda hali hech kim onNotificationTap streamiga obuna bo'lmagan
      // (broadcast stream — kech obuna bo'lganlar eski eventlarni ko'rmaydi).
      // Shuning uchun bu yerda ham streamga qo'shamiz (izchillik uchun), HAM
      // pendingInitialMessage sifatida saqlaymiz — main.dart o'z listenerini
      // ulagach buni tekshirib, qo'lda ishlov beradi.
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        pendingInitialMessage = initialMessage;
        _handleNotificationTap(initialMessage);
      }

      _logger.i('Firebase Messaging initialized successfully');
    } catch (e) {
      _logger.e('Error initializing Firebase Messaging: $e');
    }
  }

  /// Request notification permissions (especially for iOS and Android 13+)
  Future<void> _requestPermission() async {
    try {
      // For Android 13+ (API 33+), request runtime permission
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        
        if (status.isDenied) {
          _logger.i('Requesting Android notification permission...');
          final result = await Permission.notification.request();
          
          if (result.isGranted) {
            _logger.i('Android notification permission granted');
          } else if (result.isDenied) {
            _logger.w('Android notification permission denied');
          } else if (result.isPermanentlyDenied) {
            _logger.w('Android notification permission permanently denied');
          }
        } else if (status.isGranted) {
          _logger.i('Android notification permission already granted');
        }
      }
      
      // For iOS, request permission through Firebase Messaging
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        _logger.i('iOS notification permission status: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          _logger.i('iOS user granted permission');
        } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
          _logger.i('iOS user granted provisional permission');
        } else {
          _logger.w('iOS user declined or has not accepted permission');
        }
      }
    } catch (e) {
      _logger.e('Error requesting permission: $e');
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      // For iOS, you may need APNs token first
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          _logger.w('APNs token not available yet, retrying...');
          // Wait a bit and retry
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      final token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Foreground message received: ${message.messageId}');
    _logger.i('Title: ${message.notification?.title}');
    _logger.i('Body: ${message.notification?.body}');
    _logger.i('Data: ${message.data}');

    // Check if it's a silent notification (data-only)
    if (message.notification == null || 
        (message.notification?.title == null && message.notification?.body == null)) {
      _logger.i('Silent notification detected in foreground');
      final action = message.data['action']?.toString();
      if (action == 'announcement') {
        _logger.i('Announcement: showing in-app dialog');
        _announcementDialogController.add(message);
        return;
      }
      _handleBackgroundDataAction(message.data);
      return;
    }

    // Foreground: Instagram uslubida in-app banner ko'rsatish (tray notification emas)
    _foregroundNotificationDisplayController.add(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    _logger.i('Data: ${message.data}');

    // Emit to stream for navigation
    _notificationTapController.add(message);
  }

  /// Handle background data actions (for silent notifications)
  Future<void> _handleBackgroundDataAction(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      _logger.w('No data in silent notification');
      return;
    }

    final action = data['action'];
    _logger.i('Executing action: $action');

    switch (action) {
      case 'refresh_cart':
        _logger.i('Action: Refresh cart triggered');
        // Emit special event for cart refresh
        // You can modify this to trigger specific cubits/blocs
        break;
      case 'refresh_orders':
        _logger.i('Action: Refresh orders triggered');
        // Emit special event for orders refresh
        break;
      case 'refresh_profile':
        _logger.i('Action: Refresh profile triggered');
        // Emit special event for profile refresh
        break;
      case 'logout':
        _logger.i('Action: Logout triggered in foreground');
        await LogoutStorage.clearForLogout();
        _actionController.add('logout');
        break;
      case 'custom_action':
        _logger.i('Action: Custom action triggered with data: $data');
        // Handle custom actions based on additional data
        final customData = data['custom_data'];
        _logger.i('Custom data: $customData');
        break;
      default:
        _logger.w('Unknown action: $action');
    }
  }

  /// Check if notification permission is granted
  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return false;
  }

  /// Request notification permission (can be called from UI)
  Future<bool> requestNotificationPermission() async {
    await _requestPermission();
    return await isPermissionGranted();
  }

  /// FCM tokenni backendga (yangi DeviceToken tizimi) ro'yxatdan o'tkazadi.
  ///
  /// Faqat foydalanuvchi tizimga kirgan bo'lsa (accessToken mavjud bo'lsa)
  /// so'rov yuboradi. Token o'zgarmagan bo'lsa (oxirgi muvaffaqiyatli
  /// sinxronlash bilan bir xil) qayta so'rov yubormaydi. Xatolik ilovani
  /// yiqitmasligi kerak — shuning uchun hech qanday exception tashlanmaydi.
  Future<void> registerDeviceToken() async {
    try {
      final accessToken = await _secureStorage.read(key: 'accessToken');
      if (accessToken == null || accessToken.isEmpty) {
        // Hali autentifikatsiya qilinmagan — keyinroq login/refresh paytida
        // qayta chaqiriladi.
        return;
      }

      final fcmToken = await _secureStorage.read(key: 'fcm_token') ?? await getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        _logger.w('registerDeviceToken: FCM token hali mavjud emas');
        return;
      }

      final alreadySynced = await _secureStorage.read(key: _kSyncedTokenKey);
      if (alreadySynced == fcmToken) {
        return; // Backend allaqachon shu tokenni bilади — keraksiz so'rov yubormaymiz
      }

      final response = await _apiClient.post(
        MainUrls.deviceTokenRegister,
        body: {
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );

      if (response.isSuccess) {
        await _secureStorage.write(key: _kSyncedTokenKey, value: fcmToken);
        _logger.i('Device token backendga ro\'yxatdan o\'tkazildi');
      } else {
        _logger.w('Device token ro\'yxatdan o\'tkazishda xatolik: ${response.response}');
      }
    } catch (e) {
      // Token ro'yxatdan o'tmasa ham ilova ishlashda davom etishi kerak.
      _logger.e('registerDeviceToken xatosi: $e');
    }
  }

  /// Joriy qurilma tokenini backendda faolsizlantiradi (logout paytida
  /// chaqiriladi). Boshqa qurilmalarga (masalan foydalanuvchining planshetiga)
  /// ta'sir qilmaydi — faqat shu qurilmaning tokeni yuboriladi.
  Future<void> unregisterDeviceToken() async {
    try {
      final fcmToken = await _secureStorage.read(key: 'fcm_token');
      if (fcmToken == null || fcmToken.isEmpty) return;

      final accessToken = await _secureStorage.read(key: 'accessToken');
      if (accessToken == null || accessToken.isEmpty) return;

      await _apiClient.delete(
        MainUrls.deviceTokenRemove,
        body: {'token': fcmToken},
      );
      await _secureStorage.write(key: _kSyncedTokenKey, value: '');
    } catch (e) {
      // Logout jarayoni token o'chirilmasa ham davom etishi kerak.
      _logger.e('unregisterDeviceToken xatosi: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
    _actionController.close();
    _announcementDialogController.close();
    _foregroundNotificationDisplayController.close();
  }
}
