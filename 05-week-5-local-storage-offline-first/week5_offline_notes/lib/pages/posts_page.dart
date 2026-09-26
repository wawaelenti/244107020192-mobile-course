import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/sync.dart';

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final cached = await readCachedPosts();

  // Jika cache masih kosong, ambil data API terlebih dahulu.
  if (cached.isEmpty) {
    await refreshPostsInBackground();
    return readCachedPosts();
  }

  // Jika cache sudah ada, tampilkan cache terlebih dahulu.
  // Refresh API tetap dilakukan di background.
  refreshPostsInBackground().then((_) {
    ref.invalidateSelf();
  });

  return cached;
});

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(postsProvider);
            },
          ),
        ],
      ),
      body: posts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Terjadi error: $error'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Belum ada cache posts'),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final post = items[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Text('${post.id}'),
                ),
                title: Text(post.title),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}