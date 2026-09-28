import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  Color get _color => switch (status) {
    OrderStatus.delivered || RequestStatus.approved => AppColors.success,
    OrderStatus.confirmed => AppColors.primary,
    OrderStatus.cancelled || RequestStatus.rejected => AppColors.danger,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Formatters.capitalize(status),
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
