import 'package:flutter/material.dart';

import '../../core/auth/session_controller.dart';
import '../home_screen.dart';
import '../splash_screen.dart';
import 'login_screen.dart';

/// App root: shows the professional SplashScreen on app startup while restoring
/// any existing session (reading the stored token and validating it against GET /auth/me),
/// then swaps between HomeScreen (Dashboard) and LoginScreen automatically.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _restoreStarted = false;
  bool _animationCompleted = false;

  void _onSplashComplete() {
    if (mounted && !_animationCompleted) {
      setState(() {
        _animationCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    if (!_restoreStarted) {
      _restoreStarted = true;
      // Deferred to after this build so SessionScope's InheritedNotifier
      // is fully in the tree before the resulting notifyListeners() fires.
      WidgetsBinding.instance.addPostFrameCallback((_) => session.restore());
    }

    // Keep displaying the splash screen until its short smooth entrance
    // animation finishes and the initial session status is resolved.
    if (!_animationCompleted || session.status == SessionStatus.unknown) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    switch (session.status) {
      case SessionStatus.authenticated:
        return const HomeScreen();
      case SessionStatus.unauthenticated:
        return const LoginScreen();
      case SessionStatus.unknown:
        return SplashScreen(onComplete: _onSplashComplete);
    }
  }
}

