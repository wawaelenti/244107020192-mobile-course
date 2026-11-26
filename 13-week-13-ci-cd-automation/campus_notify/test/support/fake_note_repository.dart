import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note> notes = const [], this.fetchFailure})
    : _notes = [...notes];

  final List<Note> _notes;
  Failure? fetchFailure;
  Failure? saveFailure;
  Future<void> Function()? beforeSave;
  int addCalls = 0;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    final failure = fetchFailure;
    if (failure != null) return (notes: const <Note>[], failure: failure);
    return (notes: List<Note>.unmodifiable(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCalls++;
    await beforeSave?.call();
    final failure = saveFailure;
    if (failure != null) return (note: null, failure: failure);

    final note = Note(title: title, body: body, updatedAt: DateTime.utc(2026));
    _notes.insert(0, note);
    return (note: note, failure: null);
  }
}
