import 'package:dio/dio.dart';

import '../models/post.dart';

abstract interface class PostsRepository {
  Future<List<Post>> fetchPage({required int page, int limit = 10});
}

class PostRepository implements PostsRepository {
  PostRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Post>> fetchPage({required int page, int limit = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    final data = response.data ?? const <dynamic>[];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }
}
