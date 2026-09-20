import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostsState {
  const PostsState({
    this.items = const [],
    this.page = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  PostsState copyWith({
    List<Post>? items,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return PostsState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PostsNotifier extends Notifier<PostsState> {
  bool _requestInFlight = false;

  @override
  PostsState build() {
    return const PostsState();
  }

  Future<void> loadFirstPage() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    state = state.copyWith(
      items: const [],
      page: 0,
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
    );
    try {
      final items = await ref.read(postsRepositoryProvider).fetchPage(page: 1);
      state = PostsState(
        items: items,
        page: 1,
        isLoading: false,
        hasMore: items.length == 10,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> loadNextPage() async {
    if (_requestInFlight ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore)
      return;
    _requestInFlight = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final items = await ref
          .read(postsRepositoryProvider)
          .fetchPage(page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...items],
        page: nextPage,
        isLoadingMore: false,
        hasMore: items.length == 10,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    } finally {
      _requestInFlight = false;
    }
  }
}

final postsProvider = NotifierProvider<PostsNotifier, PostsState>(
  PostsNotifier.new,
);
