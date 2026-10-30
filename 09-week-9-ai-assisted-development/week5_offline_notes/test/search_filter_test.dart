import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/domain/filter_notes.dart';

void main() {
  final notes = [
    Note(id: 1, title: 'Belanja Mingguan', updatedAt: DateTime(2026, 10, 30)),
    Note(id: 2, title: 'Catatan belanja', updatedAt: DateTime(2026, 10, 29)),
    Note(id: 3, title: 'Jadwal Kuliah', updatedAt: DateTime(2026, 10, 28)),
  ];

  test('filter mengabaikan huruf besar dan kecil', () {
    final result = filterNotes(notes, 'belanja', (note) => note.title);

    expect(result, hasLength(2));
    expect(result.map((note) => note.id), [1, 2]);
  });

  test('query kosong mengembalikan semua catatan', () {
    expect(filterNotes(notes, '  ', (note) => note.title), hasLength(3));
  });

  test('query yang tidak cocok mengembalikan daftar kosong', () {
    expect(filterNotes(notes, 'zzz-tak-ada', (note) => note.title), isEmpty);
  });
}
