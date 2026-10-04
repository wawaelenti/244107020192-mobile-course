import 'package:dio/dio.dart';

String apiErrorMessage(DioException error) {
  if (error.response?.statusCode == 401) {
    return 'Sesi kamu sudah berakhir. Silakan login kembali.';
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return 'Koneksi ke server terlalu lama. Silakan coba lagi.';
  }

  if (error.type == DioExceptionType.connectionError) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}