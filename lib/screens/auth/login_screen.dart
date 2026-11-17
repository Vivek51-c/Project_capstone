import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../../core/auth/session_controller.dart';
import '../../core/auth/validators.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/ui_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = SessionScope.of(context);
    try {
      await session.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      // AuthGate (wrapping the whole app) reacts to the session change and
      // swaps to HomeScreen on its own -- nothing to navigate here.
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
                  Text('Welcome back', style: context.text.headlineMedium, textAlign: TextAlign.center),
                  AppSpacing.gapXs,
                  Text(
                    'Sign in to continue your job search.',
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
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: AuthValidators.email,
                          ),
                          AppSpacing.gapLg,
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => AuthValidators.required(v, label: 'Password'),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          AppSpacing.gapSm,
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                  ),
                                  const Text('Remember me'),
                                ],
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                          AppSpacing.gapLg,
                          PrimaryButton(label: 'Log in', loadingLabel: 'Signing in…', onPressed: _submit),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text("Don't have an account?", style: context.text.bodyMedium),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
