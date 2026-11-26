import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login page displays the notification icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(_MemoryTokenStore())],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
  });
}

class _MemoryTokenStore extends TokenStore {
  @override
  Future<String?> readAccess() async => null;
}
