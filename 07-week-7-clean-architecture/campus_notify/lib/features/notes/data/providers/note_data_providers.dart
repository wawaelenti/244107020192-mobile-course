import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/note_repository_impl.dart';
import '../datasources/local/notes_database.dart';
import '../../domain/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});