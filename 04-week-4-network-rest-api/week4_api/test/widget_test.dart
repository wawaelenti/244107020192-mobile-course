// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/main.dart';

void main() {
  testWidgets('menampilkan halaman posts tanpa request jaringan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pagedPostsProvider.overrideWith(StaticPagedPostsNotifier.new),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Posts Paged'), findsOneWidget);
    expect(find.text('Semua data termuat.'), findsOneWidget);
  });
}

class StaticPagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() => const PagedPostsState(hasMore: false);
}
