import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class AddNote {
  const AddNote(this._repository);

  final NoteRepository _repository;

  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Judul catatan wajib diisi.';
    }
    return null;
  }

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) async {
    final error = validateTitle(title);
    if (error != null) {
      return (note: null, failure: LocalFailure(error));
    }
    return _repository.addNote(title: title.trim(), body: body);
  }
}
