import 'package:flutter/material.dart';

import 'user_avatar.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/app_user.dart';
import '../views/common/user_profile_screen.dart';

/// Horizontally scrolling mini ID-badge cards; tap opens the profile.
class AvatarStrip extends StatelessWidget {
  final List<AppUser> people;
  final String emptyText;

  /// Text for the card footer (e.g. "3 orders"). Defaults to "View profile".
  final String Function(AppUser)? footerFor;

  const AvatarStrip({
    super.key,
    required this.people,
    required this.emptyText,
    this.footerFor,
  });

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          emptyText,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _BadgeCard(
          p: people[i],
          footer: footerFor?.call(people[i]) ?? 'View profile',
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AppUser p;
  final String footer;
  const _BadgeCard({required this.p, required this.footer});

  bool get _pharmacist => p.profession == Profession.pharmacist;

  @override
  Widget build(BuildContext context) {
    final colors = _pharmacist
        ? const [AppColors.accent, Color(0xFFD9663A)]
        : const [AppColors.primary, AppColors.primaryDark];
    final icon = p.isSupplier
        ? Icons.local_shipping_outlined
        : (_pharmacist
              ? Icons.local_pharmacy_outlined
              : Icons.medical_services_outlined);

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(profile: p)),
        ),
        child: SizedBox(
          width: 148,
          child: Stack(
            children: [
              // Gradient header with a role chip and decorative ring
              Container(
                height: 74,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -22,
                      top: -26,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 11,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              p.roleLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar overlapping the header
              Positioned(
                top: 42,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 27,
                      backgroundColor: colors.first.withValues(alpha: 0.14),
                      backgroundImage: profileImage(p.photoPath),
                      child: profileImage(p.photoPath) != null
                          ? null
                          : Text(
                              Formatters.initials(p.name),
                              style: TextStyle(
                                color: colors.last,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              // Name, clinic
              Positioned(
                top: 108,
                left: 10,
                right: 10,
                child: Column(
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.organization.isNotEmpty ? p.organization : p.roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Footer pill
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: colors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          footer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.last,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colors.last,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
