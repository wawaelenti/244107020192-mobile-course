import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

// ProviderContainer digunakan untuk membaca state autentikasi
// dari authStateProvider di dalam GoRouter.
final container = ProviderContainer();

void main() {
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      // Mengecek status login sebelum membuka halaman
      redirect: (context, state) {
        // Membaca status login dari authStateProvider
        final loggedIn =
            container.read(authStateProvider).value ?? false;

        // Mengecek apakah user sedang berada di halaman login
        final goingLogin =
            state.matchedLocation == '/login';

        // Jika belum login dan mencoba membuka halaman lain,
        // arahkan user ke halaman login.
        if (!loggedIn && !goingLogin) {
          return '/login';
        }

        // Jika sudah login tetapi masih berada di halaman login,
        // arahkan user ke halaman utama.
        if (loggedIn && goingLogin) {
          return '/';
        }

        // Tidak perlu melakukan redirect.
        return null;
      },

      routes: [
        // Route halaman login
        GoRoute(
          path: '/login',
          builder: (_, _) => const LoginPage(),
        ),

        // Route halaman utama
        GoRoute(
          path: '/',
          builder: (_, _) => const HomePage(),
        ),

        // Route detail pengumuman
        // Contoh: /pengumuman/123
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

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Campus Notify',
      routerConfig: router,
    );
  }
}

