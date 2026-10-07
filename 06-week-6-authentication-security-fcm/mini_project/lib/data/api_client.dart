import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_controller.dart';
import 'token_store.dart';

Dio? buildApiClient({
  required TokenStore tokenStore,
  required AuthController auth,
}) {
  const baseUrl = String.fromEnvironment('API_BASE_URL');
  if (baseUrl.isEmpty) return null;

  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  Future<void>? refreshInFlight;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await tokenStore.readAccess();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final isAuthRequest =
            request.path == '/auth/login' || request.path == '/auth/refresh';
        if (error.response?.statusCode != 401 ||
            request.extra['authRetry'] == true ||
            isAuthRequest) {
          handler.next(error);
          return;
        }

        try {
          refreshInFlight ??= auth.refreshSession();
          try {
            await refreshInFlight;
          } finally {
            refreshInFlight = null;
          }

          final renewedAccess = await tokenStore.readAccess();
          if (renewedAccess == null || renewedAccess.isEmpty) {
            throw const FormatException('Token akses baru tidak tersedia.');
          }
          final retryOptions = request
            ..headers['Authorization'] = 'Bearer $renewedAccess'
            ..extra['authRetry'] = true;
          handler.resolve(await dio.fetch<Object?>(retryOptions));
        } on Object catch (refreshError, stackTrace) {
          debugPrint('Session refresh failed: $refreshError\n$stackTrace');
          handler.reject(error);
        }
      },
    ),
  );
  return dio;
}
