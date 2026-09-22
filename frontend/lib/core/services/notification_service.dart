import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

/// Top-level background message handler required by FirebaseMessaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint(
      '[NOTIFICATION BG] 📩 Push received in background: ${message.messageId} | ${message.notification?.title ?? message.data['title']}',
    );
  } catch (e) {
    debugPrint('[NOTIFICATION BG ERROR] $e');
  }
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] is Map ? json['data'] as Map<String, dynamic> : {},
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<AppNotificationItem>> notificationsNotifier =
      ValueNotifier<List<AppNotificationItem>>([]);

  Timer? _pollingTimer;
  bool _isInitialized = false;
  String? _cachedFcmToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static const AndroidNotificationChannel _criticalChannel =
      AndroidNotificationChannel(
    'finance_alerts_channel',
    'Finance Critical Alerts',
    description:
        'Important real-time alerts for payments, collections, disbursements, and overdue loans',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize Firebase Messaging & Local Notifications (Heads-Up Banner)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();
      debugPrint('[NOTIFICATION] 🔥 Firebase Core initialized successfully');

      // 2. Set Background Message Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Initialize Local Notifications Plugin (for Foreground Banners)
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 4. Create Android High Priority Notification Channel
      final androidPlatform = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(_criticalChannel);
        await androidPlatform.requestNotificationsPermission();
      }

      // 5. Request User Notification Permissions (Android 13+ & iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '[NOTIFICATION] 🔔 Permission status: ${settings.authorizationStatus}',
      );

      // 6. Set Foreground presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 7. Foreground message listener -> Show Local Heads-Up Notification Banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[NOTIFICATION FOREGROUND] 📲 Message received: ${message.notification?.title ?? message.data['title']}',
        );
        _handleForegroundMessage(message);
      });

      // 8. Background message opened app listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '[NOTIFICATION TAP] 👆 App opened from notification: ${message.data}',
        );
        fetchNotifications();
      });

      // 9. Check if app was opened from terminated state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[NOTIFICATION COLD START] 🚀 App launched from notification: ${initialMessage.data}',
        );
        fetchNotifications();
      }

      // 10. Listen for FCM Token Refresh
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[NOTIFICATION] 🔄 FCM Token refreshed: $newToken');
        registerDeviceToken(customToken: newToken);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NOTIFICATION INIT ERROR] $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NOTIFICATION LOCAL TAP] Payload: ${response.payload}');
    fetchNotifications();
  }

  /// Show heads-up banner when notification arrives while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Finance Alert';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';

    final androidDetails = AndroidNotificationDetails(
      _criticalChannel.id,
      _criticalChannel.name,
      channelDescription: _criticalChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    // Refresh in-app notifications state
    fetchNotifications();
  }

  void startPeriodicSync() {
    _pollingTimer?.cancel();
    fetchNotifications();
    // Background polling fallback every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications();
    });
  }

  void stopPeriodicSync() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Register real FCM Token to the Backend
  Future<void> registerDeviceToken({String? customToken}) async {
    try {
      String? token = customToken ?? _cachedFcmToken;

      if (token == null && !kIsWeb) {
        try {
          token = await FirebaseMessaging.instance.getToken();
          _cachedFcmToken = token;
        } catch (fcmErr) {
          debugPrint('[NOTIFICATION] ⚠️ Could not get real FCM token: $fcmErr');
        }
      }

      // Fallback identifier if FCM is not available (e.g. during offline/emulator)
      token ??= 'DEV_TOKEN_${DateTime.now().millisecondsSinceEpoch}';

      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'unknown';

      await _apiClient.post(
        ApiEndpoints.deviceToken,
        data: {
          'fcmToken': token,
          'platform': platform,
          'appVersion': '1.0.0',
        },
      );
      debugPrint(
        '[NOTIFICATION] 📲 FCM Device Token registered successfully: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
      );
    } catch (e) {
      debugPrint('[NOTIFICATION WARN] Token registration error: $e');
    }
  }

  /// Unregister FCM token on user logout
  Future<void> unregisterDeviceToken() async {
    try {
      await _apiClient.delete(ApiEndpoints.deviceToken);
      stopPeriodicSync();
      unreadCountNotifier.value = 0;
      notificationsNotifier.value = [];
      debugPrint('[NOTIFICATION] 📴 Device token unregistered');
    } catch (e) {
      debugPrint('[NOTIFICATION WARN] Token unregister error: $e');
    }
  }

  Future<List<AppNotificationItem>> fetchNotifications() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.notifications);
      if (res.success && res.data is Map) {
        final map = res.data as Map<String, dynamic>;
        final list = map['notifications'] as List<dynamic>? ?? [];
        final count = (map['unreadCount'] as num?)?.toInt() ?? 0;

        final items = list
            .map((json) =>
                AppNotificationItem.fromJson(json as Map<String, dynamic>))
            .toList();
        notificationsNotifier.value = items;
        unreadCountNotifier.value = count;
        return items;
      }
    } catch (e) {
      debugPrint('[NOTIFICATION ERROR] $e');
    }
    return notificationsNotifier.value;
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final res = await _apiClient
          .put('${ApiEndpoints.notifications}/$notificationId/read');
      if (res.success) {
        fetchNotifications();
        return true;
      }
    } catch (e) {
      debugPrint('[NOTIFICATION ERROR] $e');
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    try {
      final res = await _apiClient.put('${ApiEndpoints.notifications}/all/read');
      if (res.success) {
        fetchNotifications();
        return true;
      }
    } catch (e) {
      debugPrint('[NOTIFICATION ERROR] $e');
    }
    return false;
  }

  Future<bool> clearAll() async {
    try {
      final res =
          await _apiClient.delete(ApiEndpoints.notificationsClearAll);
      if (res.success) {
        unreadCountNotifier.value = 0;
        notificationsNotifier.value = [];
        return true;
      }
    } catch (e) {
      debugPrint('[NOTIFICATION ERROR] $e');
    }
    return false;
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    stopPeriodicSync();
  }
}
