import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project/data.dart';
import 'package:mini_project/note.dart';
import 'package:mini_project/providers.dart';

class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository(this.notes);
  final List<Note> notes;
  var fetchCount = 0;

  @override
  Future<List<Note>> fetchNotes() async {
    fetchCount++;
    return notes;
  }

  @override
  Future<void> saveNote({
    int? id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> deleteNote(int id) async {}

  @override
  Future<int> pendingSyncCount() async =>
      notes.where((note) => note.dirty).length;

  @override
  Future<int> syncNotes() async => 0;

  @override
  Future<List<ReadingItem>> fetchReadings({bool refresh = false}) async =>
      const [];
}

void main() {
  test('notes provider reads through the overridden fake repository', () async {
    final expected = Note(
      id: 1,
      title: 'Catatan lokal',
      body: 'Tersedia offline',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 9),
    );
    final fakeRepository = FakeNotesRepository([expected]);
    final container = ProviderContainer(
      overrides: [notesRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    addTearDown(container.dispose);

    final result = await container.read(notesProvider.future);
    expect(result, [expected]);
    expect(fakeRepository.fetchCount, 1);
  });
}
