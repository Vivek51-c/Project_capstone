import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_jobmate/core/api_client.dart';
import 'package:opportune_jobmate/core/auth/auth_models.dart';
import 'package:opportune_jobmate/core/auth/session_controller.dart';
import 'package:opportune_jobmate/core/auth/token_storage.dart';
import 'package:opportune_jobmate/screens/auth/auth_gate.dart';
import 'package:opportune_jobmate/screens/auth/login_screen.dart';
import 'package:opportune_jobmate/screens/home_screen.dart';
import 'package:opportune_jobmate/screens/splash_screen.dart';
import 'package:opportune_jobmate/widgets/app_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashScreen renders logo, full title, tagline, and loading indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Verify logo mark
    expect(find.byType(AppLogoMark), findsOneWidget);

    // Verify full app text
    expect(find.text('Opportune JobMate'), findsOneWidget);

    // Verify tagline
    expect(find.text('Your AI-Powered Career Companion'), findsOneWidget);

    // Verify loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading…'), findsOneWidget);

    // Let entrance animation finish (use pump rather than pumpAndSettle
    // because CircularProgressIndicator has an infinite rotation animation).
    await tester.pump(const Duration(milliseconds: 950));
  });

  testWidgets('SplashScreen triggers onComplete callback after animation completes',
      (WidgetTester tester) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          onComplete: () {
            completed = true;
          },
        ),
      ),
    );

    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 950));
    expect(completed, isTrue);
  });

  testWidgets('AuthGate shows SplashScreen on start, then opens LoginScreen if not logged in',
      (WidgetTester tester) async {
    final storage = _MemoryTokenStorage();
    final session = SessionController(api: _FakeApiClient(), storage: storage);

    await tester.pumpWidget(
      SessionScope(
        controller: session,
        child: const MaterialApp(
          home: AuthGate(),
        ),
      ),
    );

    // Initially on start, SplashScreen is visible
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Opportune JobMate'), findsOneWidget);

    // After splash animation & session check complete
    await tester.pumpAndSettle();

    // Navigates to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);

    session.dispose();
  });

  testWidgets('AuthGate shows SplashScreen on start, then opens Dashboard (HomeScreen) if logged in',
      (WidgetTester tester) async {
    final storage = _MemoryTokenStorage()..token = 'existing-valid-token';
    final session = SessionController(api: _FakeApiClient(), storage: storage);

    await tester.pumpWidget(
      SessionScope(
        controller: session,
        child: const MaterialApp(
          home: AuthGate(),
        ),
      ),
    );

    // Initially on start, SplashScreen is visible
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Opportune JobMate'), findsOneWidget);

    // After splash animation & session check complete
    await tester.pumpAndSettle();

    // Navigates to HomeScreen (Dashboard)
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);

    session.dispose();
  });
}

class _FakeApiClient extends ApiClient {
  static final _authUser = AuthUser(
    id: 'test-user',
    fullName: 'Test User',
    email: 'test@example.com',
    isActive: true,
    createdAt: DateTime.utc(2025),
  );

  @override
  Future<AuthUser> getMe({required String token}) async {
    if (token == 'existing-valid-token') {
      return _authUser;
    }
    throw Exception('Invalid token');
  }
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
