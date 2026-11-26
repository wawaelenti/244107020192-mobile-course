import 'package:campus_notify/features/notes/data/repositories/json_note_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'browser storage: kosong, tambah, dan baca dari instance baru',
    () async {
      String? stored;
      JsonNoteRepository create() =>
          JsonNoteRepository(read: () => stored, write: (s) => stored = s);
      final first = create();
      expect((await first.fetchNotes()).notes, isEmpty);
      expect(
        (await first.addNote(
          title: 'Catatan web',
          body: 'Tersimpan offline',
        )).failure,
        isNull,
      );
      final reloaded = await create().fetchNotes();
      expect(reloaded.notes.single.title, 'Catatan web');
      expect(reloaded.notes.single.body, 'Tersimpan offline');
      expect(reloaded.notes.single.id, 1);
    },
  );

  test('menambah catatan mempertahankan catatan lama dan ID berbeda', () async {
    String? stored;
    final repository = JsonNoteRepository(
      read: () => stored,
      write: (value) => stored = value,
    );
    final first = await repository.addNote(title: 'Pertama', body: 'Isi lama');
    final second = await repository.addNote(title: 'Kedua', body: 'Isi baru');

    expect(first.failure, isNull);
    expect(second.failure, isNull);
    expect(second.note?.id, isNot(first.note?.id));
    final reloaded = await JsonNoteRepository(
      read: () => stored,
      write: (value) => stored = value,
    ).fetchNotes();
    expect(reloaded.failure, isNull);
    expect(reloaded.notes, hasLength(2));
    expect(reloaded.notes.map((note) => note.id), unorderedEquals([1, 2]));
    expect(reloaded.notes.singleWhere((note) => note.id == 1).body, 'Isi lama');
    expect(reloaded.notes.singleWhere((note) => note.id == 2).body, 'Isi baru');
  });

  test('JSON rusak tidak ditimpa oleh penulisan baru', () async {
    var stored = '{rusak';
    final repo = JsonNoteRepository(
      read: () => stored,
      write: (s) => stored = s,
    );
    expect((await repo.fetchNotes()).failure, isNotNull);
    expect((await repo.addNote(title: 'Baru')).failure, isNotNull);
    expect(stored, '{rusak');
  });

  test('kuota penyimpanan browser dilaporkan sebagai failure', () async {
    final repo = JsonNoteRepository(
      read: () => null,
      write: (_) => throw StateError('QuotaExceeded'),
    );
    final result = await repo.addNote(title: 'Baru');
    expect(result.note, isNull);
    expect(result.failure, isNotNull);
  });
}
