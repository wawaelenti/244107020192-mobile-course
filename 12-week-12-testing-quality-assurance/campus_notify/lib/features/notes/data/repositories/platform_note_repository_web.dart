import 'package:web/web.dart' as web;

import '../../domain/repositories/note_repository.dart';
import 'json_note_repository.dart';

NoteRepository createPlatformNoteRepository() => JsonNoteRepository(
  read: () => web.window.localStorage.getItem('campus_notify.notes.v1'),
  write: (value) =>
      web.window.localStorage.setItem('campus_notify.notes.v1', value),
);
