import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/token_store.dart';

/// Provider untuk TokenStore
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

/// Provider untuk AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider untuk menyimpan status login
///
/// true  = sudah login
/// false = belum login
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

/// Notifier untuk mengatur proses authentication
class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Membaca access token dari secure storage
    final token = await ref
        .watch(tokenStoreProvider)
        .readAccess();

    // Jika token ada, berarti user sudah login
    return token != null;
  }

  /// Proses login
  Future<void> login(
    String email,
    String password,
  ) async {
    // Mengubah state menjadi loading
    state = const AsyncLoading();

    // Menjalankan proses login dan menangani error
    state = await AsyncValue.guard(() async {
      // Memanggil AuthRepository
      final session = await ref
          .read(authRepositoryProvider)
          .login(
            email: email,
            password: password,
          );

      // Menyimpan access token dan refresh token
      await ref
          .read(tokenStoreProvider)
          .save(
            access: session.access,
            refresh: session.refresh,
          );

      // Login berhasil
      return true;
    });
  }

  /// Proses logout
  Future<void> logout() async {
    // Menghapus semua token
    await ref
        .read(tokenStoreProvider)
        .clear();

    // Memuat ulang status authentication
    ref.invalidateSelf();
  }
}