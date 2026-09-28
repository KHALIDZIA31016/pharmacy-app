import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/ui.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _cooldown = 30;

  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  Timer? _timer;
  bool _sent = false;
  int _seconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _seconds = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.sendResetEmail(_email.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
      _startCooldown();
    } else {
      showSnack(context, auth.error!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthViewModel>().loading;
    return Scaffold(
      body: Column(
        children: [
          _Header(sent: _sent),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _sent
                    ? _SentView(
                        key: const ValueKey('sent'),
                        email: _email.text.trim(),
                        seconds: _seconds,
                        loading: loading,
                        onResend: _submit,
                        onChangeEmail: () => setState(() => _sent = false),
                      )
                    : _FormView(
                        key: const ValueKey('form'),
                        form: _form,
                        email: _email,
                        loading: loading,
                        onSubmit: _submit,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned gradient header with a lock icon that turns into a mail icon.
class _Header extends StatelessWidget {
  final bool sent;
  const _Header({required this.sent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -6, child: _ring(120)),
          Positioned(right: 70, bottom: -56, child: _ring(84)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: Container(
                        key: ValueKey(sent),
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          sent
                              ? Icons.mark_email_read_rounded
                              : Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACCOUNT RECOVERY',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sent ? 'Check your inbox' : 'Reset your password',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.15,
                              letterSpacing: -0.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  sent
                                      ? 'Your reset link is on its way'
                                      : 'It only takes a minute',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ring(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.13),
        width: 14,
      ),
    ),
  );
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> form;
  final TextEditingController email;
  final bool loading;
  final VoidCallback onSubmit;

  const _FormView({
    super.key,
    required this.form,
    required this.email,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forgot your password?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the email you registered with and we will send you a secure link to choose a new password.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 22),
        Form(
          key: form,
          child: AppTextField(
            controller: email,
            title: 'Email address',
            label: 'you@example.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Send reset link',
          icon: Icons.send_rounded,
          onPressed: onSubmit,
          loading: loading,
        ),
        const SizedBox(height: 28),
        const _Steps(),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Back to log in',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// "How it works" mini timeline.
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        Icons.alternate_email_rounded,
        'Enter your email',
        'The one you signed up with',
      ),
      (
        Icons.mark_email_unread_outlined,
        'Open the link',
        'Check your inbox and spam',
      ),
      (Icons.password_rounded, 'Choose a new password', 'Then log in as usual'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW IT WORKS',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            steps[i].$1,
                            size: 17,
                            color: AppColors.primary,
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < steps.length - 1 ? 14 : 0,
                        top: 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            steps[i].$3,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Confirmation after the link has been sent, with a resend cooldown.
class _SentView extends StatelessWidget {
  final String email;
  final int seconds;
  final bool loading;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  const _SentView({
    super.key,
    required this.email,
    required this.seconds,
    required this.loading,
    required this.onResend,
    required this.onChangeEmail,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = seconds <= 0 && !loading;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.success,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),
              const Text(
                'Reset link sent',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'We emailed a password reset link to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Open the email and tap the link. Not there? Check your spam folder.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Back to log in',
          icon: Icons.login_rounded,
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: canResend ? 'Resend link' : 'Resend in ${seconds}s',
          icon: Icons.refresh_rounded,
          outlined: true,
          loading: loading,
          onPressed: canResend ? onResend : null,
        ),
        TextButton(
          onPressed: onChangeEmail,
          child: const Text(
            'Use a different email',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
