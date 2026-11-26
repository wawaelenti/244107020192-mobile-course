import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

typedef NotesResult = ({List<Note> notes, Failure? failure});

/// Cache satu daftar selama 30 detik; kegagalan tidak disimpan.
class CachedNoteRepository implements NoteRepository {
  CachedNoteRepository(
    this._source, {
    DateTime Function()? clock,
    this.enabled = true,
  }) : _clock = clock ?? DateTime.now;

  final NoteRepository _source;
  final bool enabled;
  final DateTime Function() _clock;
  NotesResult? _cached;
  DateTime? _expiresAt;
  Future<NotesResult>? _pending;
  int _generation = 0;

  void invalidate() {
    _generation++;
    _cached = null;
    _expiresAt = null;
    _pending = null;
  }

  @override
  Future<NotesResult> fetchNotes() {
    if (!enabled) return _source.fetchNotes();
    if (_cached != null && _clock().isBefore(_expiresAt!)) {
      return Future.value(_cached);
    }
    return _pending ??= _load(_generation);
  }

  Future<NotesResult> _load(int generation) async {
    try {
      final result = await _source.fetchNotes();
      if (result.failure != null) return result;
      final snapshot = (
        notes: List<Note>.unmodifiable(result.notes),
        failure: result.failure,
      );
      if (generation == _generation) {
        _cached = snapshot;
        _expiresAt = _clock().add(const Duration(seconds: 30));
      }
      return snapshot;
    } finally {
      if (generation == _generation) _pending = null;
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final result = await _source.addNote(title: title, body: body);
    if (result.failure == null) invalidate();
    return result;
  }
}
