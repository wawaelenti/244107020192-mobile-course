import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';

// Sinkronisasi catatan yang masih dirty
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  // Simulasi proses sinkronisasi ke server
  await Future.delayed(
    const Duration(seconds: 1),
  );

  await repo.markAllSynced();

  return dirtyCount;
}

// Membaca posts yang sudah tersimpan di SQLite
Future<List<Post>> readCachedPosts() async {
  final db = await openNotesDb();

  final rows = await db.query(
    'cached_posts',
    orderBy: 'id ASC',
  );

  return rows.map((row) {
    final payload = jsonDecode(
      row['payload'] as String,
    ) as Map<String, dynamic>;

    return Post.fromJson(payload);
  }).toList();
}

// Mengambil posts dari API lalu menyimpannya ke SQLite
Future<void> refreshPostsInBackground() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  try {
    final response = await dio.get<List>('/posts');
    final data = response.data ?? [];

    final db = await openNotesDb();

    final batch = db.batch();

    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final post = Post.fromJson(item);

        batch.insert(
          'cached_posts',
          {
            'id': post.id,
            'payload': jsonEncode(post.toJson()),
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);
  } catch (_) {
    // Jika offline, cache lokal tetap digunakan.
  }
}

// Cache-first:
// baca SQLite terlebih dahulu,
// kemudian refresh data API di background.
Future<List<Post>> loadPostsCacheFirst() async {
  final cached = await readCachedPosts();

  refreshPostsInBackground();

  return cached;
}