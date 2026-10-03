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

final container = ProviderContainer();
late final GoRouter appRouter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  final loggedIn = await container.read(authStateProvider.future);

  debugPrint('=== APP START ===');
  debugPrint('LOGIN AWAL: $loggedIn');

  appRouter = GoRouter(
    initialLocation: loggedIn ? '/' : '/login',

    redirect: (context, state) {
      final isLoggedIn =
          container.read(authStateProvider).value ?? loggedIn;

      final currentRoute = state.matchedLocation;
      final goingLogin = currentRoute == '/login';

      debugPrint('==============================');
      debugPrint('ROUTE SEKARANG: $currentRoute');
      debugPrint('LOGIN STATUS: $isLoggedIn');
      debugPrint('==============================');

      // Kalau belum login, arahkan ke login.
      if (!isLoggedIn && !goingLogin) {
        debugPrint('REDIRECT → /login');
        return '/login';
      }

      // Kalau sudah login tetapi mencoba membuka login,
      // arahkan ke Home.
      if (isLoggedIn && goingLogin) {
        debugPrint('REDIRECT → /');
        return '/';
      }

      // Tidak ada redirect.
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomePage();
        },
      ),

      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';

          debugPrint('=== ANNOUNCEMENT PAGE ===');
          debugPrint('ID PENGUMUMAN: $id');

          return AnnouncementPage(
            id: id,
          );
        },
      ),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFCM();
    });
  }

  Future<void> _initializeFCM() async {
    final pushService = PushService(
      onNavigate: (route) {
        debugPrint('================================');
        debugPrint('NAVIGASI DARI NOTIFICATION');
        debugPrint('ROUTE: $route');
        debugPrint('================================');

        appRouter.go(route);
      },
    );

    await pushService.initialize(
      onToken: (token) async {
        final preview = token.length > 12
            ? '${token.substring(0, 12)}...'
            : token;

        debugPrint('FCM Token: $preview');
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