import '../../domain/repositories/note_repository.dart';
import '../datasources/local/notes_database.dart';
import 'note_repository_impl.dart';

NoteRepository createPlatformNoteRepository() =>
    NoteRepositoryImpl(openDb: openNotesDb);
