import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Plugin untuk menampilkan local notification.
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Menyimpan deep link sementara dari notifikasi.
String? pendingDeepLink;

/// Handler untuk pesan FCM ketika aplikasi berada di background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Inisialisasi Firebase pada isolate background.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('==============================');
  debugPrint('FCM BACKGROUND MESSAGE');
  debugPrint('Message ID : ${message.messageId}');
  debugPrint('Title      : ${message.notification?.title}');
  debugPrint('Body       : ${message.notification?.body}');
  debugPrint('Data       : ${message.data}');

  final route = message.data['route'];
  final id = message.data['id'];

  debugPrint('Route      : $route');
  debugPrint('ID         : $id');
  debugPrint('==============================');
}

/// Service untuk menangani Firebase Cloud Messaging.
class PushService {
  PushService({
    required this.onNavigate,
  });

  /// Callback untuk melakukan navigasi.
  final void Function(String route) onNavigate;

  /// Menjalankan seluruh proses inisialisasi FCM.
  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  }) async {
    // Meminta izin notifikasi.
    await requestNotificationPermission();

    // Menyiapkan local notification.
    await initLocalNotifications();

    // Mendengarkan pesan ketika aplikasi sedang terbuka.
    listenForeground();

    // Menangani klik notifikasi saat aplikasi berada
    // dalam kondisi background.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        debugPrint('==============================');
        debugPrint('FCM NOTIFICATION CLICKED');
        debugPrint('Message ID : ${message.messageId}');
        debugPrint('Data       : ${message.data}');

        final route = message.data['route'] ?? '/';
        final id = message.data['id'] ?? '';

        debugPrint('Route      : $route');
        debugPrint('ID         : $id');
        debugPrint('==============================');

        onNavigate(route);
      },
    );

    // Menangani notifikasi ketika aplikasi sebelumnya
    // dalam kondisi terminated.
    await handleTerminated();

    // Mengambil FCM token dan mendengarkan perubahan token.
    await initFcmToken(
      onToken: onToken,
    );
  }

  /// Meminta izin untuk menampilkan notifikasi.
  Future<bool> requestNotificationPermission() async {
    final settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    final authorized =
        settings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            settings.authorizationStatus ==
                AuthorizationStatus.provisional;

    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );

    return authorized;
  }

  /// Menginisialisasi local notification.
  Future<void> initLocalNotifications() async {
    // Konfigurasi Android.
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Konfigurasi iOS.
    const iosSettings = DarwinInitializationSettings();

    // Inisialisasi plugin.
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (
        NotificationResponse response,
      ) {
        debugPrint('==============================');
        debugPrint('LOCAL NOTIFICATION CLICKED');
        debugPrint('Payload: ${response.payload}');
        debugPrint('==============================');

        // Payload berisi route yang akan dibuka.
        final route = response.payload;

        if (route != null && route.isNotEmpty) {
          pendingDeepLink = route;

          // Navigasi ke halaman yang sesuai.
          onNavigate(route);
        }
      },
    );

    // Notification channel untuk Android.
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
  }

  /// Mengambil FCM token dan memantau perubahan token.
  Future<void> initFcmToken({
    required Future<void> Function(String token) onToken,
  }) async {
    // Mengambil token FCM saat ini.
    final token = await FirebaseMessaging.instance.getToken(
      // Pertahankan VAPID key milik project kamu yang sekarang.
      vapidKey:
          'BDDH2Onsdj5lcB7ZZszSg6wuIrxojYHhNoGr4_WvoyyOllzY6hUYnhd5gPHJS8x6kzIVnonKMB8H0tfTIZwcTGw',
    );

    // Menampilkan FCM token di debug console.
    debugPrint('FCM Token: $token');

    if (token != null) {
      await onToken(token);
    }

    // Memantau perubahan token.
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        debugPrint(
          'FCM Token diperbarui: $newToken',
        );

        await onToken(newToken);
      },
    );

    // Topic subscription client-side tidak dijalankan di Web.
    // Untuk Android/iOS, topic dapat digunakan langsung.
    if (!kIsWeb) {
      await FirebaseMessaging.instance.subscribeToTopic(
        'pengumuman-kampus',
      );

      debugPrint(
        'Berhasil subscribe ke topic: pengumuman-kampus',
      );
    } else {
      debugPrint(
        'Web: topic subscription dilewati.',
      );
    }
  }

  /// Mendengarkan pesan ketika aplikasi sedang foreground.
  void listenForeground() {
    FirebaseMessaging.onMessage.listen(
      (message) async {
        debugPrint('==============================');
        debugPrint('FCM FOREGROUND MESSAGE');
        debugPrint('Message ID : ${message.messageId}');
        debugPrint(
          'Title      : ${message.notification?.title}',
        );
        debugPrint(
          'Body       : ${message.notification?.body}',
        );
        debugPrint('Data       : ${message.data}');

        // Mengambil route dari data FCM.
        final route = message.data['route'] ?? '/';

        // Mengambil ID pengumuman dari data FCM.
        final id = message.data['id'] ?? '';

        debugPrint('Route      : $route');
        debugPrint('ID         : $id');
        debugPrint('==============================');

        // Detail notifikasi Android.
        const androidDetails = AndroidNotificationDetails(
          'pengumuman',
          'Pengumuman Kampus',
          channelDescription:
              'Notifikasi pengumuman kampus',
          importance: Importance.high,
          priority: Priority.high,
        );

        // Detail notifikasi.
        const notificationDetails = NotificationDetails(
          android: androidDetails,
        );

        // Mengambil data notification.
        final notification = message.notification;

        // Menampilkan local notification.
        await _localNotifications.show(
          id: message.hashCode,
          title: notification?.title ?? 'Pengumuman',
          body: notification?.body ?? '',
          notificationDetails: notificationDetails,
          payload: route,
        );
      },
    );
  }

  /// Menangani notifikasi saat aplikasi dibuka dari kondisi
  /// terminated.
  Future<void> handleTerminated() async {
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('==============================');
      debugPrint('FCM OPENED FROM TERMINATED');
      debugPrint(
        'Message ID : ${initialMessage.messageId}',
      );
      debugPrint(
        'Title      : ${initialMessage.notification?.title}',
      );
      debugPrint(
        'Body       : ${initialMessage.notification?.body}',
      );
      debugPrint(
        'Data       : ${initialMessage.data}',
      );

      final route =
          initialMessage.data['route'] ?? '/';

      final id =
          initialMessage.data['id'] ?? '';

      debugPrint('Route      : $route');
      debugPrint('ID         : $id');
      debugPrint('==============================');

      // Menunggu sebentar sampai aplikasi siap melakukan navigasi.
      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          onNavigate(route);
        },
      );
    }

    // Menangani deep link yang masih tersimpan.
    if (pendingDeepLink != null) {
      final route = pendingDeepLink!;

      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          onNavigate(route);
        },
      );
    }
  }

  /// Subscribe ke topic pengumuman kampus.
  Future<void> subscribeToCampusTopic() async {
    if (kIsWeb) {
      debugPrint(
        'Web: subscribeToCampusTopic dilewati.',
      );
      return;
    }

    await FirebaseMessaging.instance.subscribeToTopic(
      'pengumuman-kampus',
    );

    debugPrint(
      'Subscribe topic berhasil: pengumuman-kampus',
    );
  }

  /// Unsubscribe dari topic pengumuman kampus.
  Future<void> unsubscribeFromCampusTopic() async {
    if (kIsWeb) {
      debugPrint(
        'Web: unsubscribeToCampusTopic dilewati.',
      );
      return;
    }

    await FirebaseMessaging.instance.unsubscribeFromTopic(
      'pengumuman-kampus',
    );

    debugPrint(
      'Unsubscribe topic berhasil: pengumuman-kampus',
    );
  }
}