import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Menyimpan satu baris data statistik yang akan ditampilkan oleh halaman.
class Statistic {
  const Statistic(this.label, this.value);

  final String label;
  final int value;
}

// Mengelola status asynchronous untuk proses pengambilan statistik.
class StatsNotifier extends AsyncNotifier<List<Statistic>> {
  // Fungsi acak dapat diganti ketika test agar hasil test selalu deterministik.
  StatsNotifier({int Function(int max)? nextInt})
    : _nextInt = nextInt ?? Random().nextInt;

  final int Function(int max) _nextInt;

  // Riverpod menjalankan build saat provider pertama kali diamati.
  @override
  Future<List<Statistic>> build() => _fetchStats();

  // Mengambil data setelah jeda dan mensimulasikan kegagalan sebanyak 30%.
  Future<List<Statistic>> _fetchStats() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    if (_nextInt(100) < 30) {
      throw Exception('Gagal mengambil data statistik');
    }

    return const [
      Statistic('Pengguna aktif', 1280),
      Statistic('Pesanan selesai', 864),
      Statistic('Pendapatan bulan ini', 45200),
    ];
  }
}

// Provider tunggal yang menjadi sumber state untuk StatsPage.
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<Statistic>>(
  StatsNotifier.new,
);
