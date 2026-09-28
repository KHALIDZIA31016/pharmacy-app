import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/app_user.dart';
import '../../data/models/supply_request.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/person_card.dart';
import '../common/profile_screen.dart';
import 'supplier_changes_tab.dart';

/// Admin panel: approve supply requests and review the catalog.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminViewModel>().load(),
    );
  }

  Future<void> _approve(SupplyRequest r) async {
    final vm = context.read<AdminViewModel>();
    final unit = TextEditingController(text: 'Piece');
    final price = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add "${r.name}"'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: unit,
                label: 'Unit',
                validator: (v) => Validators.required(v, 'Unit'),
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: price,
                label: 'Rate',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.positiveNumber,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await vm.approve(r, unit.text.trim(), double.parse(price.text));
    }
    unit.dispose();
    price.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(
                text:
                    'Item requests${vm.pendingRequests > 0 ? ' (${vm.pendingRequests})' : ''}',
              ),
              Tab(
                text:
                    'Supplier changes${vm.pendingChanges > 0 ? ' (${vm.pendingChanges})' : ''}',
              ),
              const Tab(text: 'Catalog'),
              const Tab(text: 'Users'),
              const Tab(text: 'Account'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: vm.load,
              child: vm.requests.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'No supply requests',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = vm.requests[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    StatusChip(r.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By ${r.userName} · ${Formatters.date(r.createdAt)}',
                                ),
                                if (r.details.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r.details),
                                ],
                                if (r.status == RequestStatus.pending) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => vm.reject(r),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () => _approve(r),
                                          child: const Text('Approve'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SupplierChangesTab(),
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = vm.products[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${p.supplierName} · ${p.unit}'),
                    trailing: Text(
                      Formatters.money(p.price),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              },
            ),
            const _UsersTab(),
            const ProfileScreen(),
          ],
        ),
      ),
    );
  }
}

/// Registered suppliers and doctors/pharmacists. The admin is never listed.
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Suppliers (${vm.suppliers.length})'),
              Tab(text: 'Doctors (${vm.doctors.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _list(vm.suppliers, 'No suppliers registered yet.', vm),
                _list(
                  vm.doctors,
                  'No doctors or pharmacists registered yet.',
                  vm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<AppUser> people, String empty, AdminViewModel vm) {
    return RefreshIndicator(
      onRefresh: vm.load,
      child: people.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                EmptyState(icon: Icons.group_outlined, title: empty),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: people.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => PersonCard(people[i]),
            ),
    );
  }
}
