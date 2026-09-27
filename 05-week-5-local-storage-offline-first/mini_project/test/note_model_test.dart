import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project/note.dart';

void main() {
  test('Note round-trips its persisted fields', () {
    final note = Note(
      id: 7,
      title: 'Rencana',
      body: 'Tulis test model',
      createdAt: DateTime.utc(2026, 9, 26, 8),
      updatedAt: DateTime.utc(2026, 9, 26, 9),
      dirty: true,
      deletedAt: DateTime.utc(2026, 9, 26, 10),
    );
    final restored = Note.fromMap(note.toMap());

    expect(restored.id, note.id);
    expect(restored.title, note.title);
    expect(restored.body, note.body);
    expect(restored.createdAt, note.createdAt);
    expect(restored.updatedAt, note.updatedAt);
    expect(restored.dirty, isTrue);
    expect(restored.deletedAt, note.deletedAt);
  });
}
