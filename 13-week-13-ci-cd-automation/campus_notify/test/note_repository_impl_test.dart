import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/data/repositories/note_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

class _FakeDatabase extends Fake implements Database {
  List<Map<String, Object?>> rows = [];
  Object? readError;
  Object? writeError;
  String? queriedTable;
  String? requestedOrder;
  String? insertedTable;
  Map<String, Object?>? insertedValues;

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (readError case final error?) throw error;
    queriedTable = table;
    requestedOrder = orderBy;
    return rows;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    if (writeError case final error?) throw error;
    insertedTable = table;
    insertedValues = Map.of(values);
    return 42;
  }
}

void main() {
  group('NoteRepositoryImpl', () {
    late _FakeDatabase database;
    late NoteRepositoryImpl repository;

    setUp(() {
      database = _FakeDatabase();
      repository = NoteRepositoryImpl(openDb: () async => database);
    });

    test(
      'membaca kolom SQLite menjadi catatan dan meminta urutan terbaru',
      () async {
        database.rows = [
          {
            'id': 7,
            'title': 'Jadwal',
            'body': 'Bawa laptop',
            'updated_at': '2026-11-26T08:00:00.000Z',
            'dirty': 1,
          },
        ];

        final result = await repository.fetchNotes();

        expect(result.failure, isNull);
        expect(database.queriedTable, 'notes');
        expect(database.requestedOrder, 'updated_at DESC');
        final note = result.notes.single;
        expect(note.id, 7);
        expect(note.title, 'Jadwal');
        expect(note.body, 'Bawa laptop');
        expect(note.updatedAt, DateTime.utc(2026, 11, 26, 8));
        expect(note.dirty, isTrue);
      },
    );

    test('menyimpan isi kosong dan mengembalikan ID dari database', () async {
      final result = await repository.addNote(title: 'Jadwal');

      expect(result.failure, isNull);
      final note = result.note!;
      expect(note.id, 42);
      expect(note.title, 'Jadwal');
      expect(note.body, isEmpty);
      expect(note.dirty, isTrue);
      expect(database.insertedTable, 'notes');
      expect(database.insertedValues, {
        'id': null,
        'title': 'Jadwal',
        'body': '',
        'updated_at': note.updatedAt.toIso8601String(),
        'dirty': 1,
      });
    });

    test('kegagalan query menghasilkan failure dan daftar kosong', () async {
      database.readError = StateError('disk tidak tersedia');

      final result = await repository.fetchNotes();

      expect(result.notes, isEmpty);
      expect(result.failure, isA<LocalFailure>());
      expect(result.failure?.message, contains('Gagal membaca catatan:'));
      expect(result.failure?.message, contains('disk tidak tersedia'));
    });

    test(
      'kegagalan insert tidak dilaporkan sebagai catatan berhasil',
      () async {
        database.writeError = StateError('disk penuh');

        final result = await repository.addNote(title: 'Jadwal');

        expect(result.note, isNull);
        expect(result.failure, isA<LocalFailure>());
        expect(result.failure?.message, contains('Gagal menyimpan catatan:'));
        expect(result.failure?.message, contains('disk penuh'));
        expect(database.insertedValues, isNull);
      },
    );
  });
}
