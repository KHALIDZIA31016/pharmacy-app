import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../viewmodels/nav_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../common/order_detail_screen.dart';
import '../../widgets/invoice_tile.dart';

/// Shown right after an order is placed (or updated): confirmation, invoice
/// actions and a shortcut to track the order.
class OrderPlacedScreen extends StatelessWidget {
  final List<Order> orders;
  final bool updated;

  const OrderPlacedScreen({
    super.key,
    required this.orders,
    this.updated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Hero(orders: orders, updated: updated),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                for (final o in orders) ...[
                  _SummaryCard(order: o),
                  const SizedBox(height: 8),
                  InvoiceTile(order: o),
                  const SizedBox(height: 14),
                ],
                if (orders.length > 1) _GrandTotal(orders: orders),
                const SizedBox(height: 22),
                AppButton(
                  label: orders.length == 1
                      ? 'Track this order'
                      : 'Track my orders',
                  icon: Icons.local_shipping_outlined,
                  outlined: true,
                  onPressed: () {
                    if (orders.length == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailScreen(order: orders.first),
                        ),
                      );
                    } else {
                      context.read<NavViewModel>().setIndex(0);
                      Navigator.popUntil(context, (r) => r.isFirst);
                    }
                  },
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    context.read<NavViewModel>().setIndex(0);
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  child: const Text(
                    'Back to home',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final List<Order> orders;
  final bool updated;
  const _Hero({required this.orders, required this.updated});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 26,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(right: -40, top: -50, child: _ring(150)),
          Positioned(left: -30, bottom: -70, child: _ring(120)),
          Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 42,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                updated ? 'ORDER UPDATED' : 'ORDER CONFIRMED',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                updated ? 'Changes saved!' : 'Order placed!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      orders.length == 1
                          ? '${orders.first.supplierName} has been notified'
                          : '${orders.length} suppliers have been notified',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ring(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.13),
        width: 16,
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final Order order;
  const _SummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ORDER #${order.id}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                Formatters.dateTime(order.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final i in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${i.qty}×',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(i.name)),
                  Text(
                    Formatters.money(i.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Text(
                Formatters.money(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Combined total when one submission created several orders.
class _GrandTotal extends StatelessWidget {
  final List<Order> orders;
  const _GrandTotal({required this.orders});

  @override
  Widget build(BuildContext context) {
    final total = orders.fold<double>(0, (s, o) => s + o.total);
    final items = orders.fold<int>(0, (s, o) => s + o.itemCount);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALL ORDERS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${orders.length} orders · $items items',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Text(
            Formatters.money(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
