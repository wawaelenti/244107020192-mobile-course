
import 'package:dio/dio.dart';

String apiErrorMessage(DioException error) {
  if (error.response?.statusCode == 401) {
    return 'Sesi berakhir. Silakan login kembali.';
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'Koneksi timeout. Silakan coba lagi.';
  }

  if (error.type == DioExceptionType.connectionError) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}
