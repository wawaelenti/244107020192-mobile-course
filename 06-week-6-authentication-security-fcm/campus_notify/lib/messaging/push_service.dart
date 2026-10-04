import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'notification_route.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Firebase invokes this top-level handler in a background isolate.
/// It must not access widgets, BuildContext, or app navigation state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushService {
  PushService({required this.onNavigate});

  /// The router callback is context-free and can be called from message taps.
  final void Function(String route) onNavigate;

  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  }) async {
    await requestNotificationPermission();
    await initLocalNotifications();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
    }

    listenForeground();
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    await handleTerminated();
    await initFcmToken(onToken: onToken);

    if (!kIsWeb) {
      await subscribeToCampusTopic();
    }
  }

  Future<bool> requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        _navigateToRoute(response.payload);
      },
    );

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _navigateToRoute(launchDetails?.notificationResponse?.payload);
    }

    const channel = AndroidNotificationChannel(
      'pengumuman',
      'Pengumuman Kampus',
      description: 'Notifikasi pengumuman kampus',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> initFcmToken({
    required Future<void> Function(String token) onToken,
  }) async {
    const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');
    if (kIsWeb && vapidKey.isEmpty) {
      throw StateError(
        'FCM_VAPID_KEY must be supplied with --dart-define on web.',
      );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) => unawaited(_registerToken(newToken, onToken)),
    );

    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? vapidKey : null,
    );
    if (token != null) {
      await _registerToken(token, onToken);
    }
  }

  void listenForeground() {
    FirebaseMessaging.onMessage.listen((message) async {
      final route = notificationRouteFromData(message.data);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'pengumuman',
          'Pengumuman Kampus',
          channelDescription: 'Notifikasi pengumuman kampus',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman',
        body: message.notification?.body ?? '',
        notificationDetails: details,
        payload: route,
      );
    });
  }

  Future<void> _registerToken(
    String token,
    Future<void> Function(String token) onToken,
  ) async {
    try {
      await onToken(token);
    } on DioException catch (error) {
      debugPrint(
        'FCM token registration failed '
        '(HTTP ${error.response?.statusCode ?? 'network error'}).',
      );
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    _navigateToRoute(notificationRouteFromData(message.data));
  }

  void _navigateToRoute(String? route) {
    if (route != null) {
      onNavigate(route);
    }
  }

  Future<void> handleTerminated() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> subscribeToCampusTopic() async {
    if (kIsWeb) {
      debugPrint('FCM topic subscription is not supported on web.');
      return;
    }

    await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  }

  Future<void> unsubscribeFromCampusTopic() async {
    if (kIsWeb) {
      debugPrint('FCM topic unsubscription is not supported on web.');
      return;
    }

    await FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
  }
}
