import 'package:flutter/material.dart';

import '../../widgets/user_avatar.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui.dart';
import '../../data/models/app_user.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/nav_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../viewmodels/user_home_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/order_card.dart';
import '../../widgets/supply_image.dart';
import 'order_detail_screen.dart';

/// Read-only profile of a doctor / pharmacist or a supplier, with the
/// order history shared with the person viewing it.
class UserProfileScreen extends StatelessWidget {
  final AppUser profile;
  const UserProfileScreen({super.key, required this.profile});

  bool get _isPharmacist => profile.profession == Profession.pharmacist;

  Color get _accent => profile.isSupplier
      ? AppColors.primary
      : (_isPharmacist ? AppColors.accent : AppColors.primary);

  IconData get _roleIcon => profile.isSupplier
      ? Icons.local_shipping_outlined
      : (_isPharmacist
            ? Icons.local_pharmacy_outlined
            : Icons.medical_services_outlined);

  Future<void> _orderFrom(BuildContext context) async {
    final nav = context.read<NavViewModel>();
    context.read<OrderViewModel>().selectSupplier(profile);
    nav.setIndex(1);
    if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  void _copy(BuildContext context, String label, String value) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    showSnack(context, '$label copied');
  }

  /// Orders shared between the viewer and this profile.
  List<Order> _sharedOrders(BuildContext context, AppUser? viewer) {
    if (viewer == null) return const [];
    if (viewer.isSupplier && !profile.isSupplier) {
      return context
          .watch<SupplierViewModel>()
          .orders
          .where((o) => o.userId == profile.uid)
          .toList();
    }
    if (!viewer.isSupplier && !viewer.isAdmin && profile.isSupplier) {
      return context
          .watch<UserHomeViewModel>()
          .orders
          .where((o) => o.supplierId == profile.uid)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final viewer = context.read<AuthViewModel>().user;
    final canOrder =
        profile.isSupplier &&
        viewer != null &&
        !viewer.isSupplier &&
        !viewer.isAdmin;
    final asSupplier = viewer?.isSupplier ?? false;
    final shared = _sharedOrders(context, viewer);
    final counted = shared
        .where((o) => o.status != OrderStatus.cancelled)
        .toList();
    final spent = counted.fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      bottomNavigationBar: canOrder
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: 'Order from ${profile.firstName}',
                  icon: Icons.shopping_bag_outlined,
                  onPressed: () => _orderFrom(context),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          _Hero(
            profile: profile,
            accent: _accent,
            roleIcon: _roleIcon,
            stats: [
              if (viewer != null && !viewer.isAdmin) ...[
                ('${counted.length}', 'Orders'),
                (Formatters.money(spent), 'Total'),
              ],
              ('${profile.createdAt.year}', 'Member since'),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ContactButton(
                              icon: Icons.phone_outlined,
                              label: 'Copy phone',
                              enabled: profile.phone.isNotEmpty,
                              onTap: () =>
                                  _copy(context, 'Phone', profile.phone),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ContactButton(
                              icon: Icons.mail_outline,
                              label: 'Copy email',
                              enabled: profile.email.isNotEmpty,
                              onTap: () =>
                                  _copy(context, 'Email', profile.email),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (profile.about.isNotEmpty) ...[
                        const _Label('About'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              profile.about,
                              style: const TextStyle(height: 1.45),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (!profile.isSupplier && !profile.isAdmin) ...[
                        const _Label('Credentials'),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _Detail(
                                Icons.school_outlined,
                                profile.specialtyLabel,
                                profile.specialty,
                              ),
                              const Divider(height: 1, indent: 62),
                              _Detail(
                                Icons.local_hospital_outlined,
                                profile.practiceLabel,
                                profile.practiceType,
                              ),
                              const Divider(height: 1, indent: 62),
                              _Detail(
                                Icons.workspace_premium_outlined,
                                'Experience',
                                profile.experience == null
                                    ? ''
                                    : '${profile.experience} year${profile.experience == 1 ? '' : 's'}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const _Label('Contact & practice'),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _Detail(
                              Icons.business_outlined,
                              profile.isSupplier
                                  ? 'Company'
                                  : 'Clinic / pharmacy',
                              profile.organization,
                            ),
                            const Divider(height: 1, indent: 62),
                            _Detail(
                              Icons.phone_outlined,
                              'Phone',
                              profile.phone,
                              onCopy: () =>
                                  _copy(context, 'Phone', profile.phone),
                            ),
                            const Divider(height: 1, indent: 62),
                            _Detail(
                              Icons.mail_outline,
                              'Email',
                              profile.email,
                              onCopy: () =>
                                  _copy(context, 'Email', profile.email),
                            ),
                            const Divider(height: 1, indent: 62),
                            _Detail(
                              Icons.location_on_outlined,
                              'Address',
                              profile.address,
                            ),
                          ],
                        ),
                      ),
                      if (profile.isSupplier) ...[
                        const SizedBox(height: 20),
                        _SuppliesSection(supplierId: profile.uid),
                      ],
                      if (shared.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _Label(
                          asSupplier
                              ? 'Orders from ${profile.firstName}'
                              : 'Your orders here',
                        ),
                        for (final o in shared.take(5)) ...[
                          OrderCard(
                            order: o,
                            showBuyer: asSupplier,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  order: o,
                                  asSupplier: asSupplier,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
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

class _Hero extends StatelessWidget {
  final AppUser profile;
  final Color accent;
  final IconData roleIcon;
  final List<(String, String)> stats;

  const _Hero({
    required this.profile,
    required this.accent,
    required this.roleIcon,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.of(context).padding.top + 4,
        12,
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
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: profileImage(profile.photoPath),
              child: profileImage(profile.photoPath) != null
                  ? null
                  : Text(
                      Formatters.initials(profile.name),
                      style: TextStyle(
                        color: accent == AppColors.accent
                            ? AppColors.accent
                            : AppColors.primaryDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              profile.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  profile.roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (profile.organization.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.organization,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      Container(width: 1, height: 30, color: Colors.white24),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            stats[i].$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            stats[i].$2,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        letterSpacing: 1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _Detail(this.icon, this.label, this.value, {this.onCopy});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
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
        if (onCopy != null && value.isNotEmpty)
          IconButton(
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    ),
  );
}

/// A supplier's live supplies (first few), loaded from the catalog.
class _SuppliesSection extends StatelessWidget {
  final String supplierId;
  const _SuppliesSection({required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: context.read<ProductRepository>().bySupplier(supplierId),
      builder: (context, snap) {
        final items = snap.data ?? const <Product>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Supplies · ${items.length}'),
            if (snap.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No supplies listed yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length && i < 6; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 66),
                      ListTile(
                        leading: SupplyImage(
                          path: items[i].imagePath,
                          style: CategoryStyle.of(items[i].category),
                          size: 40,
                          radius: 12,
                        ),
                        title: Text(
                          items[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${items[i].category} · ${items[i].unit}',
                        ),
                        trailing: Text(
                          Formatters.money(items[i].price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                    if (items.length > 6)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '+ ${items.length - 6} more supplies',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
