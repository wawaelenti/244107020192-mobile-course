import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week3_mini_project/providers/stats_provider.dart';

void main() {
  test(
    'notifier mengembalikan tiga statistik setelah delay',
    () async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(
              nextInt: (_) => 99,
            ),
          ),
        ],
      );

      addTearDown(container.dispose);

      final result =
          await container.read(statsProvider.future);

      expect(result, hasLength(3));
      expect(
        result.first.label,
        'Pengguna aktif',
      );
    },
  );

  test(
    'notifier menghasilkan error saat simulasi gagal',
    () async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(
              nextInt: (_) => 0,
            ),
          ),
        ],
      );

      addTearDown(container.dispose);

      container.read(statsProvider);

      await Future<void>.delayed(
        const Duration(seconds: 3),
      );

      final state = container.read(statsProvider);

      expect(
        state,
        isA<AsyncError<List<Statistic>>>(),
      );
    },
  );
}