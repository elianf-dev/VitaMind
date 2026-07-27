import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/neomorphic_surface.dart';
import '../widgets/vita_mind_card.dart';

enum _AuthMode { welcome, login, signUp }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.authService,
    required this.localStorageService,
  });

  final AuthService authService;
  final LocalStorageService localStorageService;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.welcome;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterApp() async {
    final onboardingCompleted = await widget.localStorageService
        .loadOnboardingCompleted();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacementNamed(onboardingCompleted ? '/dashboard' : '/onboarding');
  }

  Future<void> _submitAuth() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _message = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final error = _mode == _AuthMode.login
        ? await widget.authService.signIn(email: email, password: password)
        : await widget.authService.signUp(email: email, password: password);

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _message = error;
    });

    if (error == null) {
      widget.localStorageService.setProfileId(widget.authService.userId);
      await _enterApp();
    }
  }

  Future<void> _continueAsGuest() async {
    await widget.authService.continueAsGuest();
    widget.localStorageService.setProfileId(null);
    // TODO: Offer an upgrade path that merges guest local storage into Firestore.
    await _enterApp();
  }

  Future<void> _resetPassword() async {
    final error = await widget.authService.sendPasswordResetEmail(
      _emailController.text,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _message =
          error ??
          'Password reset email sent. Check your inbox and spam folder.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 64),
                const Center(
                  child: NeomorphicSurface(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    backgroundColor: AppColors.primarySoft,
                    borderColor: AppColors.primarySoft,
                    radius: 24,
                    shadowStrength: 1.1,
                    child: Icon(
                      Icons.self_improvement,
                      color: AppColors.primary,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'VitaMind',
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Track your mood, symptoms, and wellness habits.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 40),
                VitaMindCard(
                  margin: EdgeInsets.zero,
                  padding: AppSpacing.cardLarge,
                  backgroundColor: AppColors.glassStrong,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _mode == _AuthMode.welcome
                        ? _WelcomeActions(
                            key: const ValueKey('welcome-actions'),
                            onLogin: () =>
                                setState(() => _mode = _AuthMode.login),
                            onSignUp: () =>
                                setState(() => _mode = _AuthMode.signUp),
                            onGuest: _continueAsGuest,
                            signedInEmail: widget.authService.userEmail,
                          )
                        : _AuthForm(
                            key: ValueKey(_mode),
                            mode: _mode,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            loading: _loading,
                            message: _message,
                            firebaseAvailable:
                                widget.authService.firebaseAvailable,
                            onSubmit: _submitAuth,
                            onForgotPassword: _resetPassword,
                            onBack: () {
                              setState(() {
                                _mode = _AuthMode.welcome;
                                _message = null;
                              });
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    required this.onGuest,
    required this.signedInEmail,
  });

  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final VoidCallback onGuest;
  final String? signedInEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (signedInEmail != null) ...[
          Text(
            'Signed in as $signedInEmail',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(onPressed: onLogin, child: const Text('Login')),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onSignUp, child: const Text('Sign Up')),
        const SizedBox(height: 12),
        TextButton(onPressed: onGuest, child: const Text('Continue as Guest')),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    super.key,
    required this.mode,
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.message,
    required this.firebaseAvailable,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onBack,
  });

  final _AuthMode mode;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final String? message;
  final bool firebaseAvailable;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == _AuthMode.login;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isLogin ? 'Login' : 'Create account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        if (!firebaseAvailable) ...[
          const SizedBox(height: 12),
          const _AuthMessage(
            text:
                'Firebase is not configured yet, so email login is disabled in this local build.',
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 12),
          _AuthMessage(text: message!),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isLogin ? Icons.login : Icons.person_add_alt),
          label: Text(isLogin ? 'Login' : 'Sign Up'),
        ),
        const SizedBox(height: 8),
        if (isLogin)
          TextButton(
            onPressed: loading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        TextButton(
          onPressed: loading ? null : onBack,
          child: const Text('Back'),
        ),
      ],
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return NeomorphicSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.warningSurface,
      borderColor: AppColors.warningBorder,
      shadowStrength: 0.45,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6E5A28),
          height: 1.35,
        ),
      ),
    );
  }
}
