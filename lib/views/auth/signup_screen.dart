import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _org = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _profession = Profession.doctor;
  String? _specialty;
  String? _practice;
  double _experience = 5;
  bool _showChipErrors = false;

  bool get _isSupplier => widget.role == UserRole.supplier;
  bool get _isPharmacist => _profession == Profession.pharmacist;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {})); // strength meter
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _org, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _form.currentState!.validate();
    final chipsOk = _isSupplier || (_specialty != null && _practice != null);
    if (!chipsOk) setState(() => _showChipErrors = true);
    if (!formOk || !chipsOk) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.signUp(
      SignupDraft(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        role: widget.role,
        profession: _isSupplier ? null : _profession,
        organization: _org.text.trim(),
        specialty: _specialty ?? '',
        practiceType: _practice ?? '',
        experience: _isSupplier ? null : _experience.round(),
      ),
    );
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

  /// 0 = empty, 1 = weak, 2 = okay, 3 = strong
  int get _strength {
    final p = _password.text;
    if (p.isEmpty) return 0;
    var s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 9 && RegExp(r'[A-Z]').hasMatch(p) || p.length >= 10) s++;
    if (RegExp(r'\d').hasMatch(p) && RegExp(r'[^\w\s]').hasMatch(p)) s++;
    return s.clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthViewModel>().loading;

    return Scaffold(
      body: Column(
        children: [
          _Header(isSupplier: _isSupplier),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isSupplier) ...[
                      const _Step(1, 'I am a'),
                      Row(
                        children: [
                          for (final p in Profession.all) ...[
                            if (p != Profession.all.first)
                              const SizedBox(width: 12),
                            Expanded(
                              child: _ProfessionCard(
                                profession: p,
                                selected: _profession == p,
                                onTap: () => setState(() {
                                  _profession = p;
                                  _specialty = null;
                                  _practice = null;
                                  _showChipErrors = false;
                                }),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    _Step(_isSupplier ? 1 : 2, 'About you'),
                    AppTextField(
                      controller: _name,
                      label: 'Full name',
                      icon: Icons.person_outline,
                      validator: (v) => Validators.required(v, 'Name'),
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _org,
                      label: _isSupplier
                          ? 'Company name'
                          : (_profession == Profession.doctor
                                ? 'Clinic / hospital'
                                : 'Pharmacy name'),
                      icon: Icons.business_outlined,
                      validator: (v) => Validators.required(v, 'This'),
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    if (!_isSupplier) ...[
                      _Step(
                        3,
                        _isPharmacist
                            ? 'Pharmacy credentials'
                            : 'Medical credentials',
                      ),
                      _ChipGroup(
                        label: _isPharmacist
                            ? 'Qualification'
                            : 'Specialization',
                        options: _isPharmacist
                            ? Professional.pharmacistQualifications
                            : Professional.doctorSpecialties,
                        selected: _specialty,
                        showError: _showChipErrors,
                        onSelected: (v) => setState(() => _specialty = v),
                      ),
                      const SizedBox(height: 18),
                      _ChipGroup(
                        label: _isPharmacist
                            ? 'Pharmacy type'
                            : 'Practice setting',
                        options: _isPharmacist
                            ? Professional.pharmacySettings
                            : Professional.doctorSettings,
                        selected: _practice,
                        showError: _showChipErrors,
                        onSelected: (v) => setState(() => _practice = v),
                      ),
                      const SizedBox(height: 18),
                      _ExperienceSlider(
                        value: _experience,
                        onChanged: (v) => setState(() => _experience = v),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _Step(_isSupplier ? 2 : 4, 'Contact'),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _phone,
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    _Step(_isSupplier ? 3 : 5, 'Security'),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 10),
                    _StrengthMeter(_strength),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirm password',
                      icon: Icons.verified_user_outlined,
                      obscure: true,
                      validator: Validators.confirmPassword(
                        () => _password.text,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Create account',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _submit,
                      loading: loading,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text.rich(
                          TextSpan(
                            text: 'Already have an account?  ',
                            style: TextStyle(color: AppColors.textSecondary),
                            children: [
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact gradient header with role badge, eyebrow and headline.
class _Header extends StatelessWidget {
  final bool isSupplier;
  const _Header({required this.isSupplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        20,
        22,
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
          Positioned(right: -30, top: -10, child: _ring(120)),
          Positioned(right: 60, bottom: -50, child: _ring(80)),
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
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isSupplier
                            ? Icons.local_shipping_rounded
                            : Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isSupplier
                                ? 'Join as a Supplier'
                                : 'Join as a Doctor or Pharmacist',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.15,
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
                                  isSupplier
                                      ? 'Reach every clinic and pharmacy'
                                      : 'Order supplies in a few taps',
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

/// Numbered section label.
class _Step extends StatelessWidget {
  final int number;
  final String title;
  const _Step(this.number, this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

class _ProfessionCard extends StatelessWidget {
  final String profession;
  final bool selected;
  final VoidCallback onTap;

  const _ProfessionCard({
    required this.profession,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDoctor = profession == Profession.doctor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isDoctor
                        ? Icons.medical_services_outlined
                        : Icons.local_pharmacy_outlined,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
                if (selected)
                  const Positioned(
                    right: -6,
                    top: -6,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.success,
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              Formatters.capitalize(profession),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final int level; // 0..3
  const _StrengthMeter(this.level);

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.danger, AppColors.warning, AppColors.success];
    final labels = ['', 'Weak', 'Good', 'Strong'];
    final color = level == 0 ? AppColors.border : colors[level - 1];
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 5,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: i < level ? color : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        SizedBox(
          width: 56,
          child: Text(
            labels[level],
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Labelled group of single-choice chips (required).
class _ChipGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final bool showError;
  final ValueChanged<String> onSelected;

  const _ChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.showError,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final missing = showError && selected == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: AppColors.danger)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              InkWell(
                onTap: () => onSelected(o),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected == o
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected == o
                          ? AppColors.primary
                          : (missing ? AppColors.danger : AppColors.border),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected == o) ...[
                        const Icon(Icons.check, size: 15, color: Colors.white),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        o,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: selected == o
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (missing)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Please choose one',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Years of experience, 0-40.
class _ExperienceSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _ExperienceSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final years = value.round();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Experience',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  years == 0
                      ? 'Just starting'
                      : '$years year${years == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 40,
            divisions: 40,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
