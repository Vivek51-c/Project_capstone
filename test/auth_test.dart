import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_jobmate/core/api_client.dart';
import 'package:opportune_jobmate/core/auth/auth_models.dart';
import 'package:opportune_jobmate/core/auth/session_controller.dart';
import 'package:opportune_jobmate/core/auth/token_storage.dart';
import 'package:opportune_jobmate/screens/auth/auth_gate.dart';
import 'package:opportune_jobmate/screens/auth/login_screen.dart';
import 'package:opportune_jobmate/screens/auth/signup_screen.dart';
import 'package:opportune_jobmate/screens/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LoginScreen renders required fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('signup returns to login and login opens the dashboard',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final session = SessionController(
      api: _FakeApiClient(),
      storage: _MemoryTokenStorage(),
    );

    await tester.pumpWidget(
      SessionScope(
        controller: session,
        child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (_) => const AuthGate(),
            '/login': (_) => const AuthGate(),
            '/signup': (_) => const SignupScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    final signupFields = find.byType(TextFormField);
    await tester.enterText(signupFields.at(0), 'Test User');
    await tester.enterText(signupFields.at(1), 'test@example.com');
    await tester.enterText(signupFields.at(2), 'Password1!');
    await tester.enterText(signupFields.at(3), 'Password1!');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Account created successfully. Please login.'),
      findsOneWidget,
    );

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'test@example.com');
    await tester.enterText(loginFields.at(1), 'Password1!');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  test('signup does not persist or activate the returned token', () async {
    final storage = _MemoryTokenStorage()..token = 'previous-token';
    final session = SessionController(api: _FakeApiClient(), storage: storage);

    await session.signup(
      fullName: 'Test User',
      email: 'test@example.com',
      password: 'Password1!',
      confirmPassword: 'Password1!',
      acceptedTerms: true,
    );

    expect(session.status, SessionStatus.unauthenticated);
    expect(session.token, isNull);
    expect(session.user, isNull);
    expect(storage.token, isNull);
    session.dispose();
  });

  test('login persists a session and logout clears it across app restore',
      () async {
    final storage = _MemoryTokenStorage();
    final session = SessionController(api: _FakeApiClient(), storage: storage);

    await session.login(email: 'test@example.com', password: 'Password1!');
    expect(session.status, SessionStatus.authenticated);
    expect(storage.token, 'test-token');

    await session.logout();
    expect(session.status, SessionStatus.unauthenticated);
    expect(session.token, isNull);
    expect(storage.token, isNull);

    final restoredSession = SessionController(
      api: _FakeApiClient(),
      storage: storage,
    );
    await restoredSession.restore();
    expect(restoredSession.status, SessionStatus.unauthenticated);

    session.dispose();
    restoredSession.dispose();
  });

  test('TokenStorage falls back to memory cache when underlying storage throws', () async {
    final storage = TokenStorage(storage: const _ThrowingSecureStorage());
    // Initially null
    expect(await storage.readToken(), isNull);

    // Writing does not crash and updates fallback
    await storage.writeToken('fallback-token-abc');
    expect(await storage.readToken(), equals('fallback-token-abc'));

    // Deleting clears fallback
    await storage.deleteToken();
    expect(await storage.readToken(), isNull);
  });

  test('SessionController.restore handles storage exceptions without blocking or throwing', () async {
    final session = SessionController(
      api: _FakeApiClient(),
      storage: TokenStorage(storage: const _ThrowingSecureStorage()),
    );

    expect(session.status, equals(SessionStatus.unknown));
    await session.restore();
    expect(session.status, equals(SessionStatus.unauthenticated));
    expect(session.isAuthenticated, isFalse);
    session.dispose();
  });
}

class _FakeApiClient extends ApiClient {
  static final _result = AuthResult(
    accessToken: 'test-token',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: AuthUser(
      id: 'test-user',
      fullName: 'Test User',
      email: 'test@example.com',
      isActive: true,
      createdAt: DateTime.utc(2025),
    ),
  );

  @override
  Future<AuthResult> signup({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async =>
      _result;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async =>
      _result;

  @override
  Future<void> logout({required String token}) async {}
}

class _MemoryTokenStorage extends TokenStorage {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('WebCrypto subtle is undefined in insecure context');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('WebCrypto subtle is undefined in insecure context');
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('WebCrypto subtle is undefined in insecure context');
  }
}
