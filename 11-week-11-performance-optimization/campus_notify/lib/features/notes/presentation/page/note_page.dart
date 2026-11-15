import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/note_providers.dart';
import '../widgets/error_view.dart';
import '../widgets/notes_list.dart';
import '../../data/providers/note_data_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key, this.baseline = false, this.controller});

  final bool baseline;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(notesProvider),
      ),
      data: (notes) => RefreshIndicator(
        onRefresh: () async {
          ref.read(noteRepositoryProvider).invalidate();
          ref.invalidate(notesProvider);
          await ref.read(notesProvider.future);
        },
        child: notes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Belum ada catatan.')),
                  ),
                ],
              )
            : NotesList(notes, baseline: baseline, controller: controller),
      ),
    );
  }
}
