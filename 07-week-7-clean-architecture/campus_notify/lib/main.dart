import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'providers/auth_provider.dart';
import 'services/push_service.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, this.enablePush = false});

  final bool enablePush;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter router;
  PushService? _pushService;

  @override
  void initState() {
    super.initState();

    router = GoRouter(
      redirect: (context, state) {
        final loggedIn = ref.read(authStateProvider).value ?? false;

        final goingLogin = state.matchedLocation == loginRoute;

        if (!loggedIn && !goingLogin) return loginRoute;

        if (loggedIn && goingLogin) return homeRoute;

        return null;
      },
      routes: [
        GoRoute(path: loginRoute, builder: (_, _) => const LoginPage()),
        GoRoute(path: homeRoute, builder: (_, _) => const HomePage()),
        GoRoute(
          path: announcementRoute,
          builder: (_, state) {
            return AnnouncementPage(id: state.pathParameters['id'] ?? '');
          },
        ),
      ],
    );

    if (widget.enablePush) {
      // _pushService = PushService(onRouteRequested: (route) => router.go(route));
      // unawaited(_pushService!.initialize());
    }
  }

  @override
  void dispose() {
    final pushService = _pushService;
    if (pushService != null) {
      unawaited(pushService.dispose());
    }
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      router.refresh();
    });

    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}
