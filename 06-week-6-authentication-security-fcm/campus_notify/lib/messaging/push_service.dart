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

  // Menampilkan informasi sederhana pada debug console.
  debugPrint(
    'Pesan background diterima: ${message.messageId}',
  );
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
        final route = message.data['route'] ?? '/';
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

    // Berlangganan topic pengumuman kampus.
    await FirebaseMessaging.instance.subscribeToTopic(
      'pengumuman-kampus',
    );
  }

  /// Mendengarkan pesan ketika aplikasi sedang foreground.
  void listenForeground() {
    FirebaseMessaging.onMessage.listen(
      (message) async {
        // Mengambil route dari data FCM.
        final route = message.data['route'] ?? '/';

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
      final route =
          initialMessage.data['route'] ?? '/';

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
    await FirebaseMessaging.instance.subscribeToTopic(
      'pengumuman-kampus',
    );
  }

  /// Unsubscribe dari topic pengumuman kampus.
  Future<void> unsubscribeFromCampusTopic() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(
      'pengumuman-kampus',
    );
  }
}