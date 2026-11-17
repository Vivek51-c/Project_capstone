import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../core/auth/validators.dart';
import '../../main.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/ui_kit.dart';

/// Reached either via the app's own dev-mode "Open reset screen" shortcut
/// (ForgotPasswordScreen) or via a real deep link
/// `opportunejobmate://reset-password?token=...` / `https://.../reset-password?token=...`
/// -- see README.md ("Deep link configuration") for the platform setup
/// required for the latter.
class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final ApiClient? api;

  const ResetPasswordScreen({super.key, this.token, this.api});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _resolvedToken;
  String? _formError;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.trim().isNotEmpty) {
      _resolvedToken = widget.token!.trim();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedToken == null || _resolvedToken!.isEmpty) {
      _resolvedToken = _resolveToken();
    }
  }

  String? _resolveToken() {
    if (widget.token != null && widget.token!.trim().isNotEmpty) {
      return widget.token!.trim();
    }

    final modalRoute = ModalRoute.of(context);
    final args = modalRoute?.settings.arguments;
    if (args is Map<String, dynamic> && args['token'] is String) {
      final token = (args['token'] as String).trim();
      if (token.isNotEmpty) return token;
    }

    final routeName = modalRoute?.settings.name ?? '';
    final routeUri = Uri.tryParse(routeName);
    final routeToken = routeUri?.queryParameters['token'];
    if (routeToken != null && routeToken.trim().isNotEmpty) {
      return routeToken.trim();
    }

    if (kIsWeb) {
      final base = Uri.base;
      final queryToken = base.queryParameters['token'];
      if (queryToken != null && queryToken.trim().isNotEmpty) {
        return queryToken.trim();
      }
      if (base.hasFragment && base.fragment.isNotEmpty) {
        final frag = base.fragment.startsWith('/') ? base.fragment : '/${base.fragment}';
        final fragUri = Uri.tryParse(frag);
        final fragToken = fragUri?.queryParameters['token'];
        if (fragToken != null && fragToken.trim().isNotEmpty) {
          return fragToken.trim();
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    final token = _resolvedToken ?? _resolveToken();
    if (token == null || token.isEmpty) {
      setState(() => _formError = 'This reset link is missing its token. Please request a new one.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final client = widget.api ?? apiClient;
      await client.resetPassword(
        token: token,
        newPassword: _passwordController.text,
        confirmNewPassword: _confirmController.text,
      );
      if (!mounted) return;
      setState(() => _success = true);
    } on ApiException catch (e) {
      // Surfaces "This password reset link is invalid or has expired." (400)
      // and any 422 validation message verbatim from the backend.
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
                  if (_success) ...[
                    Text('Password reset', style: context.text.headlineMedium, textAlign: TextAlign.center),
                    AppSpacing.gapXs,
                    Text(
                      'Your password has been updated successfully.',
                      style: context.text.titleMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapXl,
                    PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: _buildSuccess(context),
                    ),
                  ] else ...[
                    Text('Choose a new password', style: context.text.headlineMedium, textAlign: TextAlign.center),
                    AppSpacing.gapXs,
                    Text(
                      'Enter and confirm your new password below.',
                      style: context.text.titleMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapXl,
                    PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: _buildForm(context),
                    ),
                  ],
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

  Widget _buildSuccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.success),
        AppSpacing.gapLg,
        Text(
          'You can now log in with your new password. '
          'Any other device you were signed in on has also been signed out.',
          style: context.text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapLg,
        PrimaryButton(
          label: 'Go to login',
          onPressed: () async => Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final token = _resolvedToken ?? _resolveToken();
    final hasToken = token != null && token.isNotEmpty;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasToken)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: InfoBanner(
                message: 'No reset token was found in this link. Please request a new password reset.',
                icon: Icons.link_off_rounded,
                accent: AppColors.warning,
                background: AppColors.warningSurface,
              ),
            ),
          if (_formError != null) ...[
            InfoBanner(
              message: _formError!,
              icon: Icons.error_outline_rounded,
              accent: AppColors.error,
              background: AppColors.errorSurface,
            ),
            AppSpacing.gapMd,
          ],
          AppTextField(
            controller: _passwordController,
            label: 'New password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.password,
            helperText: 'At least 8 characters, with upper/lowercase, a digit, and a symbol.',
          ),
          AppSpacing.gapLg,
          AppTextField(
            controller: _confirmController,
            label: 'Confirm new password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.matches(_passwordController, label: 'Passwords'),
            onFieldSubmitted: (_) => _submit(),
          ),
          AppSpacing.gapLg,
          PrimaryButton(label: 'Reset password', loadingLabel: 'Resetting…', onPressed: _submit),
        ],
      ),
    );
  }
}
