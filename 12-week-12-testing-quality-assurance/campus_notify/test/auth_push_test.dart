import 'dart:io';

import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HttpServer? server;

  Future<void> startServer(
    Future<void> Function(HttpRequest request) handleRequest,
  ) async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen(handleRequest);
  }

  String serverBaseUrl() => 'http://${server!.address.address}:${server!.port}';

  tearDown(() async {
    await server?.close(force: true);
  });

  test(
    'routeFromMessage defaults empty routes and normalizes relative routes',
    () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': ''}), '/');
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    },
  );

  test('API errors map unauthorized responses to a login prompt', () {
    final request = RequestOptions(path: '/private');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 401),
    );

    expect(apiErrorMessage(error), 'Sesi berakhir. Silakan login kembali.');
  });

  test('API errors map timeout and connection failures clearly', () {
    final request = RequestOptions(path: '/');
    final timeoutTypes = [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ];

    for (final type in timeoutTypes) {
      expect(
        apiErrorMessage(DioException(requestOptions: request, type: type)),
        'Koneksi timeout. Silakan coba lagi.',
      );
    }

    expect(
      apiErrorMessage(
        DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        ),
      ),
      'Tidak dapat terhubung ke server. Periksa koneksi internet.',
    );
  });

  test('API errors use a safe fallback for other failures', () {
    expect(
      apiErrorMessage(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.unknown,
        ),
      ),
      'Terjadi kesalahan. Silakan coba lagi.',
    );
  });

  test(
    'API client retries one unauthorized request with refreshed access',
    () async {
      final store = _MemoryTokenStore(
        access: 'old-access',
        refresh: 'refresh-token',
      );
      final auth = _FakeAuthRepository((refreshToken) async {
        expect(refreshToken, 'refresh-token');
        return 'new-access';
      });
      final authorizationHeaders = <String?>[];
      var requestCount = 0;

      await startServer((request) async {
        authorizationHeaders.add(request.headers.value('authorization'));
        requestCount++;
        request.response.statusCode = requestCount == 1 ? 401 : 200;
        request.response.write('{}');
        await request.response.close();
      });

      final client = buildApiClient(store, auth, baseUrl: serverBaseUrl());
      final response = await client.get<dynamic>('/private');

      expect(response.statusCode, 200);
      expect(requestCount, 2);
      expect(authorizationHeaders, hasLength(2));
      expect(authorizationHeaders[0]?.endsWith('old-access'), isTrue);
      expect(authorizationHeaders[1]?.endsWith('new-access'), isTrue);
      expect(auth.refreshCalls, 1);
      expect(store.access, 'new-access');
      expect(store.refresh, 'refresh-token');
    },
  );

  test('failed token refresh clears the saved session', () async {
    final store = _MemoryTokenStore(
      access: 'old-access',
      refresh: 'expired-refresh',
    );
    final auth = _FakeAuthRepository((_) async {
      throw StateError('Refresh token expired');
    });
    var requestCount = 0;
    var sessionExpiredCount = 0;

    await startServer((request) async {
      requestCount++;
      request.response.statusCode = 401;
      await request.response.close();
    });

    final client = buildApiClient(
      store,
      auth,
      baseUrl: serverBaseUrl(),
      onSessionExpired: () async {
        sessionExpiredCount++;
      },
    );

    await expectLater(
      client.get<dynamic>('/private'),
      throwsA(isA<DioException>()),
    );

    expect(requestCount, 1);
    expect(auth.refreshCalls, 1);
    expect(store.access, isNull);
    expect(store.refresh, isNull);
    expect(sessionExpiredCount, 1);
  });

  test('a retried 401 clears the session without refreshing again', () async {
    final store = _MemoryTokenStore(
      access: 'old-access',
      refresh: 'refresh-token',
    );
    final auth = _FakeAuthRepository((_) async => 'new-access');
    var requestCount = 0;
    var sessionExpiredCount = 0;

    await startServer((request) async {
      requestCount++;
      request.response.statusCode = 401;
      await request.response.close();
    });

    final client = buildApiClient(
      store,
      auth,
      baseUrl: serverBaseUrl(),
      onSessionExpired: () async {
        sessionExpiredCount++;
      },
    );

    await expectLater(
      client.get<dynamic>('/private'),
      throwsA(isA<DioException>()),
    );

    expect(requestCount, 2);
    expect(auth.refreshCalls, 1);
    expect(store.access, isNull);
    expect(store.refresh, isNull);
    expect(sessionExpiredCount, 1);
  });

  test(
    'provider session expiration changes authenticated state to false',
    () async {
      final store = _MemoryTokenStore(
        access: 'old-access',
        refresh: 'expired-refresh',
      );
      final auth = _FakeAuthRepository((_) async {
        throw StateError('Refresh token expired');
      });
      var requestCount = 0;

      await startServer((request) async {
        requestCount++;
        request.response.statusCode = 401;
        await request.response.close();
      });

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(auth),
          apiBaseUrlProvider.overrideWithValue(serverBaseUrl()),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(authStateProvider.future), isTrue);

      await expectLater(
        container.read(apiClientProvider).get<dynamic>('/private'),
        throwsA(isA<DioException>()),
      );

      expect(requestCount, 1);
      expect(container.read(authStateProvider).value, isFalse);
      expect(store.access, isNull);
      expect(store.refresh, isNull);
    },
  );
}

class _MemoryTokenStore extends TokenStore {
  _MemoryTokenStore({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this.refreshToken);

  final Future<String> Function(String refreshToken) refreshToken;
  var refreshCalls = 0;

  @override
  Future<String> refresh(String token) {
    refreshCalls++;
    return refreshToken(token);
  }
}
