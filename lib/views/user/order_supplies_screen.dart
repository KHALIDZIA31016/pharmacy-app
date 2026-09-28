import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui.dart';
import '../../data/models/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/nav_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/user_home_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_tile.dart';
import '../../widgets/qty_stepper.dart';
import '../../widgets/supply_image.dart';
import '../../widgets/user_avatar.dart';
import 'order_placed_screen.dart';

/// Doctor's order builder: pick a supplier, pick supplies (or select all),
/// review and place. Also used to edit an order that is still open.
class OrderSuppliesScreen extends StatefulWidget {
  const OrderSuppliesScreen({super.key});

  @override
  State<OrderSuppliesScreen> createState() => _OrderSuppliesScreenState();
}

class _OrderSuppliesScreenState extends State<OrderSuppliesScreen> {
  int _lastTab = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh the full supplies list each time the Order tab becomes visible,
    // so items suppliers added (and the admin approved) show up straight away.
    final tab = Provider.of<NavViewModel>(context).index;
    if (tab == 1 && _lastTab != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<OrderViewModel>().loadSuppliers();
      });
    }
    _lastTab = tab;
  }

  Future<void> _review(BuildContext context) async {
    final vm = context.read<OrderViewModel>();
    final user = context.read<AuthViewModel>().user!;
    final home = context.read<UserHomeViewModel>();
    final notes = TextEditingController(text: vm.notes);
    final isEdit = vm.editing != null;

    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BucketSheet(notes: notes, isEdit: isEdit),
    );
    vm.notes = notes.text;
    notes.dispose();
    if (go != true) return;

    final orders = await vm.placeOrder(user);
    if (!context.mounted) return;
    if (orders.isEmpty) {
      return showSnack(
        context,
        vm.error ?? 'Could not place the order.',
        error: true,
      );
    }
    await home.load(user.uid);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderPlacedScreen(orders: orders, updated: isEdit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();
    final supplier = vm.supplier;
    final products = vm.filteredProducts;

    return Scaffold(
      bottomNavigationBar: vm.cartCount == 0
          ? null
          : BottomActionBar(
              summary:
                  '${vm.cartLines} product${vm.cartLines == 1 ? '' : 's'} · ${vm.cartCount} item(s)${vm.supplierCount > 1 ? ' · ${vm.supplierCount} suppliers' : ''}',
              total: Formatters.money(vm.total),
              actionLabel: 'Place order',
              loading: vm.placing,
              onPressed: () => _review(context),
            ),
      body: Column(
        children: [
          _Header(vm: vm),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.loadSuppliers,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  if (vm.editing != null) ...[
                    _EditBanner(vm: vm),
                    const SizedBox(height: 18),
                  ],
                  if (vm.editing == null) ...[
                    const _Step(1, 'Suppliers · tap one to filter'),
                    if (vm.suppliers.isEmpty)
                      const EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No suppliers yet',
                        message: 'Suppliers who register will appear here.',
                      )
                    else
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: vm.suppliers.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (_, i) {
                            final s = vm.suppliers[i];
                            final isSel = supplier?.uid == s.uid;
                            return _SupplierChip(
                              supplier: s,
                              supplies: vm.productCounts[s.uid] ?? 0,
                              selected: isSel,
                              onTap: () =>
                                  isSel ? vm.showAll() : vm.selectSupplier(s),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 26),
                  ],
                  _Step(
                    vm.editing == null ? 2 : 1,
                    supplier == null
                        ? 'All supplies · pick from any supplier'
                        : 'Select supplies from ${supplier.name}',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      supplier == null
                          ? 'Every supply from every supplier is listed below. Tap Add on the ones you need, they go into your list, then place your order.'
                          : 'Tap Add on the supplies you need from ${supplier.name}.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (supplier != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Showing only ${supplier.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: vm.showAll,
                            icon: const Icon(Icons.apps_rounded, size: 18),
                            label: const Text('Show all suppliers'),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    key: ValueKey('search-${supplier?.uid ?? 'all'}'),
                    onChanged: vm.setQuery,
                    decoration: InputDecoration(
                      hintText: supplier == null
                          ? 'Search all supplies'
                          : 'Search ${supplier.name}\u2019s supplies',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView(
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
                  const SizedBox(height: 12),
                  _Toolbar(vm: vm, shown: products.length),
                  const SizedBox(height: 10),
                  if (vm.loading && vm.allProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (products.isEmpty)
                    EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No supplies found',
                      message: vm.products.isEmpty
                          ? (supplier == null
                                ? 'No supplier has any approved supplies yet. Pull down to refresh once they are added.'
                                : '${supplier.name} has not listed any supplies yet.')
                          : 'Nothing matches your search. Try another word or category.',
                    )
                  else
                    for (final p in products) ...[
                      ProductTile(
                        product: p,
                        showSupplier: supplier == null,
                        qty: vm.qtyOf(p),
                        onQtyChanged: (q) => vm.setQty(p, q),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned gradient header with the current step and cart badge.
class _Header extends StatelessWidget {
  final OrderViewModel vm;
  const _Header({required this.vm});

  @override
  Widget build(BuildContext context) {
    final editing = vm.editing != null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -34, child: _ring(120)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing ? 'EDIT ORDER #${vm.editing!.id}' : 'NEW ORDER',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vm.supplier == null
                          ? 'Place an order'
                          : 'Ordering from ${vm.supplier!.firstName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.15,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                            vm.supplier == null
                                ? 'Pick a supplier to start'
                                : 'Choose supplies, review, done',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (vm.cartCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${vm.cartCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
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
        width: 14,
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  const _Step(this.number, this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Banner shown while an open order is being edited.
class _EditBanner extends StatelessWidget {
  final OrderViewModel vm;
  const _EditBanner({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        const Icon(Icons.edit_note_rounded, color: AppColors.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'You are editing order #${vm.editing!.id}. ${vm.supplier?.name ?? 'The supplier'} will be notified of your changes.',
            style: const TextStyle(fontSize: 12.5, height: 1.35),
          ),
        ),
        TextButton(onPressed: vm.cancelEdit, child: const Text('Discard')),
      ],
    ),
  );
}

/// Slim supplier "story": ringed avatar with a supply-count badge and the
/// name underneath. Tap to show only this supplier; tap again for everyone.
class _SupplierChip extends StatelessWidget {
  final AppUser supplier;
  final int supplies;
  final bool selected;
  final VoidCallback onTap;

  const _SupplierChip({
    required this.supplier,
    required this.supplies,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            const SizedBox(height: 2),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          )
                        : null,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(
                      name: supplier.name,
                      radius: 23,
                      path: supplier.photoPath,
                    ),
                  ),
                ),
                // Supply count
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$supplies',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.success,
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              supplier.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Select all" / "Clear" bar above the product list.
class _Toolbar extends StatelessWidget {
  final OrderViewModel vm;
  final int shown;
  const _Toolbar({required this.vm, required this.shown});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$shown supplies',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (vm.cartCount > 0)
          TextButton(onPressed: vm.clearCart, child: const Text('Clear')),
        FilledButton.tonalIcon(
          onPressed: shown == 0 || vm.allFilteredSelected
              ? null
              : vm.selectAllFiltered,
          icon: const Icon(Icons.done_all_rounded, size: 18),
          label: Text(vm.allFilteredSelected ? 'All selected' : 'Select all'),
        ),
      ],
    );
  }
}

/// The "bucket": everything chosen so far. Quantities can be changed or
/// items removed; from here you preview the invoice and submit the request.
class _BucketSheet extends StatelessWidget {
  final TextEditingController notes;
  final bool isEdit;
  const _BucketSheet({required this.notes, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();
    final items = vm.bucket;

    // Everything was removed: close the sheet.
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context, false);
        }
      });
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit your bucket' : 'Your bucket',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${vm.cartCount} item(s) · ${vm.supplierCount} supplier${vm.supplierCount == 1 ? '' : 's'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              children: [
                if (vm.hasUnassigned) _AssignSupplier(vm: vm),
                for (final e in vm.bucketBySupplier.entries) ...[
                  _GroupHeader(
                    name: vm.supplierNameFor(e.key, e.value),
                    subtotal: vm.subtotalFor(e.value),
                  ),
                  for (final p in e.value)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          SupplyImage(
                            path: p.imagePath,
                            style: CategoryStyle.of(p.category),
                            size: 44,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${Formatters.money(p.price)} · ${p.unit}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.money(p.price * vm.qtyOf(p)),
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          QtyStepper(
                            value: vm.qtyOf(p),
                            onChanged: (q) => vm.setQty(p, q),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () => vm.setQty(p, 0),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 6),
                AppTextField(
                  controller: notes,
                  label: 'Notes for the supplier (optional)',
                  icon: Icons.notes,
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // Total + actions
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  14,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.money(vm.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: isEdit
                      ? 'Save changes'
                      : (vm.supplierCount > 1
                            ? 'Place ${vm.supplierCount} orders'
                            : 'Place order'),
                  icon: Icons.check_circle_outline,
                  onPressed: items.isEmpty || vm.needsSupplier
                      ? null
                      : () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Your invoice can be downloaded once the supplier approves the order.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Supplier heading inside the bucket, with that supplier's subtotal.
class _GroupHeader extends StatelessWidget {
  final String name;
  final double subtotal;
  const _GroupHeader({required this.name, required this.subtotal});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
    child: Row(
      children: [
        const Icon(
          Icons.local_shipping_outlined,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            Formatters.money(subtotal),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Lets the doctor pick which supplier fulfils admin-catalog items.
class _AssignSupplier extends StatelessWidget {
  final OrderViewModel vm;
  const _AssignSupplier({required this.vm});

  @override
  Widget build(BuildContext context) {
    final count = vm.bucket.where((p) => p.supplierId == null).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count admin-catalog item${count == 1 ? '' : 's'} need a supplier. Choose who should fulfil ${count == 1 ? 'it' : 'them'}.',
                  style: const TextStyle(fontSize: 12.5, height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: vm.unassignedSupplierId,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'Choose supplier',
              prefixIcon: Icon(Icons.local_shipping_outlined),
            ),
            items: [
              for (final s in vm.suppliers)
                DropdownMenuItem(value: s.uid, child: Text(s.name)),
            ],
            onChanged: vm.setUnassignedSupplier,
          ),
        ],
      ),
    );
  }
}
