import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui.dart';
import '../../core/utils/validators.dart';
import '../../data/models/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/nav_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../viewmodels/user_home_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/logout_dialog.dart';
import '../supplier/signature_screen.dart';
import 'notifications_screen.dart';

/// Logged-in user's own profile (last tab for both roles, also admin).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showLogoutDialog(
      context,
      name: context.read<AuthViewModel>().user?.name,
    );
    if (!ok || !context.mounted) return;
    final auth = context.read<AuthViewModel>();
    final nav = context.read<NavViewModel>();
    final notifications = context.read<NotificationViewModel>();
    await auth.logout();
    nav.reset();
    notifications.clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  Future<void> _edit(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final u = auth.user!;
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: u.name);
    final phone = TextEditingController(text: u.phone);
    final org = TextEditingController(text: u.organization);
    final address = TextEditingController(text: u.address);
    final about = TextEditingController(text: u.about);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: name,
                  label: 'Full name',
                  icon: Icons.person_outline,
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: phone,
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: org,
                  label: u.isSupplier ? 'Company' : 'Clinic / pharmacy',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: address,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: about,
                  label: 'About',
                  icon: Icons.info_outline,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Save changes',
                  onPressed: () {
                    if (key.currentState!.validate()) Navigator.pop(ctx, true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      await auth.updateProfile(
        name: name.text.trim(),
        phone: phone.text.trim(),
        organization: org.text.trim(),
        address: address.text.trim(),
        about: about.text.trim(),
      );
      if (context.mounted) showSnack(context, 'Profile updated');
    }
    for (final c in [name, phone, org, address, about]) {
      c.dispose();
    }
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final result = await chooseImage(
      context,
      canRemove: auth.user?.photoPath != null,
    );
    if (result == null) return;
    await auth.updatePhoto(result.isEmpty ? null : result);
    if (context.mounted) {
      showSnack(
        context,
        result.isEmpty ? 'Profile photo removed' : 'Profile photo updated',
      );
    }
  }

  /// Role-specific numbers shown under the header.
  List<(String, String)> _stats(BuildContext context, AppUser u) {
    if (u.isAdmin) return const [];
    if (u.isSupplier) {
      final vm = context.watch<SupplierViewModel>();
      return [
        ('${vm.orders.length}', 'Orders'),
        ('${vm.deliveredCount}', 'Delivered'),
        (Formatters.money(vm.revenue), 'Revenue'),
      ];
    }
    final vm = context.watch<UserHomeViewModel>();
    return [
      ('${vm.orders.length}', 'Orders'),
      ('${vm.orders.where((o) => o.isDelivered).length}', 'Delivered'),
      ('${vm.suppliers.length}', 'Suppliers'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthViewModel>().user;
    if (u == null) return const SizedBox.shrink();
    final stats = _stats(context, u);
    final unread = context.watch<NotificationViewModel>().unread;

    return Scaffold(
      body: Column(
        children: [
          _Hero(
            user: u,
            onEdit: u.isAdmin ? null : () => _edit(context),
            onPhoto: () => _pickPhoto(context),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stats.isNotEmpty) ...[
                        _StatsRow(stats),
                        const SizedBox(height: 16),
                      ],
                      _Section('Contact', [
                        _Row(Icons.mail_outline, 'Email', u.email),
                        _Row(Icons.phone_outlined, 'Phone', u.phone),
                        _Row(Icons.location_on_outlined, 'Address', u.address),
                      ]),
                      const SizedBox(height: 16),
                      _Section(u.isSupplier ? 'Business' : 'Practice', [
                        _Row(
                          Icons.business_outlined,
                          u.isSupplier ? 'Company' : 'Clinic / pharmacy',
                          u.organization,
                        ),
                        if (!u.isSupplier && !u.isAdmin) ...[
                          _Row(
                            Icons.school_outlined,
                            u.specialtyLabel,
                            u.specialty,
                          ),
                          _Row(
                            Icons.local_hospital_outlined,
                            u.practiceLabel,
                            u.practiceType,
                          ),
                          _Row(
                            Icons.workspace_premium_outlined,
                            'Experience',
                            u.experience == null
                                ? ''
                                : '${u.experience} year${u.experience == 1 ? '' : 's'}',
                          ),
                        ],
                        _Row(Icons.info_outline, 'About', u.about),
                        _Row(
                          Icons.event_available_outlined,
                          'Member since',
                          Formatters.date(u.createdAt),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _Section('Account', [
                        if (u.isSupplier)
                          _Action(
                            icon: Icons.draw_outlined,
                            label: u.signaturePath == null
                                ? 'Add invoice signature'
                                : 'Update invoice signature',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignatureScreen(),
                              ),
                            ),
                          ),
                        if (!u.isAdmin)
                          _Action(
                            icon: Icons.edit_outlined,
                            label: 'Edit profile',
                            onTap: () => _edit(context),
                          ),
                        _Action(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          badge: unread,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                        _Action(
                          icon: Icons.logout_rounded,
                          label: 'Log out',
                          color: AppColors.danger,
                          onTap: () => _logout(context),
                        ),
                      ]),
                    ],
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

/// Compact gradient header: tappable photo, letter-spaced role eyebrow,
/// big name and a "member since" tagline.
class _Hero extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onEdit;
  final VoidCallback onPhoto;

  const _Hero({required this.user, required this.onPhoto, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final photo = user.photoPath;
    final hasPhoto =
        photo != null && photo.isNotEmpty && File(photo).existsSync();
    final eyebrow = [
      user.roleLabel.toUpperCase(),
      if (user.organization.isNotEmpty) user.organization.toUpperCase(),
    ].join('  ·  ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        12,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    backgroundImage: hasPhoto ? FileImage(File(photo)) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            Formatters.initials(user.name),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.1,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 8),
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
                        'Member since ${user.createdAt.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.edit_outlined, size: 19),
            ),
        ],
      ),
    );
  }
}

/// Three role-specific metrics shown as cards under the header.
class _StatsRow extends StatelessWidget {
  final List<(String, String)> stats;
  const _StatsRow(this.stats);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < stats.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  stats[i].$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats[i].$2,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 62),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBubble(this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        _IconBubble(icon, AppColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'Not added yet' : value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: value.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final int badge;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBubble(icon, color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color == AppColors.danger
                    ? AppColors.danger
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (badge > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    ),
  );
}
