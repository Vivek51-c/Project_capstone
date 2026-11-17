import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api_client.dart';
import 'auth_models.dart';
import 'token_storage.dart';

enum SessionStatus {
  /// Still checking secure storage / calling GET /auth/me for a restored
  /// session -- show a splash, don't route anywhere yet.
  unknown,
  authenticated,
  unauthenticated,
}

/// Single source of truth for "is anyone signed in, and as whom".
///
/// Owns the JWT (in memory + secure storage) and the current AuthUser.
/// Every screen that needs the token or the user reads it from here via
/// SessionScope (see main.dart) rather than re-implementing storage/API
/// calls itself.
class SessionController extends ChangeNotifier {
  final ApiClient _api;
  final TokenStorage _storage;

  SessionController({required ApiClient api, TokenStorage? storage})
      : _api = api,
        _storage = storage ?? TokenStorage();

  SessionStatus _status = SessionStatus.unknown;
  AuthUser? _user;
  String? _token;

  SessionStatus get status => _status;
  AuthUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated =>
      _status == SessionStatus.authenticated && _token != null;

  /// Call once at app launch. Reads any stored token and validates it
  /// against the real backend (GET /auth/me) -- a token that's expired,
  /// revoked (see backend token_version), or otherwise invalid results in
  /// it being cleared and the user routed to Login, never a silent
  /// "logged in with stale data" state.
  Future<void> restore() async {
    try {
      final storedToken = await _storage
          .readToken()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      if (storedToken == null || storedToken.isEmpty) {
        _status = SessionStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _token = storedToken;
      try {
        _user = await _api
            .getMe(token: storedToken)
            .timeout(const Duration(seconds: 4));
        _status = SessionStatus.authenticated;
      } catch (_) {
        await _storage.deleteToken();
        _token = null;
        _user = null;
        _status = SessionStatus.unauthenticated;
      }
    } catch (_) {
      _token = null;
      _user = null;
      _status = SessionStatus.unauthenticated;
    } finally {
      if (_status == SessionStatus.unknown) {
        _status = SessionStatus.unauthenticated;
      }
      notifyListeners();
    }
  }

  Future<void> _applyAuthResult(AuthResult result) async {
    _token = result.accessToken;
    _user = result.user;
    await _storage.writeToken(result.accessToken);
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  Future<void> login(
      {required String email,
      required String password,
      bool rememberMe = false}) async {
    final result = await _api.login(
        email: email, password: password, rememberMe: rememberMe);
    await _applyAuthResult(result);
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async {
    await _api.signup(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      acceptedTerms: acceptedTerms,
    );
    await _storage.deleteToken();
    _token = null;
    _user = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }

  /// Changing password rotates the token (backend invalidates every prior
  /// one) -- store the fresh token so this device stays signed in.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final currentToken = _token;
    if (currentToken == null) {
      throw StateError('changePassword called with no active session.');
    }
    final result = await _api.changePassword(
      token: currentToken,
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
    await _applyAuthResult(result);
  }

  /// Re-fetches the user from the backend (e.g. after editing the profile's
  /// full name, since that field lives on User, not Profile).
  Future<void> refreshUser() async {
    final currentToken = _token;
    if (currentToken == null) return;
    _user = await _api.getMe(token: currentToken);
    notifyListeners();
  }

  Future<void> logout() async {
    final currentToken = _token;
    await _storage.deleteToken();
    _token = null;
    _user = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();

    if (currentToken != null) {
      unawaited(_api.logout(token: currentToken).catchError((Object _) {}));
    }
  }

  /// Called when any authenticated API call comes back 401 mid-session
  /// (e.g. the token was revoked by a password change on another device).
  /// Clears local state without attempting the (now-invalid) /auth/logout
  /// call.
  Future<void> forceSignOut() async {
    await _storage.deleteToken();
    _token = null;
    _user = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }
}

/// Makes the single app-wide [SessionController] available to any
/// descendant via `SessionScope.of(context)`, and rebuilds descendants
/// that read it when the session changes (login/logout/user update).
class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope(
      {super.key, required SessionController controller, required super.child})
      : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null,
        'SessionScope.of() called with no SessionScope ancestor.');
    return scope!.notifier!;
  }
}
