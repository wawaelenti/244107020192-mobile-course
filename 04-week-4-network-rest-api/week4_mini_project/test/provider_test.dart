import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_mini_project/data/models/post.dart';
import 'package:week4_mini_project/data/providers.dart';
import 'package:week4_mini_project/data/repositories/post_repository.dart';

void main() {
  test(
    'provider memuat data dari repository palsu dan menjaga guard request',
    () async {
      final repository = FakePostsRepository(
        pages: {
          1: List.generate(
            10,
            (index) => Post(
              userId: 1,
              id: index + 1,
              title: index == 0 ? 'Satu' : 'Post ${index + 1}',
              body: 'Isi post ${index + 1}',
            ),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [postsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(postsProvider.notifier).loadFirstPage();
      expect(container.read(postsProvider).items.first.title, 'Satu');

      await Future.wait([
        container.read(postsProvider.notifier).loadNextPage(),
        container.read(postsProvider.notifier).loadNextPage(),
      ]);

      expect(repository.calls, 2);
      expect(container.read(postsProvider).items.length, 11);
    },
  );
}

class FakePostsRepository implements PostsRepository {
  FakePostsRepository({required this.pages});

  final Map<int, List<Post>> pages;
  int calls = 0;

  @override
  Future<List<Post>> fetchPage({required int page, int limit = 10}) async {
    calls++;
    if (page == 2) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return [Post(userId: 1, id: 2, title: 'Dua', body: 'Isi dua')];
    }
    return pages[page] ?? const [];
  }
}
