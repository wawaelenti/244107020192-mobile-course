import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/providers/auth_provider.dart';

void main() {
  group('routeFromMessage', () {
    test('mengembalikan / jika route tidak tersedia', () {
      final result = routeFromMessage({});

      expect(result, '/');
    });

    test('menambahkan / jika route tidak diawali slash', () {
      final result = routeFromMessage({
        'route': 'pengumuman/3',
      });

      expect(result, '/pengumuman/3');
    });

    test('mempertahankan route yang sudah diawali slash', () {
      final result = routeFromMessage({
        'route': '/pengumuman/3',
      });

      expect(result, '/pengumuman/3');
    });

    test('mengubah route menjadi string jika bukan String', () {
      final result = routeFromMessage({
        'route': 123,
      });

      expect(result, '/123');
    });
  });

  group('apiErrorMessage', () {
    test('401 menghasilkan pesan sesi berakhir', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/login',
        ),
        response: Response(
          requestOptions: RequestOptions(
            path: '/login',
          ),
          statusCode: 401,
        ),
      );

      expect(
        apiErrorMessage(error),
        'Sesi kamu sudah berakhir. Silakan login kembali.',
      );
    });

    test('timeout menghasilkan pesan koneksi terlalu lama', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/login',
        ),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        apiErrorMessage(error),
        'Koneksi ke server terlalu lama. Silakan coba lagi.',
      );
    });

    test('connection error menghasilkan pesan offline', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/login',
        ),
        type: DioExceptionType.connectionError,
      );

      expect(
        apiErrorMessage(error),
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    });
  });

  group('AuthNotifier', () {
    test('status login false jika access token tidak ada', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(
            FakeTokenStore(),
          ),
        ],
      );

      addTearDown(container.dispose);

      final result = await container.read(
        authStateProvider.future,
      );

      expect(result, false);
    });

    test('status login true jika access token tersedia', () async {
      final fakeTokenStore = FakeTokenStore();

      await fakeTokenStore.save(
        access: 'access-token',
        refresh: 'refresh-token',
      );

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(
            fakeTokenStore,
          ),
        ],
      );

      addTearDown(container.dispose);

      final result = await container.read(
        authStateProvider.future,
      );

      expect(result, true);
    });
  });
}

class FakeTokenStore extends TokenStore {
  String? _access;
  String? _refresh;

  @override
  Future<void> save({
    required String access,
    required String refresh,
  }) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<String?> readAccess() async {
    return _access;
  }

  @override
  Future<String?> readRefresh() async {
    return _refresh;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}