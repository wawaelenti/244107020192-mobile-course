import 'dart:convert';
import 'dart:developer';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

/// Penyimpanan browser disuntikkan agar decoding/persistensi juga dapat diuji.
class JsonNoteRepository implements NoteRepository {
  JsonNoteRepository({required this.read, required this.write});

  final String? Function() read;
  final void Function(String) write;
  int sourceReads = 0;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final notes = Timeline.timeSync('notes.readAndDecode', () {
        sourceReads++;
        final encoded = read();
        final rows = encoded == null
            ? <dynamic>[]
            : jsonDecode(encoded) as List;
        final result = rows
            .map(
              (r) =>
                  NoteModel.fromMap(Map<String, Object?>.from(r as Map))
                      .toEntity(),
            )
            .toList();
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return result;
      });
      return (notes: notes, failure: null);
    } catch (error) {
      return (
        notes: <Note>[],
        failure: LocalFailure('Gagal membaca catatan browser: $error'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final current = await fetchNotes();
    if (current.failure != null) return (note: null, failure: current.failure);
    try {
      final id =
          current.notes.fold<int>(
            0,
            (max, n) => (n.id ?? 0) > max ? n.id! : max,
          ) +
          1;
      final note = NoteModel(
        id: id,
        title: title,
        body: body,
        updatedAt: DateTime.now(),
        dirty: true,
      );
      write(
        jsonEncode([
          note.toMap(),
          for (final n in current.notes)
            NoteModel(
              id: n.id,
              title: n.title,
              body: n.body,
              updatedAt: n.updatedAt,
              dirty: n.dirty,
            ).toMap(),
        ]),
      );
      return (note: note.toEntity(), failure: null);
    } catch (error) {
      return (
        note: null,
        failure: LocalFailure('Gagal menyimpan catatan browser: $error'),
      );
    }
  }
}
