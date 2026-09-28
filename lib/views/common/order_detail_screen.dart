import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui.dart';
import '../../data/models/app_user.dart';
import '../../data/models/order.dart';
import '../../data/repositories/user_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/nav_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/user_home_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/invoice_tile.dart';
import '../../widgets/user_avatar.dart';

/// Full order view: status tracking, parties, items, invoice, and (for the
/// doctor) edit / cancel / delete / reorder.
class OrderDetailScreen extends StatelessWidget {
  final Order order;
  final bool asSupplier;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.asSupplier = false,
  });

  // ------------------------------------------------------------- helpers

  Color get _accent => switch (order.status) {
    OrderStatus.delivered => AppColors.success,
    OrderStatus.confirmed => AppColors.primary,
    OrderStatus.cancelled => AppColors.danger,
    _ => AppColors.warning,
  };

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  // ----------------------------------------------------------------- CRUD

  Future<void> _edit(BuildContext context) async {
    final vm = context.read<OrderViewModel>();
    final nav = context.read<NavViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final skipped = await vm.startEdit(order);
    if (!context.mounted) return;
    if (skipped < 0) {
      return showSnack(
        context,
        'This supplier is no longer available.',
        error: true,
      );
    }
    nav.setIndex(1);
    Navigator.popUntil(context, (r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            skipped == 0
                ? 'Editing order #${order.id}. Change items and save.'
                : '$skipped item(s) are no longer stocked and were left out.',
          ),
        ),
      );
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Cancel this order?',
      message:
          '${order.supplierName} will be told the order was cancelled. You can delete it afterwards.',
      action: 'Cancel order',
    );
    if (!ok || !context.mounted) return;
    final user = context.read<AuthViewModel>().user!;
    final vm = context.read<OrderViewModel>();
    final home = context.read<UserHomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final done = await vm.cancelOrder(order, user);
    await home.load(user.uid);
    if (!context.mounted) return;
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            done
                ? 'Order #${order.id} cancelled'
                : 'The supplier already confirmed this order, so it cannot be cancelled.',
          ),
        ),
      );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Delete this order?',
      message: 'It will be removed from your order history for good.',
      action: 'Delete',
    );
    if (!ok || !context.mounted) return;
    final user = context.read<AuthViewModel>().user!;
    final vm = context.read<OrderViewModel>();
    final home = context.read<UserHomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    await vm.deleteOrder(order);
    await home.load(user.uid);
    if (!context.mounted) return;
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Order #${order.id} deleted'),
        ),
      );
  }

  // -------------------------------------------------------------- reorder

  Future<void> _reorder(BuildContext context, AppUser target) async {
    final orders = context.read<OrderViewModel>();
    final nav = context.read<NavViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final skipped = await orders.prefillFromOrder(order, target);
    nav.setIndex(1);
    if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            skipped == 0
                ? 'Items added from order #${order.id}. Review and place the order.'
                : '$skipped item(s) are not stocked by ${target.name} and were skipped.',
          ),
        ),
      );
  }

  Future<void> _reorderSame(BuildContext context) async {
    final supplier = await context.read<UserRepository>().getById(
      order.supplierId,
    );
    if (!context.mounted) return;
    if (supplier == null) {
      return showSnack(
        context,
        'This supplier is no longer available.',
        error: true,
      );
    }
    await _reorder(context, supplier);
  }

  Future<void> _reorderOther(BuildContext context) async {
    final all = await context.read<UserRepository>().suppliers();
    final others = all.where((s) => s.uid != order.supplierId).toList();
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<AppUser>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: others.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No other suppliers available.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Reorder from…',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final s in others)
                    ListTile(
                      leading: UserAvatar(
                        name: s.name,
                        radius: 20,
                        path: s.photoPath,
                      ),
                      title: Text(s.name),
                      subtitle: Text(s.address),
                      onTap: () => Navigator.pop(ctx, s),
                    ),
                ],
              ),
      ),
    );
    if (picked != null && context.mounted) await _reorder(context, picked);
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final who = asSupplier ? order.userName : order.supplierName;
    final open = order.status == OrderStatus.placed;

    return Scaffold(
      body: Column(
        children: [
          _Hero(order: order, accent: _accent),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                _Tracker(order: order),
                const SizedBox(height: 14),
                _Card(
                  child: Row(
                    children: [
                      UserAvatar(name: who, radius: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asSupplier ? 'ORDERED BY' : 'SUPPLIER',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              who,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ITEMS · ${order.itemCount}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.qty}×',
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${Formatters.money(item.price)} · ${item.unit}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.money(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
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
                ),
                if (order.notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(order.notes)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                InvoiceTile(order: order, asSupplier: asSupplier),
                if (!asSupplier) ...[
                  const SizedBox(height: 22),
                  if (open) ...[
                    AppButton(
                      label: 'Edit order',
                      icon: Icons.edit_outlined,
                      onPressed: () => _edit(context),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _cancel(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text(
                        'Cancel order',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  if (order.status == OrderStatus.cancelled)
                    OutlinedButton.icon(
                      onPressed: () => _delete(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text(
                        'Delete order',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (order.status == OrderStatus.confirmed)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'The supplier has confirmed this order, so it can no longer be edited or cancelled.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const Text(
                    'ORDER AGAIN',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Reorder from ${order.supplierName}',
                    icon: Icons.replay_rounded,
                    outlined: true,
                    onPressed: () => _reorderSame(context),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Reorder from a different supplier',
                    icon: Icons.swap_horiz_rounded,
                    outlined: true,
                    onPressed: () => _reorderOther(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

/// Pinned gradient header: order number, total and status.
class _Hero extends StatelessWidget {
  final Order order;
  final Color accent;
  const _Hero({required this.order, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
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
          Positioned(right: -30, top: -8, child: _ring(120)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER #${order.id}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.money(order.total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              letterSpacing: -0.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Placed ${Formatters.dateTime(order.createdAt)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        Formatters.capitalize(order.status),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
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

/// Vertical order tracker: placed -> confirmed -> delivered (or cancelled).
class _Tracker extends StatelessWidget {
  final Order order;
  const _Tracker({required this.order});

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == OrderStatus.cancelled;
    final reached = switch (order.status) {
      OrderStatus.confirmed => 1,
      OrderStatus.delivered => 2,
      _ => 0,
    };

    final steps = cancelled
        ? [
            _StepData(
              Icons.receipt_long_outlined,
              'Order placed',
              Formatters.dateTime(order.createdAt),
              AppColors.success,
              done: true,
            ),
            _StepData(
              Icons.cancel_outlined,
              'Order cancelled',
              'This order will not be delivered',
              AppColors.danger,
              done: true,
            ),
          ]
        : [
            _StepData(
              Icons.receipt_long_outlined,
              'Order placed',
              Formatters.dateTime(order.createdAt),
              AppColors.success,
              done: true,
            ),
            _StepData(
              Icons.thumb_up_alt_outlined,
              'Confirmed by supplier',
              reached >= 1
                  ? '${order.supplierName} accepted your order'
                  : 'Waiting for ${order.supplierName}',
              AppColors.primary,
              done: reached >= 1,
            ),
            _StepData(
              Icons.local_shipping_outlined,
              'Delivered',
              order.deliveredAt != null
                  ? Formatters.dateTime(order.deliveredAt!)
                  : 'Arrives after confirmation',
              AppColors.success,
              done: reached >= 2,
            ),
          ];
    final current = steps.indexWhere((s) => !s.done);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRACK ORDER',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 38,
                    child: Column(
                      children: [
                        _node(steps[i], isCurrent: i == current),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 3,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: steps[i].done && steps[i + 1].done
                                    ? steps[i + 1].color
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < steps.length - 1 ? 18 : 0,
                        top: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: steps[i].done || i == current
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            steps[i].subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _node(_StepData s, {required bool isCurrent}) {
    if (s.done) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: s.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: s.color.withValues(alpha: 0.35), blurRadius: 8),
          ],
        ),
        child: Icon(s.icon, color: Colors.white, size: 18),
      );
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? AppColors.warning : AppColors.border,
          width: 2,
        ),
      ),
      child: Icon(
        isCurrent ? Icons.hourglass_top_rounded : s.icon,
        size: 17,
        color: isCurrent ? AppColors.warning : AppColors.textSecondary,
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool done;
  const _StepData(
    this.icon,
    this.title,
    this.subtitle,
    this.color, {
    required this.done,
  });
}
