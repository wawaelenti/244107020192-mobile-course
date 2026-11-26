import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/add_note.dart';
import '../providers/note_providers.dart';

class AddNotePage extends ConsumerStatefulWidget {
  const AddNotePage({super.key});

  @override
  ConsumerState<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends ConsumerState<AddNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref.read(addNoteProvider)(
      title: _title.text,
      body: _body.text,
    );
    if (!mounted) return;
    if (result.note != null && result.failure == null) {
      ref.invalidate(notesProvider);
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _error = result.failure?.message ?? 'Gagal menyimpan catatan.';
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tambah catatan')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('noteTitle'),
                controller: _title,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: AddNote.validateTitle,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('noteBody'),
                controller: _body,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Isi catatan'),
                minLines: 3,
                maxLines: 6,
              ),
              if (_error case final message?) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan…' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
