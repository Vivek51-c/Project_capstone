import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/api_config.dart';
import 'core/app_colors.dart';
import 'core/app_spacing.dart';
import 'core/app_theme.dart';
import 'core/auth/session_controller.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/job_radar_screen.dart';
import 'screens/job_matcher_screen.dart';
import 'screens/career_match_screen.dart';
import 'screens/skill_bridge_screen.dart';
import 'screens/ats_screen.dart';
import 'screens/resume_builder_screen.dart';
import 'screens/saved_jobs_screen.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

/// Single shared HTTP client for the whole app's lifetime.
final ApiClient apiClient = ApiClient();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables (.env with fallback)
  await initEnvironment();

  // Protect path url strategy initialization against web plugin runtime quirks
  try {
    usePathUrlStrategy();
  } catch (e) {
    debugPrint('[main] URL strategy configuration fallback: $e');
  }

  // Gracefully catch any unhandled framework errors instead of leaving a blank screen
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[PlatformDispatcher Error] $error\n$stack');
    return true; // Prevents crashing the app process
  };

  // Provide a friendly error UI if any widget fails to build
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              AppSpacing.gapMd,
              const Text(
                'Something went wrong loading this screen.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapSm,
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.gapLg,
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload app'),
                onPressed: () {
                  if (kIsWeb) {
                    // ignore: avoid_web_libraries_in_flutter
                    // Safe reload trigger via window
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const OpportuneJobMateApp());
}

class OpportuneJobMateApp extends StatefulWidget {
  const OpportuneJobMateApp({super.key});

  @override
  State<OpportuneJobMateApp> createState() => _OpportuneJobMateAppState();
}

class _OpportuneJobMateAppState extends State<OpportuneJobMateApp> {
  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session = SessionController(api: apiClient);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  static final Map<String, WidgetBuilder> _staticRoutes = {
    '/': (_) => const AuthGate(),
    '/splash': (_) => const SplashScreen(),
    '/login': (_) => const AuthGate(),
    '/signup': (_) => const SignupScreen(),
    '/forgot-password': (_) => const ForgotPasswordScreen(),
    '/profile': (_) => const ProfileScreen(),
    '/job-radar': (_) => const JobRadarScreen(),
    '/job-matcher': (_) => const JobMatcherScreen(),
    '/career-match': (_) => const CareerMatchScreen(),
    '/skill-bridge': (_) => const SkillBridgeScreen(),
    '/ats-tuneup': (_) => const AtsTuneUpScreen(),
    '/resume-builder': (_) => const ResumeBuilderScreen(),
    '/saved-jobs': (_) => const SavedJobsScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: _session,
      child: MaterialApp(
        title: 'Opportune JobMate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routes: _staticRoutes,
        onGenerateInitialRoutes: (String initialRouteName) {
          String routeName = initialRouteName;
          if (kIsWeb) {
            final base = Uri.base;
            if (base.path.startsWith('/reset-password')) {
              routeName = base.path + (base.hasQuery ? '?${base.query}' : '');
            } else if (base.hasFragment && base.fragment.contains('reset-password')) {
              final frag = base.fragment.startsWith('/') ? base.fragment : '/${base.fragment}';
              routeName = frag;
            }
          }

          if (routeName.startsWith('/reset-password')) {
            final uri = Uri.tryParse(routeName);
            final token = uri?.queryParameters['token'];
            return [
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(token: token),
                settings: RouteSettings(name: routeName),
              ),
            ];
          }

          final builder = _staticRoutes[routeName];
          if (builder != null) {
            return [
              MaterialPageRoute(
                builder: builder,
                settings: RouteSettings(name: routeName),
              ),
            ];
          }

          return [
            MaterialPageRoute(
              builder: (_) => const AuthGate(),
              settings: const RouteSettings(name: '/'),
            ),
          ];
        },
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
          return null;
        },
      ),
    );
  }
}
