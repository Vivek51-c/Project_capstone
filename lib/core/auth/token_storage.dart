import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores ONLY the JWT access token -- never the password, never anything
/// else sensitive.
///
/// Platform behavior:
/// - Android/iOS: backed by Keystore/Keychain.
/// - Web: uses browser storage via flutter_secure_storage. When loaded over
///   an unencrypted IP (e.g. http://10.x.x.x:3000 in local mobile browser testing),
///   the browser's WebCrypto API is unavailable (isSecureContext == false).
///   This class automatically catches storage exceptions and falls back to
///   safe in-memory caching so the app never crashes or hangs on startup.
class TokenStorage {
  static const _tokenKey = 'opportune_auth_access_token';

  final FlutterSecureStorage _storage;
  String? _memoryFallbackToken;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> readToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        _memoryFallbackToken = token;
        return token;
      }
    } catch (e) {
      debugPrint('[TokenStorage] Notice: persistent read unavailable ($e), using memory fallback.');
    }
    return _memoryFallbackToken;
  }

  Future<void> writeToken(String token) async {
    _memoryFallbackToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('[TokenStorage] Notice: persistent write unavailable ($e), stored in memory.');
    }
  }

  Future<void> deleteToken() async {
    _memoryFallbackToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('[TokenStorage] Notice: persistent delete unavailable ($e).');
    }
  }
}
