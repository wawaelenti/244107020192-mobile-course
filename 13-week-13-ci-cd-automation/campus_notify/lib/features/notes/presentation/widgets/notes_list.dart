import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';

class NotesList extends StatelessWidget {
  const NotesList(
    this.notes, {
    super.key,
    this.baseline = false,
    this.controller,
  });

  final List<Note> notes;
  final bool baseline;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      itemExtent: baseline ? null : 88,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        if (baseline) {
          return ListTile(
            title: Text(note.title),
            subtitle: Text(note.body),
            onTap: () => openNoteDetail(context, note),
          );
        }
        return NoteTile(key: ValueKey(note.id ?? index), note: note);
      },
    );
  }
}

class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) => ListTile(
    isThreeLine: true,
    title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    onTap: () => openNoteDetail(context, note),
  );
}

Future<void> openNoteDetail(BuildContext context, Note note) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(note.title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(note.body),
        ),
      ),
    ),
  );
}
