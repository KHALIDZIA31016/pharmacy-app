import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/app_user.dart';
import '../views/common/user_profile_screen.dart';
import 'user_avatar.dart';

/// List row for a supplier or buyer; tap opens their profile.
class PersonCard extends StatelessWidget {
  final AppUser person;
  const PersonCard(this.person, {super.key});

  @override
  Widget build(BuildContext context) {
    final subtitle = person.organization.isNotEmpty
        ? person.organization
        : person.roleLabel;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(profile: person)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(name: person.name, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (person.address.isNotEmpty)
                      Text(
                        person.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
