import '../routes.dart';
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

class PushService {
  PushService({
    required this.onRouteRequested,
    this.onTokenAvailable,
  });

  static const _channelId = 'campus_announcements';
  static const _channelName = 'Pengumuman kampus';

  final void Function(String route) onRouteRequested;
  final Future<void> Function(String token)? onTokenAvailable;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  bool _initialized = false;
  bool _initializing = false;

  Future<void> initialize() async {
    if (_initialized || _initializing) return;

    _initializing = true;

    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse:
            _handleLocalNotificationResponse,
      );

      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Notifikasi pengumuman kampus',
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      await requestPermission();

      if (Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
      }

      _tokenRefreshSubscription =
          _messaging.onTokenRefresh.listen((token) {
        unawaited(_notifyTokenAvailable(token));
      });

      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showForegroundNotification(message));
      });

      _messageOpenedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageNavigation,
      );

      await getToken();
      await subscribeToAnnouncements();

      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();

      if (launchDetails?.didNotificationLaunchApp ?? false) {
        _handleLocalNotificationResponse(
          launchDetails?.notificationResponse,
        );
      }

      final initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }

      _initialized = true;
    } catch (error, stackTrace) {
      await _cancelSubscriptions();
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _initializing = false;
    }
  }

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    final token = await _messaging.getToken();

    if (token != null) {
      await _notifyTokenAvailable(token);
    }

    return token;
  }

  Future<void> subscribeToAnnouncements() {
    return _messaging.subscribeToTopic('pengumuman-kampus');
  }

  Future<void> unsubscribeFromAnnouncements() {
    return _messaging.unsubscribeFromTopic('pengumuman-kampus');
  }

  Future<void> dispose() async {
    await _cancelSubscriptions();
    _initialized = false;
  }

  Future<void> _cancelSubscriptions() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();

    _tokenRefreshSubscription = null;
    _messageSubscription = null;
    _messageOpenedSubscription = null;
  }

  Future<void> _notifyTokenAvailable(String token) async {
    if (onTokenAvailable == null) return;

    try {
      await onTokenAvailable!(token);
    } catch (_) {
      debugPrint('Gagal memproses pembaruan token FCM.');
    }
  }

  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifikasi pengumuman kampus',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final route = message.data['route'];

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
      payload: route is String ? route : null,
    );
  }

  void _handleLocalNotificationResponse(
    NotificationResponse? response,
  ) {
    _navigateToRoute(response?.payload);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    _navigateToRoute(routeFromMessage(message.data));
  }

  void _navigateToRoute(Object? value) {
    if (value is! String ||
        !value.startsWith('/') ||
        value.startsWith('//') ||
        value.contains('\\')) {
      return;
    }

    onRouteRequested(value);
  }
}
