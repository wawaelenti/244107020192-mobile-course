import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// ConsumerWidget memberi akses ke state Riverpod melalui WidgetRef.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch membuat UI dibangun ulang setiap status provider berubah.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: statsAsync.when(
        // Menampilkan spinner selama proses pengambilan data berlangsung.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Menampilkan pesan error dan memulai ulang provider saat retry ditekan.
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat statistik: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        // Menampilkan tiga statistik ketika pengambilan data berhasil.
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final statistic = stats[index];
            return ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(statistic.label),
              trailing: Text(statistic.value.toString()),
            );
          },
        ),
      ),
    );
  }
}
