import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../../core/auth/validators.dart';
import '../../main.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/ui_kit.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _formError;
  String? _successMessage;
  String? _devResetLink; // dev-only, see note in build()

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _successMessage = null;
      _devResetLink = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      // apiClient is the single shared instance from main.dart. forgotPassword
      // doesn't need a session/token, so we call it directly.
      final (message, devLink) = await apiClient.forgotPassword(_emailController.text.trim());
      setState(() {
        _successMessage = message;
        // The backend only ever returns dev_reset_link outside production
        // with no SMTP configured. We additionally gate on kReleaseMode
        // here so a release build never renders this even if pointed at a
        // misconfigured dev backend by mistake.
        _devResetLink = kReleaseMode ? null : devLink;
      });
    } on ApiException catch (e) {
      setState(() => _formError = e.message);
    } catch (e) {
      setState(() => _formError = "Couldn't reach the server. Check your connection and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppWordmark(logoSize: 44, showTagline: false)),
                  AppSpacing.gapLg,
                  Text('Reset your password', style: context.text.headlineMedium, textAlign: TextAlign.center),
                  AppSpacing.gapXs,
                  Text(
                    "Enter your account email and we'll send you a link to reset your password.",
                    style: context.text.titleMedium?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapXl,
                  PremiumCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_formError != null) ...[
                            InfoBanner(
                              message: _formError!,
                              icon: Icons.error_outline_rounded,
                              accent: AppColors.error,
                              background: AppColors.errorSurface,
                            ),
                            AppSpacing.gapMd,
                          ],
                          if (_successMessage != null) ...[
                            InfoBanner(
                              message: _successMessage!,
                              icon: Icons.mark_email_read_outlined,
                              accent: AppColors.success,
                              background: AppColors.successSurface,
                            ),
                            AppSpacing.gapMd,
                            if (_devResetLink != null)
                              InfoBanner(
                                message:
                                    'DEVELOPMENT ONLY -- this link is only shown because the backend '
                                    'has no email provider configured. It will never appear in a '
                                    'production build.\n\n$_devResetLink',
                                icon: Icons.developer_mode_rounded,
                                accent: AppColors.warning,
                                background: AppColors.warningSurface,
                                actionLabel: 'Open reset screen',
                                onAction: () => _openDevLink(context, _devResetLink!),
                              ),
                            AppSpacing.gapMd,
                          ],
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: AuthValidators.email,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          AppSpacing.gapLg,
                          PrimaryButton(label: 'Send reset link', loadingLabel: 'Sending…', onPressed: _submit),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Back to login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDevLink(BuildContext context, String link) {
    // Dev convenience only: extract the token and jump straight to the
    // Reset Password screen, mirroring what tapping the emailed link would
    // do via the app's deep link handling (see README for the real config).
    final uri = Uri.tryParse(link);
    final token = uri?.queryParameters['token'];
    if (token == null || token.isEmpty) return;
    final encodedToken = Uri.encodeComponent(token);
    Navigator.pushReplacementNamed(
      context,
      '/reset-password?token=$encodedToken',
      arguments: {'token': token},
    );
  }
}
