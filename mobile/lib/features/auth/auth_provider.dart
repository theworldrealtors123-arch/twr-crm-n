import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _errorMessage;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _busy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Called on splash: restores a session from secure storage when possible.
  Future<void> bootstrap() async {
    final bool hasSession = await _authService.hasStoredSession();
    if (!hasSession) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _authService.me();
      _status = AuthStatus.authenticated;
    } on ApiException {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email.trim(), password: password);
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = AuthStatus.unauthenticated;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to connect. Please try again.';
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Invoked by the API client when a refresh attempt fails.
  void onSessionExpired() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Your session has expired. Please log in again.';
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
