import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/data/repositories/cached_note_repository.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class CountingRepository implements NoteRepository {
  int reads = 0;
  bool fail = false;
  Completer<NotesResult>? gate;
  List<Note> items = [Note(title: 'Awal', updatedAt: DateTime(2026))];

  @override
  Future<NotesResult> fetchNotes() async {
    reads++;
    if (gate != null) return gate!.future;
    return (notes: items, failure: fail ? const LocalFailure('test') : null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(title: title, body: body, updatedAt: DateTime(2026));
    items = [...items, note];
    return (note: note, failure: null);
  }
}

void main() {
  test('cache hit, TTL, refresh, dan penulisan menjaga data terbaru', () async {
    var now = DateTime(2026);
    final source = CountingRepository();
    final cache = CachedNoteRepository(source, clock: () => now);
    final first = await cache.fetchNotes();
    await cache.fetchNotes();
    expect(source.reads, 1);
    expect(() => first.notes.clear(), throwsUnsupportedError);
    now = now.add(const Duration(seconds: 30));
    await cache.fetchNotes();
    expect(source.reads, 2);
    cache.invalidate();
    await cache.fetchNotes();
    expect(source.reads, 3);
    await cache.addNote(title: 'Baru');
    expect((await cache.fetchNotes()).notes.length, 2);
    expect(source.reads, 4);
  });

  test('kegagalan tidak menjadi cache', () async {
    final source = CountingRepository()..fail = true;
    final cache = CachedNoteRepository(source);
    await cache.fetchNotes();
    source.fail = false;
    expect((await cache.fetchNotes()).failure, isNull);
    expect(source.reads, 2);
  });

  test(
    'pembacaan paralel digabung; hasil lama tidak menimpa refresh',
    () async {
      final source = CountingRepository()..gate = Completer<NotesResult>();
      final cache = CachedNoteRepository(source);
      final old = cache.fetchNotes();
      final concurrent = cache.fetchNotes();
      expect(source.reads, 1);
      final gate = source.gate!;
      cache.invalidate();
      source.gate = null;
      final fresh = await cache.fetchNotes();
      gate.complete((notes: <Note>[], failure: null));
      await Future.wait([old, concurrent]);
      expect((await cache.fetchNotes()).notes, fresh.notes);
      expect(source.reads, 2);
    },
  );
}
