import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/models/post.dart';

void main() {
  test('Comment.fromJson memakai nilai aman saat field hilang', () {
    // JSON parsial mensimulasikan response API dengan field null/hilang.
    final comment = Comment.fromJson({'id': 7});

    // Field angka menjadi 0 dan field teks menjadi string kosong.
    expect(comment.postId, 0);
    expect(comment.id, 7);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Post.fromJson memakai nilai aman saat field hilang', () {
    final post = Post.fromJson({'id': 3});

    expect(post.userId, 0);
    expect(post.id, 3);
    expect(post.title, '');
    expect(post.body, '');
  });
}
