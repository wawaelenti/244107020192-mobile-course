import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Repository yang bertanggung jawab mengambil komentar dari REST API.
class CommentRepository {
  /// Repository menerima Dio agar mudah dipakai ulang dan di-mock saat test.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil komentar untuk satu post dengan batas waktu sepuluh detik.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Abaikan item response yang bukan object JSON yang valid.
    final data = response.data ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
