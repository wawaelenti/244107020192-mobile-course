import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              // Proses logout
              await ref
                  .read(authStateProvider.notifier)
                  .logout();

              if (!context.mounted) return;

              // Kembali ke halaman login
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
            ),

            SizedBox(height: 16),

            Text(
              'Login berhasil!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Anda sudah masuk ke aplikasi.',
            ),

            SizedBox(height: 24),

            Text(
              'Access token dan refresh token\n'
              'tersimpan menggunakan Secure Storage.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

