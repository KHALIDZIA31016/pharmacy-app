import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_card.dart';
import '../common/order_detail_screen.dart';

class SupplierOrdersScreen extends StatelessWidget {
  const SupplierOrdersScreen({super.key});

  static const _filters = <String?>[
    null,
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  Widget? _actions(SupplierViewModel vm, Order o) {
    switch (o.status) {
      case OrderStatus.placed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                onPressed: () => vm.updateStatus(o, OrderStatus.cancelled),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => vm.updateStatus(o, OrderStatus.confirmed),
                child: const Text('Approve'),
              ),
            ),
          ],
        );
      case OrderStatus.confirmed:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => vm.updateStatus(o, OrderStatus.delivered),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Mark as delivered'),
          ),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SupplierViewModel>();
    final uid = context.read<AuthViewModel>().user?.uid ?? '';
    final orders = vm.filteredOrders;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Hero summary
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Incoming orders',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vm.orders.length} total · ${vm.pendingCount} open',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _stat('${vm.deliveredCount}', 'Delivered'),
                      _stat(Formatters.money(vm.revenue), 'Revenue'),
                      _stat(
                        '${vm.countWhere(OrderStatus.cancelled)}',
                        'Cancelled',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          '${f == null ? 'All' : Formatters.capitalize(f)} · ${vm.countWhere(f)}',
                        ),
                        selected: vm.statusFilter == f,
                        onSelected: (_) => vm.setFilter(f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => vm.load(uid),
                child: orders.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No orders here',
                            message: 'Orders in this status will show up here.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final o = orders[i];
                          return OrderCard(
                            order: o,
                            showBuyer: true,
                            footer: _actions(vm, o),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  order: o,
                                  asSupplier: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}
