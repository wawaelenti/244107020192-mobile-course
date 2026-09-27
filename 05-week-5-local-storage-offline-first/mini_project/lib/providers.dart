import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'data.dart';
import 'note.dart';

final remoteNotesApiProvider = Provider<RemoteNotesApi>(
  (ref) => RemoteNotesApi(),
);

final notesDatabaseProvider = FutureProvider<Database>((ref) async {
  return openOfflineNotesDatabase();
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return SqfliteNotesRepository(
    openDb: () => ref.read(notesDatabaseProvider.future),
    remoteApi: ref.watch(remoteNotesApiProvider),
  );
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => SharedPreferencesRepository(),
);

final notesProvider = FutureProvider<List<Note>>((ref) {
  return ref.watch(notesRepositoryProvider).fetchNotes();
});

final pendingSyncCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notesRepositoryProvider).pendingSyncCount();
});

final readingsProvider = FutureProvider<List<ReadingItem>>((ref) {
  return ref.watch(notesRepositoryProvider).fetchReadings();
});

final lastOpenedProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(preferencesRepositoryProvider).loadLastOpened();
});

final themeControllerProvider = AsyncNotifierProvider<ThemeController, bool>(
  ThemeController.new,
);

class ThemeController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.read(preferencesRepositoryProvider).loadDarkMode();

  Future<void> setDarkMode(bool enabled) async {
    state = AsyncData(enabled);
    await ref.read(preferencesRepositoryProvider).saveDarkMode(enabled);
  }
}
