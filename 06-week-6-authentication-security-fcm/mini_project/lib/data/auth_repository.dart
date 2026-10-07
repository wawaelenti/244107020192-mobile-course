import 'package:dio/dio.dart';

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

class AuthRepository {
  AuthRepository({this.dio});

  final Dio? dio;

  bool get _useMock =>
      const bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!email.contains('@') || password.length < 6) {
        throw const FormatException('Email atau kata sandi tidak valid.');
      }
      return AuthTokens(
        access: 'mock-access-$email',
        refresh: 'mock-refresh-$email',
      );
    }

    final client = dio;
    if (client == null) {
      throw StateError('API_BASE_URL wajib diatur saat USE_MOCK_AUTH=false.');
    }
    final response = await client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseTokens(response.data);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (refreshToken.isEmpty || refreshToken.contains('expired')) {
        throw const FormatException('Refresh token sudah tidak berlaku.');
      }
      return AuthTokens(
        access: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
        refresh: refreshToken,
      );
    }

    final client = dio;
    if (client == null) {
      throw StateError('API_BASE_URL wajib diatur saat USE_MOCK_AUTH=false.');
    }
    final response = await client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _parseTokens(response.data);
  }

  AuthTokens _parseTokens(Map<String, dynamic>? data) {
    final access = data?['accessToken'];
    final refresh = data?['refreshToken'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const FormatException(
        'Respons autentikasi harus berisi accessToken dan refreshToken.',
      );
    }
    return AuthTokens(access: access, refresh: refresh);
  }
}
