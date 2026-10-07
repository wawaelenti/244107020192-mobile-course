import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project/data/auth_controller.dart';
import 'package:mini_project/data/auth_repository.dart';
import 'package:mini_project/data/token_store.dart';
import 'package:mini_project/messaging/route_parser.dart';

void main() {
  group('notificationRouteFromData', () {
    test('mengubah ID payload menjadi route detail', () {
      expect(
        notificationRouteFromData({'id': 'kampus-42'}),
        '/pengumuman/kampus-42',
      );
    });

    test('menolak route di luar halaman pengumuman', () {
      expect(
        notificationRouteFromData({'route': 'https://evil.test/login'}),
        isNull,
      );
    });
  });

  group('AuthController refresh/session', () {
    test('refresh berhasil memperbarui access token dan sesi tetap aktif',
        () async {
      final store = FakeTokenStore()
        ..access = 'old-access'
        ..refresh = 'valid-refresh';
      final auth = AuthController(
        tokenStore: store,
        repository: FakeAuthRepository(),
      );
      await auth.initialize();

      await auth.refreshSession();

      expect(auth.isAuthenticated, isTrue);
      expect(store.access, 'new-access');
      expect(store.refresh, 'rotated-refresh');
    });

    test('refresh yang ditolak menghapus token dan mengakhiri sesi', () async {
      final store = FakeTokenStore()
        ..access = 'old-access'
        ..refresh = 'expired-refresh';
      final auth = AuthController(
        tokenStore: store,
        repository: FakeAuthRepository(rejectRefresh: true),
      );
      await auth.initialize();

      await expectLater(auth.refreshSession(), throwsFormatException);

      expect(auth.isAuthenticated, isFalse);
      expect(store.access, isNull);
      expect(store.refresh, isNull);
    });
  });
}

class FakeTokenStore extends TokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> save({
    required String access,
    required String refresh,
  }) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.rejectRefresh = false});

  final bool rejectRefresh;

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    if (rejectRefresh) {
      throw const FormatException('Refresh token sudah tidak berlaku.');
    }
    return const AuthTokens(
      access: 'new-access',
      refresh: 'rotated-refresh',
    );
  }
}
