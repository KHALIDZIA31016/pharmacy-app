import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/order.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

/// Order card with a status-coloured edge, item chips and a progress tracker.
/// Shows the supplier, or the buyer when [showBuyer].
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final bool showBuyer;
  final Widget? footer;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showBuyer = false,
    this.footer,
  });

  Color get _accent => switch (order.status) {
    OrderStatus.delivered => AppColors.success,
    OrderStatus.confirmed => AppColors.primary,
    OrderStatus.cancelled => AppColors.danger,
    _ => AppColors.warning,
  };

  int get _step => switch (order.status) {
    OrderStatus.confirmed => 1,
    OrderStatus.delivered => 2,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final who = showBuyer ? order.userName : order.supplierName;
    final shown = order.items.take(3).toList();
    final more = order.items.length - shown.length;

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: _accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(name: who, radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  who,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                  ),
                                ),
                                Text(
                                  '#${order.id} · ${Formatters.date(order.createdAt)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(order.status),
                        ],
                      ),
                      if (shown.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final i in shown) _Chip('${i.qty}× ${i.name}'),
                            if (more > 0) _Chip('+$more more', muted: true),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (order.status == OrderStatus.cancelled)
                        _Cancelled()
                      else
                        _Progress(step: _step, color: _accent),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${order.itemCount} item(s)',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.money(order.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 12),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool muted;
  const _Chip(this.text, {this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: muted
          ? AppColors.background
          : AppColors.primary.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted ? AppColors.textSecondary : AppColors.primaryDark,
      ),
    ),
  );
}

class _Progress extends StatelessWidget {
  final int step;
  final Color color;
  const _Progress({required this.step, required this.color});

  static const _labels = ['Placed', 'Confirmed', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final reached = i <= step;
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached ? color : AppColors.surface,
          border: Border.all(
            color: reached ? color : AppColors.border,
            width: 2,
          ),
        ),
        child: reached
            ? const Icon(Icons.check, size: 11, color: Colors.white)
            : null,
      );
    }

    Widget line(int i) => Expanded(
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: i < step ? color : AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );

    return Column(
      children: [
        Row(children: [dot(0), line(0), dot(1), line(1), dot(2)]),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 3; i++)
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                  color: i <= step
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Cancelled extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(
      children: [
        Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
        SizedBox(width: 8),
        Text(
          'This order was cancelled',
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
