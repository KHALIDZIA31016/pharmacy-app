import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/supply_change_card.dart';

/// Admin queue: supplier add / edit / delete requests. Approving applies the
/// change to the live catalog; rejecting leaves the supplier's list untouched.
class SupplierChangesTab extends StatelessWidget {
  const SupplierChangesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    return RefreshIndicator(
      onRefresh: vm.load,
      child: vm.changes.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'No supplier requests',
                  message: 'Supply changes from suppliers will appear here.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.changes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = vm.changes[i];
                return SupplyChangeCard(
                  change: c,
                  showSupplier: true,
                  footer: !c.isPending
                      ? null
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                                onPressed: () => vm.rejectChange(c),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => vm.approveChange(c),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
