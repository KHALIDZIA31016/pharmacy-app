import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/category_style.dart';
import '../core/utils/formatters.dart';
import '../data/models/product.dart';
import 'qty_stepper.dart';
import 'supply_image.dart';

/// Supply card: photo, name, a plain category / unit / supplier line, price and
/// a quantity stepper. Chosen items get a teal border and tint.
class ProductTile extends StatelessWidget {
  final Product product;
  final int qty;
  final ValueChanged<int> onQtyChanged;
  final bool showSupplier;

  const ProductTile({
    super.key,
    required this.product,
    required this.qty,
    required this.onQtyChanged,
    this.showSupplier = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(product.category);
    final selected = qty > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SupplyImage(
            path: product.imagePath,
            style: style,
            size: 56,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  showSupplier
                      ? '${product.category} · ${product.unit} · ${product.supplierName}'
                      : '${product.category} · ${product.unit}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.money(product.price),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QtyStepper(value: qty, onChanged: onQtyChanged),
        ],
      ),
    );
  }
}
