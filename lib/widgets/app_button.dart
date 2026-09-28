import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        // FittedBox shrinks icon + label together when the button is narrow
        // (e.g. two buttons side by side) instead of overflowing.
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const size = Size.fromHeight(52);
    final action = loading ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: action,
              style: OutlinedButton.styleFrom(minimumSize: size, shape: shape),
              child: child,
            )
          : FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(minimumSize: size, shape: shape),
              child: child,
            ),
    );
  }
}
