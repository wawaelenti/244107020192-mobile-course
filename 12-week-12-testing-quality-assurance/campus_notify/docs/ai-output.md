# Draf Awal PushService

## 💻 Kode Awal dari AI

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  // Handler berjalan tanpa BuildContext dan tidak melakukan navigasi.
}

class PushService {
  PushService({
    required this.onTokenAvailable,
    required this.onRouteRequested,
  });

  final Future<void> Function(String token) onTokenAvailable;
  final void Function(String route) onRouteRequested;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) {
          onRouteRequested(route);
        }
      },
    );

    await requestPermission();
    await getToken();

    _messaging.onTokenRefresh.listen(onTokenAvailable);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }
  }

  Future<NotificationSettings> requestPermission() {
    // iOS meminta izin melalui prompt sistem.
    // Android 13 ke atas memerlukan izin POST_NOTIFICATIONS saat runtime.
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await onTokenAvailable(token);
    }
    return token;
  }

  Future<void> subscribeToAnnouncements() {
    return _messaging.subscribeToTopic('pengumuman-kampus');
  }

  Future<void> unsubscribeFromAnnouncements() {
    return _messaging.unsubscribeFromTopic('pengumuman-kampus');
  }

  Future<void> _showForegroundNotification(
      RemoteMessage message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'campus_announcements',
        'Pengumuman kampus',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data['route'] as String?,
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && route.isNotEmpty) {
      onRouteRequested(route);
    }
  }
}
```