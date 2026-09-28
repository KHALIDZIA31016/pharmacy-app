import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/nav_viewmodel.dart';
import '../../viewmodels/user_home_viewmodel.dart';
import '../../widgets/avatar_strip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/highlight_card.dart';
import '../../widgets/home_header.dart';
import '../../widgets/order_card.dart';
import '../../widgets/quick_actions.dart';
import '../../widgets/section_header.dart';
import '../common/order_detail_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    // Null while logging out, before the login route replaces this screen.
    if (user == null) return const SizedBox.shrink();
    final vm = context.watch<UserHomeViewModel>();
    final nav = context.read<NavViewModel>();
    final latest = vm.latestDelivered;
    final active = vm.orders
        .where((o) => !o.isDelivered && o.status != 'cancelled')
        .length;

    return Scaffold(
      body: Column(
        children: [
          HomeHeader(
            name: user.name,
            child: _SearchPill(onTap: () => nav.setIndex(2)),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => vm.load(user.uid),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (latest != null)
                          HighlightCard(
                            eyebrow: 'Latest delivery',
                            title: latest.supplierName,
                            subtitle:
                                'Order #${latest.id} · ${latest.itemCount} items · ${Formatters.date(latest.deliveredAt ?? latest.createdAt)}',
                            icon: Icons.inventory_2_rounded,
                            footer: [
                              HighlightStat(
                                'Total',
                                Formatters.money(latest.total),
                              ),
                              const HighlightStat('Status', 'Delivered'),
                              const HighlightStat('Tap for', 'Details'),
                            ],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailScreen(order: latest),
                              ),
                            ),
                          )
                        else
                          HighlightCard(
                            eyebrow: 'Deliveries',
                            title: 'No deliveries yet',
                            subtitle: 'Place your first order to see it here.',
                            icon: Icons.local_shipping_rounded,
                            onTap: () => nav.setIndex(1),
                          ),
                        const SizedBox(height: 18),
                        QuickActions([
                          QuickAction(
                            Icons.shopping_bag_outlined,
                            'Order',
                            () => nav.setIndex(1),
                          ),
                          QuickAction(
                            Icons.manage_search_rounded,
                            'Explore',
                            () => nav.setIndex(2),
                          ),
                          QuickAction(
                            Icons.local_shipping_outlined,
                            'In progress',
                            () => nav.setIndex(0),
                            badge: active,
                            color: AppColors.accent,
                          ),
                        ]),
                        const SizedBox(height: 28),
                        SectionHeader(
                          'Suppliers',
                          actionLabel: vm.suppliers.isEmpty
                              ? null
                              : '${vm.suppliers.length} available',
                        ),
                        const SizedBox(height: 8),
                        AvatarStrip(
                          people: vm.suppliers,
                          emptyText: 'No suppliers registered yet.',
                        ),
                        const SizedBox(height: 24),
                        const SectionHeader('Order updates'),
                        const SizedBox(height: 8),
                        if (vm.loading && vm.orders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (vm.orders.isEmpty)
                          const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No orders yet',
                            message:
                                'Orders you place will appear here with live status.',
                          )
                        else
                          for (final o in vm.orders.take(5)) ...[
                            OrderCard(
                              order: o,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(order: o),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search medicines, injections, supplies…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
