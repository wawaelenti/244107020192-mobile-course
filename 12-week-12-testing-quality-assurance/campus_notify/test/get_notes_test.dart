import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/usecases/get_notes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_note_repository.dart';

void main() {
  group('GetNotes', () {
    test('meneruskan daftar dari repository', () async {
      final note = Note(
        title: 'Jadwal praktikum',
        updatedAt: DateTime.utc(2026),
      );
      final repository = FakeNoteRepository(notes: [note]);

      final result = await GetNotes(repository)();

      expect(result.failure, isNull);
      expect(result.notes, [note]);
    });

    test('meneruskan kegagalan baca tanpa melempar', () async {
      const failure = LocalFailure('Gagal membaca catatan.');
      final repository = FakeNoteRepository(fetchFailure: failure);

      final result = await GetNotes(repository)();

      expect(result.failure, same(failure));
      expect(result.notes, isEmpty);
    });
  });
}
