import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/data/providers/note_data_providers.dart';
import 'package:campus_notify/features/notes/data/repositories/cached_note_repository.dart';
import 'package:campus_notify/features/notes/presentation/page/note_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_note_repository.dart';

final _title = find.byKey(const Key('noteTitle'));
final _body = find.byKey(const Key('noteBody'));
final _save = find.widgetWithText(FilledButton, 'Simpan');

void main() {
  group('Catatan offline', () {
    late FakeNoteRepository repository;

    setUp(() {
      repository = FakeNoteRepository();
    });

    Future<void> openNotes(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(
              CachedNoteRepository(repository),
            ),
          ],
          child: const MaterialApp(home: NotesScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openForm(WidgetTester tester) async {
      await openNotes(tester);
      await tester.tap(find.byTooltip('Tambah catatan'));
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan keadaan kosong dan tombol tambah', (tester) async {
      await openNotes(tester);

      expect(find.text('Catatan offline'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
      expect(find.byTooltip('Tambah catatan'), findsOneWidget);
    });

    for (final title in ['', '   ']) {
      testWidgets(
        'menampilkan validasi untuk judul ${title.isEmpty ? 'kosong' : 'whitespace'}',
        (tester) async {
          await openForm(tester);
          await tester.enterText(_title, title);

          await tester.tap(_save);
          await tester.pumpAndSettle();

          expect(find.text('Judul catatan wajib diisi.'), findsOneWidget);
          expect(_title, findsOneWidget);
          expect(repository.addCalls, 0);
        },
      );
    }

    testWidgets('menampilkan kegagalan baca dan pulih setelah coba lagi', (
      tester,
    ) async {
      repository.fetchFailure = const LocalFailure('Gagal membaca catatan.');
      await openNotes(tester);

      expect(find.textContaining('Gagal membaca catatan.'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsNothing);

      repository.fetchFailure = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal membaca catatan.'), findsNothing);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
    });

    testWidgets('kembali ke daftar dan menampilkan catatan yang disimpan', (
      tester,
    ) async {
      await openForm(tester);
      await tester.enterText(_title, '  Jadwal praktikum  ');
      await tester.enterText(_body, 'Bawa laptop.');

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(_title, findsNothing);
      expect(find.text('Jadwal praktikum'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsNothing);
      expect((await repository.fetchNotes()).notes.single.body, 'Bawa laptop.');
    });

    testWidgets('menahan simpan ganda sampai penyimpanan selesai', (
      tester,
    ) async {
      final pendingSave = Completer<void>();
      repository.beforeSave = () => pendingSave.future;
      await openForm(tester);
      await tester.enterText(_title, 'Catatan sekali');

      // Dua ketukan sebelum frame berikutnya juga harus dilindungi oleh _saving.
      await tester.tap(_save);
      await tester.tap(_save);
      await tester.pump();

      expect(repository.addCalls, 1);
      expect((await repository.fetchNotes()).notes, isEmpty);
      expect(find.text('Menyimpan…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.widget<TextFormField>(_title).enabled, isFalse);
      expect(tester.widget<TextFormField>(_body).enabled, isFalse);

      pendingSave.complete();
      await tester.pumpAndSettle();

      expect(find.text('Catatan sekali'), findsOneWidget);
      expect((await repository.fetchNotes()).notes, hasLength(1));
      expect(repository.addCalls, 1);
    });

    testWidgets('mempertahankan masukan saat gagal dan bisa menyimpan ulang', (
      tester,
    ) async {
      repository.saveFailure = const LocalFailure(
        'Penyimpanan tidak tersedia.',
      );
      await openForm(tester);
      await tester.enterText(_title, 'Jadwal praktikum');
      await tester.enterText(_body, 'Bawa laptop.');

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(find.text('Penyimpanan tidak tersedia.'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_title).controller?.text,
        'Jadwal praktikum',
      );
      expect(
        tester.widget<TextFormField>(_body).controller?.text,
        'Bawa laptop.',
      );
      expect((await repository.fetchNotes()).notes, isEmpty);

      repository.saveFailure = null;
      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(find.text('Jadwal praktikum'), findsOneWidget);
      expect(repository.addCalls, 2);
    });
  });
}
