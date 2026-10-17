import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

const _retriedAfterRefreshKey = 'retriedAfterRefresh';

Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  String baseUrl = 'https://example-campus-api.test',
  Future<void> Function()? onSessionExpired,
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<void> expireSession() async {
    await store.clear();
    await onSessionExpired?.call();
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = ['Bearer', access].join(' ');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }

        if (error.requestOptions.extra[_retriedAfterRefreshKey] == true) {
          await expireSession();
          handler.next(error);
          return;
        }

        final refresh = await store.readRefresh();
        if (refresh == null || refresh.isEmpty) {
          await expireSession();
          handler.next(error);
          return;
        }

        late final String renewedAccess;
        try {
          renewedAccess = await auth.refresh(refresh);
        } catch (refreshError, stackTrace) {
          await expireSession();
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: refreshError,
              stackTrace: stackTrace,
              message: 'Session refresh failed',
            ),
          );
          return;
        }

        await store.save(access: renewedAccess, refresh: refresh);
        final request = error.requestOptions;
        final retryOptions = request.copyWith(
          headers: {
            ...request.headers,
            'Authorization': ['Bearer', renewedAccess].join(' '),
          },
          extra: {
            ...request.extra,
            _retriedAfterRefreshKey: true,
          },
        );

        try {
          handler.resolve(await dio.fetch<dynamic>(retryOptions));
        } on DioException catch (retryError) {
          handler.reject(retryError);
        }
      },
    ),
  );

  return dio;
}
