import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = FutureProvider<List<Note>>((ref) {
  return ref.watch(noteRepositoryProvider).fetchNotes();
});

final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).countDirty();
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Catatan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                ),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  return;
                }

                await ref.read(noteRepositoryProvider).addNote(
                      title: titleController.text.trim(),
                      body: bodyController.text.trim(),
                    );

                // Tutup dialog terlebih dahulu
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                // Setelah dialog ditutup, perbarui data
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          Center(
            child: dirtyCount.when(
              data: (count) => Text(
                'Belum sync: $count',
              ),
              loading: () => const Text('...'),
              error: (_, _) => const Text('Error'),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi',
            onPressed: () async {
              final repo = ref.read(noteRepositoryProvider);

              await syncNotes(repo);

              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
            },
          ),
        ],
      ),

      body: notes.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stackTrace) => Center(
          child: Text('Terjadi error: $error'),
        ),

        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Belum ada catatan'),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final note = items[index];

              return NoteTile(
                note: note,
                onDelete: () async {
                  if (note.id == null) return;

                  await ref
                      .read(noteRepositoryProvider)
                      .deleteNote(note.id!);

                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNote(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}