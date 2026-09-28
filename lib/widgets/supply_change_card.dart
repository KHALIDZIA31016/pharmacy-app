import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/category_style.dart';
import '../core/utils/formatters.dart';
import '../data/models/supply_change.dart';
import 'status_chip.dart';
import 'supply_image.dart';

/// Shows one add / update / delete request, with before → after values.
class SupplyChangeCard extends StatelessWidget {
  final SupplyChange change;
  final bool showSupplier;
  final Widget? footer;

  const SupplyChangeCard({
    super.key,
    required this.change,
    this.showSupplier = false,
    this.footer,
  });

  (String, IconData, Color) get _action => switch (change.action) {
    ChangeAction.add => (
      'New supply',
      Icons.add_circle_outline,
      AppColors.success,
    ),
    ChangeAction.update => ('Edit', Icons.edit_outlined, AppColors.primary),
    _ => ('Delete', Icons.delete_outline, AppColors.danger),
  };

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _action;
    final style = CategoryStyle.of(change.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                StatusChip(change.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SupplyImage(path: change.imagePath, style: style, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        change.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                      Text(
                        [
                          if (showSupplier) change.supplierName,
                          Formatters.date(change.createdAt),
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._details(),
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );
  }

  List<Widget> _details() {
    final c = change;
    if (c.action != ChangeAction.update) {
      return [
        Text(
          '${c.category} · ${c.unit} · ${Formatters.money(c.price)}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ];
    }
    return [
      if (c.oldName != c.name) _diff('Name', c.oldName!, c.name),
      if (c.oldCategory != c.category)
        _diff('Category', c.oldCategory!, c.category),
      if (c.oldUnit != c.unit) _diff('Unit', c.oldUnit!, c.unit),
      if (c.oldPrice != c.price)
        _diff('Rate', Formatters.money(c.oldPrice!), Formatters.money(c.price)),
    ];
  }

  Widget _diff(String field, String from, String to) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            field,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
        Flexible(
          child: Text(
            from,
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded, size: 14),
        ),
        Flexible(
          child: Text(to, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
