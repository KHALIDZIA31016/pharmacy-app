import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const QtyStepper({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return FilledButton.tonal(
        onPressed: () => onChanged(1),
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: const Text('Add'),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => onChanged(value - 1)),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _btn(Icons.add, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 18, color: AppColors.primary),
    ),
  );
}
