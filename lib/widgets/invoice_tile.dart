import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/order.dart';
import '../views/common/invoice_preview_screen.dart';

/// Entry point to an order's invoice. Locked (amber) until the supplier
/// approves the order, then teal and ready to download / print.
class InvoiceTile extends StatelessWidget {
  final Order order;
  final bool asSupplier;

  const InvoiceTile({super.key, required this.order, this.asSupplier = false});

  @override
  Widget build(BuildContext context) {
    final approved = order.isApproved;
    final cancelled = order.status == 'cancelled';
    final color = cancelled
        ? AppColors.textSecondary
        : (approved ? AppColors.primary : AppColors.warning);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: approved
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: approved ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: approved
              ? null
              : Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  InvoicePreviewScreen(order: order, asSupplier: asSupplier),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: approved
                        ? Colors.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    approved
                        ? Icons.receipt_long_rounded
                        : Icons.lock_outline_rounded,
                    color: approved ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approved ? 'Invoice ready' : 'Invoice preview',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: approved
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        cancelled
                            ? 'Order cancelled'
                            : approved
                            ? 'Approved · tap to view, download or print'
                            : 'Locked · unlocks when ${order.supplierName} approves',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: approved
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: approved ? Colors.white : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
