import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_button.dart';

/// Sticky summary + action shown above the bottom navigation.
class BottomActionBar extends StatelessWidget {
  final String summary;
  final String total;
  final String actionLabel;
  final VoidCallback? onPressed;
  final bool loading;

  const BottomActionBar({
    super.key,
    required this.summary,
    required this.total,
    required this.actionLabel,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  summary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: AppButton(
                label: actionLabel,
                onPressed: onPressed,
                loading: loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
