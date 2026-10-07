import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/api_client.dart';
import 'data/auth_controller.dart';
import 'data/auth_repository.dart';
import 'data/token_store.dart';
import 'firebase_options.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStore = TokenStore();
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  final authRepository = AuthRepository(
    dio: apiBaseUrl.isEmpty ? null : Dio(BaseOptions(baseUrl: apiBaseUrl)),
  );
  final auth = AuthController(
    tokenStore: tokenStore,
    repository: authRepository,
  );
  await auth.initialize();

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
  }

  final tokenPreview = ValueNotifier<String?>(null);
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.isReady) return AppRoutes.login;
      final goingToLogin = state.matchedLocation == AppRoutes.login;
      if (!auth.isAuthenticated && !goingToLogin) {
        final destination = state.uri.toString();
        return Uri(
          path: AppRoutes.login,
          queryParameters: destination == AppRoutes.login
              ? null
              : {'redirect': destination},
        ).toString();
      }
      if (auth.isAuthenticated && goingToLogin) {
        return state.uri.queryParameters['redirect'] ?? AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(
          auth: auth,
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomePage(
          auth: auth,
          tokenPreview: tokenPreview,
        ),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) =>
            AnnouncementPage(id: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.error}')),
    ),
  );

  runApp(CampusNotifyApp(router: router));

  if (firebaseReady) {
    final apiClient = buildApiClient(tokenStore: tokenStore, auth: auth);
    final pushService = PushService(
      onNavigate: router.go,
      onError: debugPrint,
    );
    unawaited(
      pushService
          .initialize(
            onToken: (token) async {
              tokenPreview.value = _maskToken(token);
              if (apiClient == null) {
                debugPrint(
                  'FCM token is available but was not sent: '
                  'configure API_BASE_URL to enable POST /devices.',
                );
                return;
              }
              await apiClient.post<void>('/devices', data: {'token': token});
              debugPrint('FCM device token registered with backend.');
            },
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('Push initialization failed: $error\n$stackTrace');
          }),
    );
  }
}

String _maskToken(String token) {
  if (token.length <= 12) return '••••••••';
  return '${token.substring(0, 8)}…${token.substring(token.length - 4)}';
}

class CampusNotifyApp extends StatelessWidget {
  const CampusNotifyApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142B4A);
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2764C5),
          surface: const Color(0xFFF5F7FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FB),
          foregroundColor: navy,
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
