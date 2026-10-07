import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.tokenStore,
    required this.repository,
  });

  final TokenStore tokenStore;
  final AuthRepository repository;

  bool _isReady = false;
  bool _isAuthenticated = false;
  bool _isBusy = false;
  String? _error;

  bool get isReady => _isReady;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBusy => _isBusy;
  String? get error => _error;

  Future<void> initialize() async {
    _isAuthenticated = (await tokenStore.readAccess()) != null;
    _isReady = true;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      final tokens = await repository.login(
        email: email,
        password: password,
      );
      await tokenStore.save(
        access: tokens.access,
        refresh: tokens.refresh,
      );
      _isAuthenticated = true;
    } catch (error) {
      _error = error.toString().replaceFirst('FormatException: ', '');
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshSession() async {
    final refresh = await tokenStore.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await expireSession();
      throw const FormatException('Refresh token tidak tersedia.');
    }
    try {
      final tokens = await repository.refresh(refresh);
      await tokenStore.save(
        access: tokens.access,
        refresh: tokens.refresh,
      );
    } catch (error) {
      final refreshRejected = error is FormatException ||
          (error is DioException &&
              (error.response?.statusCode == 401 ||
                  error.response?.statusCode == 403));
      if (refreshRejected) await expireSession();
      rethrow;
    }
  }

  Future<void> expireSession() async {
    await tokenStore.clear();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> signOut() => expireSession();
}
