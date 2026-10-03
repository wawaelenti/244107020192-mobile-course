import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

// Satu ProviderContainer digunakan oleh aplikasi.
final container = ProviderContainer();

// Router dibuat sebagai variable global agar bisa digunakan
// oleh PushService ketika notifikasi diklik.
late final GoRouter appRouter;

Future<void> main() async {
  // Memastikan binding Flutter sudah siap.
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Mendaftarkan handler untuk pesan ketika aplikasi berada
  // di background.
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Mengecek apakah user sudah login sebelum aplikasi dibuka.
  final loggedIn = await container
      .read(authStateProvider.future);

  // Membuat router aplikasi.
  appRouter = GoRouter(
    initialLocation: loggedIn ? '/' : '/login',

    redirect: (context, state) {
      // Membaca status login.
      final isLoggedIn =
          container.read(authStateProvider).value ?? loggedIn;

      // Mengecek apakah sedang membuka halaman login.
      final goingLogin =
          state.matchedLocation == '/login';

      // Belum login tidak boleh membuka halaman lain.
      if (!isLoggedIn && !goingLogin) {
        return '/login';
      }

      // Sudah login tidak perlu kembali ke login.
      if (isLoggedIn && goingLogin) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),

      GoRoute(
        path: '/',
        builder: (_, _) => const HomePage(),
      ),

      GoRoute(
        path: '/pengumuman/:id',
        builder: (_, state) {
          return AnnouncementPage(
            id: state.pathParameters['id'] ?? '',
          );
        },
      ),
    ],
  );

  // Jalankan aplikasi.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Menjalankan inisialisasi FCM setelah widget pertama
    // selesai dibuat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFCM();
    });
  }

  Future<void> _initializeFCM() async {
    final pushService = PushService(
      onNavigate: (route) {
        // Jika notifikasi mempunyai route,
        // arahkan ke route tersebut.
        appRouter.go(route);
      },
    );

    await pushService.initialize(
      onToken: (token) async {
        // Untuk praktikum, token hanya ditampilkan sebagian.
        final preview = token.length > 12
            ? '${token.substring(0, 12)}...'
            : token;

        debugPrint(
          'FCM Token: $preview',
        );

        // Nanti bagian ini bisa diganti dengan:
        // await dio.post('/devices', data: {
        //   'fcm_token': token,
        //   'platform': 'android',
        // });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Campus Notify',
      routerConfig: appRouter,
    );
  }
}

