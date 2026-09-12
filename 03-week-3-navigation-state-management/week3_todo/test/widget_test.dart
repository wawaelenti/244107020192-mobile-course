import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week3_todo/main.dart';

void main() {
  testWidgets('StatsPage menampilkan loading saat mengambil data', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Proses pengambilan data masih berlangsung.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Menyelesaikan delay 2 detik agar tidak ada timer yang tertinggal.
    await tester.pump(const Duration(seconds: 2));
  });
}
