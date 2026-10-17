
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/note_data_providers.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/entities/note.dart';

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.notes;
});
