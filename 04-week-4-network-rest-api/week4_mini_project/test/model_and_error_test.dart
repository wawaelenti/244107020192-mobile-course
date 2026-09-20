import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_mini_project/data/models/post.dart';
import 'package:week4_mini_project/data/network_errors.dart';

void main() {
  test('Post.fromJson memakai default aman untuk field hilang', () {
    final post = Post.fromJson({'id': 4});

    expect(post.userId, 0);
    expect(post.id, 4);
    expect(post.title, '');
    expect(post.body, '');
  });

  test('friendlyErrorMessage memetakan connection error', () {
    final message = friendlyErrorMessage(
      DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(message, contains('terhubung'));
  });
}
