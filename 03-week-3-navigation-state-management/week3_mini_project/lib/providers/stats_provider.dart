import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Statistic {
  const Statistic(this.label, this.value);

  final String label;
  final int value;
}

class StatsNotifier extends AsyncNotifier<List<Statistic>> {
  StatsNotifier({int Function(int max)? nextInt})
      : _nextInt = nextInt ?? Random().nextInt;

  final int Function(int max) _nextInt;

  @override
  Future<List<Statistic>> build() async {
    return _fetchStats();
  }

  Future<List<Statistic>> _fetchStats() async {
    await Future<void>.delayed(
      const Duration(seconds: 2),
    );

    if (_nextInt(100) < 30) {
      throw Exception(
        'Gagal mengambil data statistik',
      );
    }

    return const [
      Statistic('Pengguna aktif', 1280),
      Statistic('Pesanan selesai', 864),
      Statistic('Pendapatan bulan ini', 45200),
    ];
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<Statistic>>(
  StatsNotifier.new,
);