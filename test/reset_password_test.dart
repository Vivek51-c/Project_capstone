import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_jobmate/core/api_client.dart';
import 'package:opportune_jobmate/core/api_config.dart';
import 'package:opportune_jobmate/screens/auth/reset_password_screen.dart';

class _MockApiClient extends ApiClient {
  String? lastToken;
  String? lastNewPassword;
  String? lastConfirmPassword;
  bool shouldFail = false;
  String failureMessage = 'Reset token is invalid or has expired';

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    lastToken = token;
    lastNewPassword = newPassword;
    lastConfirmPassword = confirmNewPassword;
    if (shouldFail) {
      throw ApiException(400, failureMessage);
    }
    return 'Password has been reset successfully. You can now log in.';
  }
}

void main() {
  testWidgets('ResetPasswordScreen displays warning banner when no token is provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResetPasswordScreen(),
      ),
    );

    expect(find.text('Choose a new password'), findsOneWidget);
    expect(
      find.text('No reset token was found in this link. Please request a new password reset.'),
      findsOneWidget,
    );
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Confirm new password'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });

  testWidgets('ResetPasswordScreen submits successfully with matching passwords and token',
      (WidgetTester tester) async {
    final mockApi = _MockApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          token: 'TEST_TOKEN_123',
          api: mockApi,
        ),
      ),
    );

    // Warning banner should NOT be displayed when token is present
    expect(
      find.text('No reset token was found in this link. Please request a new password reset.'),
      findsNothing,
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'NewSecretPass1!');
    await tester.enterText(fields.at(1), 'NewSecretPass1!');

    await tester.ensureVisible(find.text('Reset password'));
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();

    expect(mockApi.lastToken, 'TEST_TOKEN_123');
    expect(mockApi.lastNewPassword, 'NewSecretPass1!');
    expect(mockApi.lastConfirmPassword, 'NewSecretPass1!');
    expect(find.text('Password reset'), findsOneWidget);
    expect(find.text('Go to login'), findsOneWidget);
  });

  testWidgets('ResetPasswordScreen shows error banner when backend returns invalid/expired token error',
      (WidgetTester tester) async {
    final mockApi = _MockApiClient()..shouldFail = true;

    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          token: 'EXPIRED_TOKEN',
          api: mockApi,
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NewSecretPass1!');
    await tester.enterText(fields.at(1), 'NewSecretPass1!');

    await tester.ensureVisible(find.text('Reset password'));
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();

    expect(find.text('Reset token is invalid or has expired'), findsOneWidget);
  });

  testWidgets('Routing extracts query parameter token and opens ResetPasswordScreen',
      (WidgetTester tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        onGenerateRoute: (settings) {
          final name = settings.name ?? '';
          if (name.startsWith('/reset-password')) {
            final uri = Uri.tryParse(name);
            final args = settings.arguments as Map<String, dynamic>?;
            final token = uri?.queryParameters['token'] ?? args?['token'] as String?;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(token: token),
              settings: settings,
            );
          }
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Home')));
        },
        home: const Scaffold(body: Text('Home')),
      ),
    );
    navKey.currentState!.pushNamed('/reset-password?token=EXTRACTED_QUERY_TOKEN');
    await tester.pumpAndSettle();

    expect(find.text('Choose a new password'), findsOneWidget);
    // Should NOT show missing token warning because token was extracted
    expect(
      find.text('No reset token was found in this link. Please request a new password reset.'),
      findsNothing,
    );
  });
}
