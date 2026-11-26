import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/usecases/add_note.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_note_repository.dart';

void main() {
  group('AddNote', () {
    late FakeNoteRepository repository;
    late AddNote addNote;

    setUp(() {
      repository = FakeNoteRepository();
      addNote = AddNote(repository);
    });

    test('menyimpan judul yang sudah dirapikan dan isi asli', () async {
      const body = 'Baris pertama\nBaris kedua';
      final result = await addNote(title: '  Jadwal praktikum  ', body: body);

      expect(result.failure, isNull);
      expect(result.note?.title, 'Jadwal praktikum');
      expect(result.note?.body, body);
      expect((await repository.fetchNotes()).notes, [result.note]);
    });

    group('validasi judul', () {
      for (final title in ['', ' \t\n ']) {
        test(
          'menolak ${title.isEmpty ? 'kosong' : 'whitespace'} sebelum akses data',
          () async {
            final result = await addNote(title: title);

            expect(result.failure?.message, 'Judul catatan wajib diisi.');
            expect(result.note, isNull);
            expect(repository.addCalls, 0);
          },
        );
      }
    });

    test('menerima judul satu karakter dengan isi kosong', () async {
      final result = await addNote(title: ' A ');

      expect(result.failure, isNull);
      expect(result.note?.title, 'A');
      expect(result.note?.body, isEmpty);
      expect(repository.addCalls, 1);
    });

    test('meneruskan kegagalan simpan tanpa menambah catatan', () async {
      const failure = LocalFailure('Penyimpanan tidak tersedia.');
      repository.saveFailure = failure;

      final result = await addNote(title: 'Jadwal praktikum');

      expect(result.failure, same(failure));
      expect(result.note, isNull);
      expect((await repository.fetchNotes()).notes, isEmpty);
    });
  });
}
