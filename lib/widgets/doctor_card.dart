import 'package:flutter/material.dart';

import 'user_avatar.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/app_user.dart';
import '../views/common/user_profile_screen.dart';

/// Doctor / pharmacist "ID badge": gradient identity panel, contact lines,
/// a perforated tear-line with side notches, and a stats footer.
class DoctorCard extends StatelessWidget {
  final AppUser person;
  final int orders;
  final double spent;

  const DoctorCard({
    super.key,
    required this.person,
    this.orders = 0,
    this.spent = 0,
  });

  bool get _isPharmacist => person.profession == Profession.pharmacist;

  @override
  Widget build(BuildContext context) {
    final colors = _isPharmacist
        ? const [AppColors.accent, Color(0xFFD9663A)]
        : const [AppColors.primary, AppColors.primaryDark];

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(profile: person)),
        ),
        child: Column(
          children: [
            _Identity(
              person: person,
              colors: colors,
              pharmacist: _isPharmacist,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                children: [
                  _line(
                    Icons.phone_outlined,
                    person.phone.isEmpty ? 'No phone added' : person.phone,
                  ),
                  const SizedBox(height: 6),
                  _line(
                    Icons.location_on_outlined,
                    person.address.isEmpty
                        ? 'No address added'
                        : person.address,
                  ),
                ],
              ),
            ),
            const _Perforation(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 14),
              child: Row(
                children: [
                  _metric('$orders', orders == 1 ? 'Order' : 'Orders'),
                  _divider(),
                  _metric(Formatters.money(spent), 'Total spent'),
                  _divider(),
                  _metric('${person.createdAt.year}', 'Joined'),
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ],
  );

  Widget _metric(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 26, color: AppColors.border);
}

/// Gradient panel with avatar, name, role chip and clinic.
class _Identity extends StatelessWidget {
  final AppUser person;
  final List<Color> colors;
  final bool pharmacist;

  const _Identity({
    required this.person,
    required this.colors,
    required this.pharmacist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative rings
          Positioned(right: -30, top: -30, child: _ring(110)),
          Positioned(right: 30, bottom: -40, child: _ring(80)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImage(person.photoPath),
                    child: profileImage(person.photoPath) != null
                        ? null
                        : Text(
                            Formatters.initials(person.name),
                            style: TextStyle(
                              color: colors.last,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pharmacist
                                  ? Icons.local_pharmacy_outlined
                                  : Icons.medical_services_outlined,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              person.roleLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (person.credentialLine.isNotEmpty)
                        Text(
                          person.credentialLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (person.organization.isNotEmpty)
                        Text(
                          person.organization,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
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

  Widget _ring(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.14),
        width: 14,
      ),
    ),
  );
}

/// Dashed tear-line with half-circle notches biting into both sides.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: LayoutBuilder(
              builder: (_, c) {
                final dashes = (c.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < dashes; i++)
                      Container(width: 5, height: 1.5, color: AppColors.border),
                  ],
                );
              },
            ),
          ),
          const Positioned(left: -10, child: _Notch()),
          const Positioned(right: -10, child: _Notch()),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      color: AppColors.background,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.border),
    ),
  );
}
