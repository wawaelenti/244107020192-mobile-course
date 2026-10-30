import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class _FakeNoteRepository extends NoteRepository {
  _FakeNoteRepository(this.notes)
    : super(openDb: () => throw UnimplementedError());

  final List<Note> notes;

  @override
  Future<List<Note>> fetchNotes() async => notes;

  @override
  Future<int> countDirty() async => 0;
}

void main() {
  testWidgets('pencarian tanpa hasil menampilkan empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            _FakeNoteRepository([
              Note(
                title: 'Belanja Mingguan',
                updatedAt: DateTime(2026, 10, 30),
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('notes-search-field')),
      'judul yang tidak cocok',
    );
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada catatan yang cocok'), findsOneWidget);
    expect(find.text('Belanja Mingguan'), findsNothing);
  });
}
