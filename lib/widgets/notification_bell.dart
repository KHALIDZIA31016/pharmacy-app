import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../views/common/notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  /// White-on-translucent style for use over the gradient header.
  final bool light;
  const NotificationBell({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationViewModel>().unread;
    return Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      offset: const Offset(-4, 4),
      child: IconButton.filledTonal(
        icon: const Icon(Icons.notifications_none_rounded),
        color: light ? Colors.white : AppColors.textPrimary,
        style: light
            ? IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              )
            : null,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
    );
  }
}
