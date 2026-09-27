import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'note.dart';

Future<Database> openOfflineNotesDatabase() async {
  final directory = await getDatabasesPath();
  return openDatabase(
    path.join(directory, 'lembar_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 1 CHECK (dirty IN (0, 1)),
          deleted_at TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC)',
      );
      await db.execute('''
        CREATE TABLE reading_cache (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    },
  );
}

abstract class NotesRepository {
  Future<List<Note>> fetchNotes();
  Future<void> saveNote({int? id, required String title, required String body});
  Future<void> deleteNote(int id);
  Future<int> pendingSyncCount();
  Future<int> syncNotes();
  Future<List<ReadingItem>> fetchReadings({bool refresh = false});
}

class RemoteNotesApi {
  RemoteNotesApi({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse('https://jsonplaceholder.typicode.com');
  final http.Client _client;

  Future<List<ReadingItem>> fetchReadings() async {
    final response = await _client.get(
      _baseUri.replace(path: '/posts', queryParameters: {'_limit': '12'}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Gagal memuat bacaan (${response.statusCode}).',
      );
    }
    final rows = jsonDecode(response.body) as List<dynamic>;
    return rows
        .map((row) => ReadingItem.fromMap(row as Map<String, Object?>))
        .toList();
  }

  Future<void> syncNote(Note note) async {
    final response = note.deletedAt == null
        ? await _client.post(
            _baseUri.replace(path: '/posts'),
            headers: {'content-type': 'application/json; charset=UTF-8'},
            body: jsonEncode(note.toMap()),
          )
        : await _client.delete(_baseUri.replace(path: '/posts/${note.id}'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('Sync ditolak (${response.statusCode}).');
    }
  }
}

class SqfliteNotesRepository implements NotesRepository {
  SqfliteNotesRepository({required this.openDb, required this.remoteApi});

  final Future<Database> Function() openDb;
  final RemoteNotesApi remoteApi;

  @override
  Future<List<Note>> fetchNotes() async {
    final db = await openDb();
    final rows = await db.query(
      'notes',
      where: 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  @override
  Future<void> saveNote({
    int? id,
    required String title,
    required String body,
  }) async {
    final db = await openDb();
    final now = DateTime.now().toUtc().toIso8601String();
    if (id == null) {
      await db.insert('notes', {
        'title': title.trim(),
        'body': body.trim(),
        'created_at': now,
        'updated_at': now,
        'dirty': 1,
        'deleted_at': null,
      });
      return;
    }
    await db.update(
      'notes',
      {
        'title': title.trim(),
        'body': body.trim(),
        'updated_at': now,
        'dirty': 1,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteNote(int id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final db = await openDb();
    await db.update(
      'notes',
      {'deleted_at': now, 'updated_at': now, 'dirty': 1},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  @override
  Future<int> pendingSyncCount() async {
    final db = await openDb();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM notes WHERE dirty = 1',
    );
    return (rows.first['count'] as num).toInt();
  }

  @override
  Future<int> syncNotes() async {
    final db = await openDb();
    final rows = await db.query(
      'notes',
      where: 'dirty = 1',
      orderBy: 'updated_at ASC',
    );
    var synced = 0;
    var failed = 0;
    for (final row in rows) {
      final note = Note.fromMap(row);
      try {
        await remoteApi.syncNote(note);
        await db.update(
          'notes',
          {'dirty': 0},
          where: 'id = ? AND updated_at = ?',
          whereArgs: [note.id, row['updated_at']],
        );
        synced++;
      } on Exception {
        failed++;
      }
    }
    if (failed > 0) throw SyncException(synced: synced, failed: failed);
    return synced;
  }

  @override
  Future<List<ReadingItem>> fetchReadings({bool refresh = false}) async {
    final db = await openDb();
    final cachedRows = await db.query('reading_cache', orderBy: 'id ASC');
    final cached = cachedRows.map(ReadingItem.fromMap).toList();
    if (!refresh && cached.isNotEmpty) return cached;

    try {
      final fresh = await remoteApi.fetchReadings();
      await db.transaction((txn) async {
        await txn.delete('reading_cache');
        for (final item in fresh) {
          await txn.insert('reading_cache', {
            ...item.toMap(),
            'cached_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      });
      return fresh;
    } on Exception {
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }
}

class SyncException implements Exception {
  const SyncException({required this.synced, required this.failed});
  final int synced;
  final int failed;
}

abstract class PreferencesRepository {
  Future<bool> loadDarkMode();
  Future<void> saveDarkMode(bool enabled);
  Future<DateTime?> loadLastOpened();
  Future<void> saveLastOpened(DateTime value);
}

class SharedPreferencesRepository implements PreferencesRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<bool> loadDarkMode() async =>
      (await _prefs).getBool('dark_mode') ?? false;

  @override
  Future<void> saveDarkMode(bool enabled) async =>
      (await _prefs).setBool('dark_mode', enabled);

  @override
  Future<DateTime?> loadLastOpened() async {
    final value = (await _prefs).getString('last_opened');
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> saveLastOpened(DateTime value) async =>
      (await _prefs).setString('last_opened', value.toUtc().toIso8601String());
}
