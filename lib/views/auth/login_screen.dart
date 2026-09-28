import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeFor(auth.user!),
        (_) => false,
      );
    } else {
      showSnack(context, auth.error!, error: true);
    }
  }

  void _register(String role) =>
      Navigator.pushNamed(context, AppRoutes.signup, arguments: role);

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthViewModel>().loading;

    return Scaffold(
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _email,
                          title: 'Email address',
                          label: 'you@example.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          action: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _password,
                          title: 'Password',
                          label: 'Enter your password',
                          icon: Icons.lock_outline,
                          obscure: true,
                          validator: Validators.password,
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.forgot),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  AppButton(
                    label: 'Log in',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _login,
                    loading: loading,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'NEW TO PHARMACY UNIT?',
                          style: TextStyle(
                            fontSize: 11.5,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _RegisterCard(
                    filled: true,
                    icon: Icons.medical_services_rounded,
                    title: 'Doctor / Pharmacist',
                    subtitle:
                        'Order supplies, compare rates, generate invoices',
                    onTap: () => _register(UserRole.user),
                  ),
                  const SizedBox(height: 12),
                  _RegisterCard(
                    filled: false,
                    icon: Icons.local_shipping_rounded,
                    title: 'Supplier',
                    subtitle: 'List your products and reach every clinic',
                    onTap: () => _register(UserRole.supplier),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand header: logo, name, welcome headline and tagline.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 18,
        24,
        26,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -30, child: _ring(140)),
          Positioned(right: 70, bottom: -60, child: _ring(90)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PHARMACY UNIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Log in to manage your supplies and orders',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
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
        width: 16,
      ),
    ),
  );
}

/// Large register option: filled teal gradient or white outlined variant.
class _RegisterCard extends StatelessWidget {
  final bool filled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RegisterCard({
    required this.filled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.textPrimary;
    final sub = filled ? Colors.white70 : AppColors.textSecondary;
    final tint = filled ? AppColors.primary : AppColors.accent;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: filled ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: filled ? null : Border.all(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.white.withValues(alpha: 0.2)
                        : tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: filled ? Colors.white : tint),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register as',
                        style: TextStyle(
                          color: sub,
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          color: fg,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: sub,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: filled ? Colors.white : tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: filled ? AppColors.primaryDark : Colors.white,
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
