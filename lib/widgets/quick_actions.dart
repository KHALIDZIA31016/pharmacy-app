import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final Color? color;

  const QuickAction(
    this.icon,
    this.label,
    this.onTap, {
    this.badge = 0,
    this.color,
  });
}

/// Row of equal-width shortcut tiles.
class QuickActions extends StatelessWidget {
  final List<QuickAction> actions;
  const QuickActions(this.actions, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(child: _Tile(actions[i])),
      ],
    ],
  );
}

class _Tile extends StatelessWidget {
  final QuickAction action;
  const _Tile(this.action);

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? AppColors.primary;
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Badge(
                isLabelVisible: action.badge > 0,
                label: Text('${action.badge}'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(action.icon, color: color),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
