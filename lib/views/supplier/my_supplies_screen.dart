import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui.dart';
import '../../data/models/product.dart';
import '../../data/models/supply_change.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/my_supplies_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/supply_detail_sheet.dart';
import '../../widgets/supply_image.dart';
import '../../widgets/supply_form_sheet.dart';
import 'my_requests_screen.dart';

/// One scrolling page: stats + search, then the supplier's own supplies,
/// then every item of the standard price list they can still add.
/// Add / edit / delete are sent to the admin for approval.
class MySuppliesScreen extends StatefulWidget {
  const MySuppliesScreen({super.key});

  @override
  State<MySuppliesScreen> createState() => _MySuppliesScreenState();
}

class _MySuppliesScreenState extends State<MySuppliesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MySuppliesViewModel>()
        ..setQuery('')
        ..setCategory(null);
      _reload();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() => context.read<MySuppliesViewModel>().load(
    context.read<AuthViewModel>().user!,
  );

  Future<void> _add({SupplyDraft? initial}) async {
    final vm = context.read<MySuppliesViewModel>();
    final draft = await showSupplyForm(
      context,
      initial: initial,
      categories: vm.categories,
    );
    if (draft == null) return;
    final error = await vm.requestAdd(
      draft.name,
      draft.category,
      draft.unit,
      draft.price,
      imagePath: draft.imagePath,
    );
    _report(error, 'Sent to admin for approval');
  }

  Future<void> _open(Product p) async {
    final vm = context.read<MySuppliesViewModel>();
    final result = await showSupplyDetail(
      context,
      product: p,
      pending: vm.pendingFor(p),
      categories: vm.categories,
    );
    if (result == null || !mounted) return;
    if (result.delete) return _delete(p);
    final d = result.draft!;
    final error = await vm.requestUpdate(
      p,
      d.name,
      d.category,
      d.unit,
      d.price,
      imagePath: d.imagePath,
    );
    _report(error, 'Edit request sent to admin');
  }

  Future<void> _openSuggestion((String, String, String, double) s) async {
    final vm = context.read<MySuppliesViewModel>();
    final result = await showSupplyDetail(
      context,
      product: Product(name: s.$1, category: s.$2, unit: s.$3, price: s.$4),
      isNew: true,
      categories: vm.categories,
    );
    final d = result?.draft;
    if (d == null || !mounted) return;
    final error = await vm.requestAdd(
      d.name,
      d.category,
      d.unit,
      d.price,
      imagePath: d.imagePath,
    );
    _report(error, 'Request sent to admin for approval');
  }

  Future<void> _delete(Product p) async {
    final vm = context.read<MySuppliesViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request deletion?'),
        content: Text(
          '"${p.name}" stays in your list until the admin approves the deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Request delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await vm.requestDelete(p);
    _report(error, 'Deletion sent to admin for approval');
  }

  void _report(String? error, String success) {
    if (!mounted) return;
    showSnack(context, error ?? success, error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MySuppliesViewModel>();
    final products = vm.filteredProducts;
    final pending = vm.filteredPendingAdds;
    final suggestions = vm.suggestions;
    final nothing = products.isEmpty && pending.isEmpty && suggestions.isEmpty;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(),
        icon: const Icon(Icons.add),
        label: const Text('New supply'),
      ),
      body: Column(
        children: [
          _Header(
            vm: vm,
            controller: _search,
            onRequests: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: nothing
                  ? ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.search_off_rounded,
                          title: vm.loading
                              ? 'Loading…'
                              : 'No matching supplies',
                          message: vm.loading
                              ? null
                              : 'Try another word, or tap "New supply" to request a custom item.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      children: [
                        if (products.isNotEmpty || pending.isNotEmpty) ...[
                          _SectionLabel(
                            'Your supplies',
                            '${products.length + pending.length}',
                          ),
                          for (final c in pending) ...[
                            _PendingAddCard(change: c),
                            const SizedBox(height: 10),
                          ],
                          for (final p in products) ...[
                            _SupplyCard(
                              product: p,
                              pending: vm.pendingFor(p),
                              onTap: () => _open(p),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                        if (suggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SectionLabel(
                            'Price list · tap an item to request',
                            '${suggestions.length}',
                          ),
                          for (final s in suggestions) ...[
                            _PriceListTile(
                              item: s,
                              declined: vm.wasDeclined(s.$1),
                              onTap: () => _openSuggestion(s),
                            ),
                            const SizedBox(height: 8),
                          ],
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

/// Pinned gradient header: title + requests shortcut, stats, search, chips.
class _Header extends StatelessWidget {
  final MySuppliesViewModel vm;
  final TextEditingController controller;
  final VoidCallback onRequests;

  const _Header({
    required this.vm,
    required this.controller,
    required this.onRequests,
  });

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData icon, String value, String label) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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

    OutlineInputBorder none() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        8,
        14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'My supplies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Badge(
                  isLabelVisible: vm.pendingCount > 0,
                  label: Text('${vm.pendingCount}'),
                  offset: const Offset(-4, 4),
                  child: IconButton.filledTonal(
                    tooltip: 'My requests',
                    onPressed: onRequests,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                    icon: const Icon(Icons.outbox_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  stat(
                    Icons.inventory_2_outlined,
                    '${vm.products.length}',
                    'Live supplies',
                  ),
                  Container(width: 1, height: 34, color: Colors.white24),
                  stat(
                    Icons.hourglass_top_rounded,
                    '${vm.pendingCount}',
                    'Awaiting admin',
                  ),
                  Container(width: 1, height: 34, color: Colors.white24),
                  stat(
                    Icons.list_alt_rounded,
                    '${vm.suggestions.length}',
                    'In price list',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: TextField(
              controller: controller,
              onChanged: vm.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name or category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: vm.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          controller.clear();
                          vm.setQuery('');
                        },
                      ),
                border: none(),
                enabledBorder: none(),
                focusedBorder: none(),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _Pill(
                  'All',
                  null,
                  selected: vm.category == null,
                  onTap: () => vm.setCategory(null),
                ),
                for (final c in vm.categories)
                  _Pill(
                    c,
                    CategoryStyle.of(c).icon,
                    selected: vm.category == c,
                    onTap: () => vm.setCategory(c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Pill(
    this.label,
    this.icon, {
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.primaryDark : Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? AppColors.primaryDark : Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String count;
  const _SectionLabel(this.title, this.count);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

class _SupplyCard extends StatelessWidget {
  final Product product;
  final SupplyChange? pending;
  final VoidCallback onTap;

  const _SupplyCard({
    required this.product,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(product.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: style.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _IconBox(style, product.imagePath),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    _Tag(product.category, style.color),
                                    _Tag(product.unit, AppColors.textSecondary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.money(product.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      if (pending != null) ...[
                        const SizedBox(height: 10),
                        _PendingBanner(change: pending!),
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

class _IconBox extends StatelessWidget {
  final CategoryStyle style;
  final String? path;
  const _IconBox(this.style, this.path);

  @override
  Widget build(BuildContext context) =>
      SupplyImage(path: path, style: style, size: 44, radius: 12);
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _PendingBanner extends StatelessWidget {
  final SupplyChange change;
  const _PendingBanner({required this.change});

  String get _text => switch (change.action) {
    ChangeAction.delete => 'Deletion awaiting admin approval',
    _ =>
      'Edit awaiting admin approval → '
          '${Formatters.money(change.price)} · ${change.unit}',
  };

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.hourglass_top_rounded,
          size: 16,
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PendingAddCard extends StatelessWidget {
  final SupplyChange change;
  const _PendingAddCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(change.category);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _IconBox(style, change.imagePath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                Text(
                  '${change.category} · ${change.unit}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'New · awaiting admin approval',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            Formatters.money(change.price),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Compact row for a price-list item the supplier has not added yet.
class _PriceListTile extends StatelessWidget {
  final (String, String, String, double) item;
  final bool declined;
  final VoidCallback onTap;

  const _PriceListTile({
    required this.item,
    required this.declined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(item.$2);
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Icon(style.icon, color: style.color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      declined
                          ? '${item.$3} · last request declined'
                          : '${item.$2} · ${item.$3}',
                      style: TextStyle(
                        fontSize: 12,
                        color: declined
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.money(item.$4),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
