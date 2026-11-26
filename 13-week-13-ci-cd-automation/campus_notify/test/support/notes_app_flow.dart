import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/features/notes/data/providers/note_data_providers.dart';
import 'package:campus_notify/features/notes/data/repositories/cached_note_repository.dart';
import 'package:campus_notify/features/notes/data/repositories/json_note_repository.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedInTokenStore extends TokenStore {
  @override
  Future<String?> readAccess() async => 'integration-test-session';
}

// Alur yang sama dijalankan oleh widget test dan integration test perangkat.
void registerNotesAppFlow() {
  testWidgets('buat catatan dari beranda dan buka isinya dari daftar', (
    tester,
  ) async {
    String? savedJson;
    final repository = CachedNoteRepository(
      JsonNoteRepository(
        read: () => savedJson,
        write: (value) => savedJson = value,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(_SignedInTokenStore()),
          noteRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catatan offline'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada catatan.'), findsOneWidget);

    await tester.tap(find.byTooltip('Tambah catatan'));
    await tester.pumpAndSettle();
    const title = 'Persiapan praktikum';
    const body = 'Bawa laptop dan siapkan bahan praktikum.';
    await tester.enterText(find.byKey(const Key('noteTitle')), '  $title  ');
    await tester.enterText(find.byKey(const Key('noteBody')), body);
    final save = find.widgetWithText(FilledButton, 'Simpan');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(savedJson, isNotNull);
    // Baca lewat instance baru agar hasil tidak hanya berasal dari cache UI.
    final reloaded = await JsonNoteRepository(
      read: () => savedJson,
      write: (value) => savedJson = value,
    ).fetchNotes();
    expect(reloaded.failure, isNull);
    expect(reloaded.notes, hasLength(1));
    expect(reloaded.notes.single.title, title);
    expect(reloaded.notes.single.body, body);

    await tester.tap(find.widgetWithText(ListTile, title));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, title), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      body,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, title), findsOneWidget);
  });
}
