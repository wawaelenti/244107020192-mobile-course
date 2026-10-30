import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/domain/filter_notes.dart';
import 'package:week5_offline_notes/domain/sort_notes.dart';

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

  test('sorting judul A-Z tidak peka huruf besar dan kecil', () {
    final result = sortNotes(
      notes.reversed.toList(),
      order: NoteSortOrder.titleAscending,
      titleOf: (note) => note.title,
      updatedAtOf: (note) => note.updatedAt,
    );

    expect(result.map((note) => note.title), [
      'Belanja Mingguan',
      'Catatan belanja',
      'Jadwal Kuliah',
    ]);
  });

  test('sorting judul Z-A membalik urutan alfabetis', () {
    final result = sortNotes(
      notes,
      order: NoteSortOrder.titleDescending,
      titleOf: (note) => note.title,
      updatedAtOf: (note) => note.updatedAt,
    );

    expect(result.map((note) => note.title), [
      'Jadwal Kuliah',
      'Catatan belanja',
      'Belanja Mingguan',
    ]);
  });

  test('sorting terbaru menggunakan updatedAt tanpa mengubah input', () {
    final reversedNotes = notes.reversed.toList();
    final result = sortNotes(
      reversedNotes,
      order: NoteSortOrder.newest,
      titleOf: (note) => note.title,
      updatedAtOf: (note) => note.updatedAt,
    );

    expect(result.map((note) => note.id), [1, 2, 3]);
    expect(reversedNotes.map((note) => note.id), [3, 2, 1]);
  });
}
