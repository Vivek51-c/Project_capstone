import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../../core/auth/session_controller.dart';
import '../../core/auth/validators.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/ui_kit.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _acceptedTerms = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;
    if (!_acceptedTerms) {
      setState(() => _formError =
          'You must accept the Terms and Privacy Policy to sign up.');
      return;
    }

    final session = SessionScope.of(context);
    try {
      await session.signup(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
        acceptedTerms: _acceptedTerms,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Account created successfully. Please login.')),
      );
    } on ApiException catch (e) {
      // Surfaces "An account with this email already exists." (409) and
      // any 422 validation message verbatim from the backend.
      setState(() => _formError = e.message);
    } catch (e) {
      setState(() => _formError =
          "Couldn't reach the server. Check your connection and try again.");
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
                  const Center(
                      child: AppWordmark(logoSize: 44, showTagline: false)),
                  AppSpacing.gapLg,
                  Text('Join Opportune JobMate',
                      style: context.text.headlineMedium,
                      textAlign: TextAlign.center),
                  AppSpacing.gapXs,
                  Text(
                    'Create your account to save your progress across every tool.',
                    style: context.text.titleMedium
                        ?.copyWith(color: AppColors.textSecondary),
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
                            controller: _nameController,
                            label: 'Full name',
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: AuthValidators.fullName,
                          ),
                          AppSpacing.gapLg,
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
                            textInputAction: TextInputAction.next,
                            validator: AuthValidators.password,
                            helperText:
                                'At least 8 characters, with upper/lowercase, a digit, and a symbol.',
                          ),
                          AppSpacing.gapLg,
                          AppTextField(
                            controller: _confirmController,
                            label: 'Confirm password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            validator: AuthValidators.matches(
                                _passwordController,
                                label: 'Passwords'),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          AppSpacing.gapSm,
                          InkWell(
                            onTap: () => setState(
                                () => _acceptedTerms = !_acceptedTerms),
                            borderRadius: AppRadius.brSm,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (v) => setState(
                                        () => _acceptedTerms = v ?? false),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Text(
                                        'I agree to the Terms of Service and Privacy Policy.',
                                        style: context.text.bodySmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapLg,
                          PrimaryButton(
                            label: 'Create account',
                            loadingLabel: 'Creating account…',
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style: context.text.bodyMedium),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('Log in'),
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
