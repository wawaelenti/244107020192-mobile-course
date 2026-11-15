import 'package:campus_notify/features/notes/data/repositories/json_note_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('browser storage: kosong, tambah, dan baca dari instance baru', () async {
    String? stored;
    JsonNoteRepository create() => JsonNoteRepository(read: () => stored, write: (s) => stored = s);
    final first = create();
    expect((await first.fetchNotes()).notes, isEmpty);
    expect((await first.addNote(title: 'Catatan web', body: 'Tersimpan offline')).failure, isNull);
    final reloaded = await create().fetchNotes();
    expect(reloaded.notes.single.title, 'Catatan web');
    expect(reloaded.notes.single.body, 'Tersimpan offline');
    expect(reloaded.notes.single.id, 1);
  });

  test('JSON rusak tidak ditimpa oleh penulisan baru', () async {
    var stored = '{rusak';
    final repo = JsonNoteRepository(read: () => stored, write: (s) => stored = s);
    expect((await repo.fetchNotes()).failure, isNotNull);
    expect((await repo.addNote(title: 'Baru')).failure, isNotNull);
    expect(stored, '{rusak');
  });

  test('kuota penyimpanan browser dilaporkan sebagai failure', () async {
    final repo = JsonNoteRepository(read: () => null, write: (_) => throw StateError('QuotaExceeded'));
    final result = await repo.addNote(title: 'Baru');
    expect(result.note, isNull);
    expect(result.failure, isNotNull);
  });
}
