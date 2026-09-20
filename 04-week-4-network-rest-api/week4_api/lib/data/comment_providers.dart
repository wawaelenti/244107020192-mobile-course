import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/comment.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

/// Menyediakan repository agar notifier tidak membuat dependency secara manual.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// Notifier family menyimpan state komentar secara terpisah untuk setiap postId.
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  CommentNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    // Exception dari repository otomatis diubah Riverpod menjadi AsyncError.
    return ref.read(commentRepositoryProvider).fetchComments(postId);
  }

  /// Memuat ulang komentar dan mempertahankan penanganan AsyncError otomatis.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(commentRepositoryProvider).fetchComments(postId),
    );
  }
}

/// Provider family untuk membaca komentar berdasarkan id post.
final commentsProvider =
    AsyncNotifierProvider.family<CommentNotifier, List<Comment>, int>(
      CommentNotifier.new,
      // Mematikan retry otomatis agar error langsung dapat ditampilkan ke user.
      retry: (retryCount, error) => null,
    );

/// Mengubah error teknis Dio menjadi pesan yang mudah dipahami pengguna.
String commentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi terlalu lama. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 404:
            return 'Komentar tidak ditemukan (404).';
          case 500:
            return 'Server sedang bermasalah (500). Coba lagi nanti.';
          default:
            return 'Server mengembalikan kesalahan. Coba lagi nanti.';
        }
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }

  return 'Terjadi kesalahan tak terduga. Coba lagi.';
}
