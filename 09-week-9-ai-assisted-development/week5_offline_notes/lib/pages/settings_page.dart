import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';

final prefsRepositoryProvider = Provider(
  (ref) => PrefsRepository(),
);

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

// Provider untuk membaca waktu terakhir aplikasi dibuka
final lastOpenedProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(prefsRepositoryProvider);

  final lastOpened = await repo.getLastOpened();
  await repo.markOpenedNow();

  return lastOpened;
});

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(prefsRepositoryProvider)
          .setDarkMode(next);

      return next;
    });
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: darkMode.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Terjadi error: $error'),
        ),
        data: (isDarkMode) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text(
                  'Gunakan tema gelap pada aplikasi',
                ),
                value: isDarkMode,
                onChanged: (_) {
                  ref.read(darkModeProvider.notifier).toggle();
                },
              ),

              // Menampilkan waktu terakhir aplikasi dibuka
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Terakhir dibuka'),
                subtitle: lastOpened.when(
                  loading: () => const Text('Memuat...'),
                  error: (error, stackTrace) =>
                      Text('Terjadi error: $error'),
                  data: (value) => Text(
                    value ?? 'Belum ada data',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}