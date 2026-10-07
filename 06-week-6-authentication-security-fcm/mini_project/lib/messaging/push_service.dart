import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'route_parser.dart';

class PushService {
  PushService({
    required this.onNavigate,
    required this.onError,
  });

  final void Function(String route) onNavigate;
  final void Function(String message) onError;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  }) async {
    await requestPermission();
    await _initializeLocalNotifications();
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => unawaited(_registerToken(token, onToken)),
      onError: (Object error) => onError('Gagal memperbarui token FCM: $error'),
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _openMessage(initialMessage);

    const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');
    if (kIsWeb && vapidKey.isEmpty) {
      throw StateError('FCM_VAPID_KEY wajib diatur untuk FCM di web.');
    }
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? vapidKey : null,
    );
    if (token != null) await _registerToken(token, onToken);

    if (!kIsWeb) {
      await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
    }
  }

  Future<AuthorizationStatus> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus;
  }

  Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null) onNavigate(route);
      },
    );
    const channel = AndroidNotificationChannel(
      'pengumuman',
      'Pengumuman Kampus',
      description: 'Notifikasi pengumuman kampus',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && payload != null) {
      onNavigate(payload);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final route = notificationRouteFromData(message.data);
    if (route == null) {
      onError('Notifikasi diabaikan: data id/route pengumuman tidak valid.');
      return;
    }
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
      title: message.notification?.title ?? 'Pengumuman kampus',
      body: message.notification?.body ?? 'Buka untuk melihat detail.',
      notificationDetails: details,
      payload: route,
    );
  }

  void _openMessage(RemoteMessage message) {
    final route = notificationRouteFromData(message.data);
    if (route == null) {
      onError('Notifikasi diabaikan: data id/route pengumuman tidak valid.');
      return;
    }
    onNavigate(route);
  }

  Future<void> _registerToken(
    String token,
    Future<void> Function(String token) onToken,
  ) async {
    try {
      await onToken(token);
    } on DioException catch (error) {
      onError(
        'Gagal mengirim token perangkat '
        '(HTTP ${error.response?.statusCode ?? 'koneksi'}).',
      );
      debugPrint('FCM device registration failed: $error');
    } catch (error, stackTrace) {
      onError('Gagal mengirim token perangkat: $error');
      debugPrint('FCM device registration failed: $error\n$stackTrace');
    }
  }
}
