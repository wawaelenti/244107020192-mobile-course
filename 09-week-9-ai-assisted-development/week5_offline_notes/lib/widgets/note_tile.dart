import 'package:flutter/material.dart';

import '../data/local/note.dart';
import 'package:go_router/go_router.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (note.id != null) {
          context.push('/note/${note.id}');
        }
      },
      leading: Icon(
        note.dirty ? Icons.cloud_off : Icons.cloud_done,
      ),
      title: Text(note.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.body),
          if (note.dirty)
            const Text(
              'Belum tersinkron',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}