import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_tile.dart';
import 'invoice_screen.dart';
import 'supply_request_screen.dart';

/// Browse every supply rate, request missing items, build an invoice.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  void _openRequests(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SupplyRequestScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatalogViewModel>();
    final items = vm.filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore supplies'),
        actions: [
          IconButton(
            tooltip: 'Request an item',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _openRequests(context),
          ),
        ],
      ),
      bottomNavigationBar: vm.selectedCount == 0
          ? null
          : BottomActionBar(
              summary: '${vm.selectedCount} item(s) selected',
              total: Formatters.money(vm.selectedTotal),
              actionLabel: 'Generate invoice',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceScreen()),
              ),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: TextField(
              onChanged: vm.setQuery,
              decoration: const InputDecoration(
                hintText: 'Search product or supplier',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: vm.category == null,
                    onSelected: (_) => vm.setCategory(null),
                  ),
                ),
                for (final c in vm.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: vm.category == c,
                      onSelected: (_) => vm.setCategory(c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: vm.loading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Not in the list?',
                        message:
                            'Ask the admin to add it. You will be notified when it is approved.',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: AppButton(
                          label: 'Request this item',
                          icon: Icons.add_comment_outlined,
                          onPressed: () => _openRequests(context),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == items.length) {
                        return TextButton.icon(
                          onPressed: () => _openRequests(context),
                          icon: const Icon(Icons.add_comment_outlined),
                          label: const Text("Can't find it? Request an item"),
                        );
                      }
                      final p = items[i];
                      return ProductTile(
                        product: p,
                        showSupplier: true,
                        qty: vm.qtyOf(p),
                        onQtyChanged: (q) => vm.setQty(p, q),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
