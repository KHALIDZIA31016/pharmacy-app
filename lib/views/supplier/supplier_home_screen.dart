import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/nav_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../widgets/avatar_strip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/home_header.dart';
import '../../widgets/order_card.dart';
import '../../widgets/quick_actions.dart';
import '../../widgets/section_header.dart';
import '../common/order_detail_screen.dart';
import 'my_supplies_screen.dart';

class SupplierHomeScreen extends StatelessWidget {
  const SupplierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    // Null while logging out, before the login route replaces this screen.
    if (user == null) return const SizedBox.shrink();
    final vm = context.watch<SupplierViewModel>();
    final nav = context.read<NavViewModel>();

    return Scaffold(
      body: Column(
        children: [
          HomeHeader(
            name: user.name,
            child: HeaderStats([
              ('${vm.pendingCount}', 'Open orders'),
              ('${vm.deliveredCount}', 'Delivered'),
              (Formatters.money(vm.revenue), 'Revenue'),
            ]),
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
                        QuickActions([
                          QuickAction(
                            Icons.inventory_2_outlined,
                            'My supplies',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MySuppliesScreen(),
                              ),
                            ),
                          ),
                          QuickAction(
                            Icons.receipt_long_outlined,
                            'Orders',
                            () => nav.setIndex(2),
                            badge: vm.pendingCount,
                            color: AppColors.accent,
                          ),
                          QuickAction(
                            Icons.medical_services_outlined,
                            'Doctors',
                            () => nav.setIndex(1),
                          ),
                        ]),
                        const SizedBox(height: 28),
                        SectionHeader(
                          'Doctors & pharmacists',
                          actionLabel: 'See all',
                          onAction: () => nav.setIndex(1),
                        ),
                        const SizedBox(height: 8),
                        AvatarStrip(
                          people: vm.buyers,
                          emptyText:
                              'No doctors or pharmacists registered yet.',
                          footerFor: (p) {
                            final n = vm.ordersFrom(p.uid);
                            return n == 0
                                ? 'View profile'
                                : '$n order${n == 1 ? '' : 's'}';
                          },
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          'Recent orders',
                          actionLabel: vm.orders.isEmpty ? null : 'See all',
                          onAction: () => nav.setIndex(2),
                        ),
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
                            message: 'Orders placed with you will appear here.',
                          )
                        else
                          for (final o in vm.orders.take(5)) ...[
                            OrderCard(
                              order: o,
                              showBuyer: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(
                                    order: o,
                                    asSupplier: true,
                                  ),
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
