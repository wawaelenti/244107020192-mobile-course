import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../note.dart';
import '../providers.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.note});
  final Note? note;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul catatan wajib diisi.')),
      );
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(notesRepositoryProvider)
        .saveNote(
          id: widget.note?.id,
          title: title,
          body: _bodyController.text,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.note == null ? 'Catatan baru' : 'Edit catatan'),
      actions: [
        IconButton(
          onPressed: _saving ? null : _save,
          tooltip: 'Simpan catatan',
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
      children: [
        TextField(
          controller: _titleController,
          autofocus: widget.note == null,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            hintText: 'Judul catatan',
            border: InputBorder.none,
            counterText: '',
          ),
        ),
        const Divider(height: 24),
        TextField(
          controller: _bodyController,
          minLines: 12,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Tulis sesuatu...',
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Perubahan disimpan di perangkat dan menunggu sinkronisasi.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}
