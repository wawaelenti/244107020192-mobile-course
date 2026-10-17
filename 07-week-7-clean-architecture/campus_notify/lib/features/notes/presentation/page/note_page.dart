import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/note_providers.dart';
import '../widgets/error_view.dart';
import '../widgets/notes_list.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    return state.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(notesProvider),
      ),
      data: (notes) => notes.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : NotesList(notes),
    );
  }
}