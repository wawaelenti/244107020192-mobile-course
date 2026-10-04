import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://example-campus-api.test',
  );
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 ||
            error.requestOptions.extra['authRetry'] == true) {
          handler.next(error);
          return;
        }

        final refresh = await store.readRefresh();
        if (refresh == null) {
          handler.next(error);
          return;
        }

        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          final retryOptions = error.requestOptions
            ..headers['Authorization'] = 'Bearer $renewed'
            ..extra['authRetry'] = true;
          final retry = await dio.fetch<Object?>(retryOptions);
          handler.resolve(retry);
        } on DioException catch (refreshError) {
          await store.clear();
          handler.reject(refreshError);
        } catch (refreshError) {
          await store.clear();
          debugPrint(
            'Authentication token refresh failed '
            '(${refreshError.runtimeType}); session cleared.',
          );
          handler.next(error);
        }
      },
    ),
  );

  return dio;
}
