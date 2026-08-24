import '../core/network/api_client.dart';
import '../models/user.dart';
import 'secure_storage_service.dart';

class AuthService {
  AuthService({required ApiClient client, required SecureStorageService storage})
      : _client = client,
        _storage = storage;

  final ApiClient _client;
  final SecureStorageService _storage;

  Future<AppUser> login({required String email, required String password}) async {
    final dynamic data = await _client.post(
      '/auth/login',
      data: <String, dynamic>{'email': email, 'password': password},
      skipAuth: true,
    );
    final Map<String, dynamic> body =
        Map<String, dynamic>.from(data as Map<dynamic, dynamic>);

    await _storage.saveTokens(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    );

    return AppUser.fromJson(
        Map<String, dynamic>.from(body['user'] as Map<dynamic, dynamic>));
  }

  Future<AppUser> me() async {
    final dynamic data = await _client.get('/users/me');
    return AppUser.fromJson(
        Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }

  Future<void> logout() async {
    final String? refreshToken = await _storage.readRefreshToken();
    try {
      await _client.post(
        '/auth/logout',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
    } catch (_) {
      // A failed server-side revoke must never trap the user inside the app.
    } finally {
      await _storage.clear();
    }
  }

  Future<bool> hasStoredSession() async {
    final String? token = await _storage.readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
