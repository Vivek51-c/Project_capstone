import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Precedence:
/// 1. Explicit `--dart-define=API_BASE_URL=...` first
/// 2. Valid `.env` value second
/// 3. Production Render backend fallback last
///
/// Production default: https://opportune-jobmate-api.onrender.com
const String _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');
const String _dartDefineAppEnv = String.fromEnvironment('APP_ENV');
const String _dartDefineTimeoutSeconds =
    String.fromEnvironment('API_TIMEOUT_SECONDS');

const String defaultProductionBaseUrl =
    'https://opportune-jobmate-api.onrender.com';
const String defaultAppEnv = 'production';
const int defaultTimeoutSeconds = 60; // 60s accommodates Render free-tier cold starts

/// Safely loads `.env` if available without crashing if missing.
Future<void> initEnvironment() async {
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e) {
    debugPrint(
        '[Environment] .env not loaded ($e). Using dart-define / production defaults.');
  }
}

String? _getEnvVar(String key) {
  try {
    if (dotenv.isInitialized) {
      final value = dotenv.maybeGet(key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  } catch (_) {
    // Graceful fallback if dotenv is uninitialized or throws
  }
  return null;
}

String _normalizeUrl(String url) {
  var normalized = url.trim();
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

/// Resolves the backend base URL dynamically.
///
/// 1. Uses explicit `--dart-define=API_BASE_URL=...` when provided.
/// 2. Uses `.env` value when present.
/// 3. Falls back to the deployed production Render backend URL.
String get kApiBaseUrl {
  if (_dartDefineBaseUrl.trim().isNotEmpty) {
    final normalizedDefine = _normalizeUrl(_dartDefineBaseUrl);
    if (normalizedDefine == '/api') return '/api';
    if (!kIsWeb || normalizedDefine != defaultProductionBaseUrl) {
      return normalizedDefine;
    }
  }
  final envUrl = _getEnvVar('API_BASE_URL');
  if (envUrl != null && envUrl.isNotEmpty) {
    final normalizedEnv = _normalizeUrl(envUrl);
    // If explicitly specified as relative proxy
    if (normalizedEnv == '/api') return '/api';
    // If user specified a custom external domain (not the default Render URL)
    if (normalizedEnv != defaultProductionBaseUrl) {
      return normalizedEnv;
    }
  }

  // When running in a web browser, route via '/api' to leverage the reverse-proxy.
  // This completely eliminates browser CORS preflight ('Disallowed CORS origin')
  // both in local browser preview and when deployed on Vercel.
  if (kIsWeb) {
    return '/api';
  }

  return defaultProductionBaseUrl;
}

/// Resolves the application environment mode (e.g., 'production', 'development').
String get kAppEnv {
  if (_dartDefineAppEnv.trim().isNotEmpty) {
    return _dartDefineAppEnv.trim();
  }
  final envVal = _getEnvVar('APP_ENV');
  if (envVal != null && envVal.isNotEmpty) {
    return envVal;
  }
  return defaultAppEnv;
}

/// Resolves the API request timeout in seconds.
int get kApiTimeoutSeconds {
  if (_dartDefineTimeoutSeconds.trim().isNotEmpty) {
    final parsed = int.tryParse(_dartDefineTimeoutSeconds.trim());
    if (parsed != null && parsed > 0) return parsed;
  }
  final envVal = _getEnvVar('API_TIMEOUT_SECONDS');
  if (envVal != null) {
    final parsed = int.tryParse(envVal);
    if (parsed != null && parsed > 0) return parsed;
  }
  return defaultTimeoutSeconds;
}

/// Resolves the API request timeout as a [Duration].
Duration get kApiTimeout => Duration(seconds: kApiTimeoutSeconds);

/// Static configuration namespace exposing all environment settings.
abstract final class ApiConfig {
  static const String defaultBaseUrl = defaultProductionBaseUrl;
  static const String defaultEnvironment = defaultAppEnv;
  static const int defaultTimeoutInSeconds = defaultTimeoutSeconds;

  static String get baseUrl => kApiBaseUrl;
  static String get appEnv => kAppEnv;
  static int get timeoutSeconds => kApiTimeoutSeconds;
  static Duration get timeout => kApiTimeout;

  static Future<void> loadEnvironment() => initEnvironment();
}

/// Thrown for any non-2xx response. `message` is taken from the backend's
/// `{"detail": "..."}` error body (see app.core.exceptions on the FastAPI
/// side) when present, otherwise falls back to a generic message.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
