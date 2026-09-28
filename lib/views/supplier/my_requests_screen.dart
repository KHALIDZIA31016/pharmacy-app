import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/supply_change.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/my_supplies_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/supply_image.dart';

/// Every request the supplier has sent to the admin, shown as a status
/// timeline and filterable by status.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  /// null = all
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MySuppliesViewModel>();
    final all = vm.changes;
    int count(String? s) =>
        s == null ? all.length : all.where((c) => c.status == s).length;
    final shown = _filter == null
        ? all
        : all.where((c) => c.status == _filter).toList();

    return Scaffold(
      body: Column(
        children: [
          _Header(
            pending: count(RequestStatus.pending),
            accepted: count(RequestStatus.approved),
            rejected: count(RequestStatus.rejected),
            filter: _filter,
            count: count,
            onFilter: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => vm.load(context.read<AuthViewModel>().user!),
              child: shown.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 90),
                        EmptyState(
                          icon: Icons.outbox_outlined,
                          title: switch (_filter) {
                            RequestStatus.pending => 'Nothing pending',
                            RequestStatus.rejected => 'No rejected requests',
                            RequestStatus.approved => 'No accepted requests',
                            _ => 'No requests yet',
                          },
                          message:
                              'Requests you send to the admin appear here.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => _TimelineRow(
                        change: shown[i],
                        isLast: i == shown.length - 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int pending;
  final int accepted;
  final int rejected;
  final String? filter;
  final int Function(String?) count;
  final ValueChanged<String?> onFilter;

  const _Header({
    required this.pending,
    required this.accepted,
    required this.rejected,
    required this.filter,
    required this.count,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = <(String?, String)>[
      (null, 'Requests'),
      (RequestStatus.pending, 'Pending'),
      (RequestStatus.rejected, 'Rejected'),
      (RequestStatus.approved, 'Accepted'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        8,
        16,
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
              const Text(
                'My requests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          // Status summary
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _summary(
                    Icons.hourglass_top_rounded,
                    '$pending',
                    'Pending',
                    const Color(0xFFFFD27A),
                  ),
                  _sep(),
                  _summary(
                    Icons.check_circle_rounded,
                    '$accepted',
                    'Accepted',
                    const Color(0xFF8CE0AE),
                  ),
                  _sep(),
                  _summary(
                    Icons.cancel_rounded,
                    '$rejected',
                    'Rejected',
                    const Color(0xFFFFA39A),
                  ),
                ],
              ),
            ),
          ),
          // Filter pills
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              scrollDirection: Axis.horizontal,
              children: [
                for (final (status, label) in tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Pill(
                      '$label · ${count(status)}',
                      selected: filter == status,
                      onTap: () => onFilter(status),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sep() => Container(width: 1, height: 34, color: Colors.white24);

  Widget _summary(IconData icon, String value, String label, Color color) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
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
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: selected ? AppColors.primaryDark : Colors.white,
        ),
      ),
    ),
  );
}

/// One request: a coloured status node on a vertical rail + the detail card.
class _TimelineRow extends StatelessWidget {
  final SupplyChange change;
  final bool isLast;
  const _TimelineRow({required this.change, required this.isLast});

  (Color, IconData, String) get _status => switch (change.status) {
    RequestStatus.approved => (
      AppColors.success,
      Icons.check_rounded,
      'Approved — now live in your supplies',
    ),
    RequestStatus.rejected => (
      AppColors.danger,
      Icons.close_rounded,
      'Declined — your list is unchanged',
    ),
    _ => (
      AppColors.warning,
      Icons.hourglass_top_rounded,
      'Waiting for admin review',
    ),
  };

  (String, IconData, Color) get _action => switch (change.action) {
    ChangeAction.add => (
      'New supply',
      Icons.add_circle_outline,
      AppColors.success,
    ),
    ChangeAction.update => ('Edit', Icons.edit_outlined, AppColors.primary),
    _ => ('Deletion', Icons.delete_outline, AppColors.danger),
  };

  @override
  Widget build(BuildContext context) {
    final (color, icon, message) = _status;
    final (actionLabel, actionIcon, actionColor) = _action;
    final style = CategoryStyle.of(change.category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: actionColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      actionIcon,
                                      size: 13,
                                      color: actionColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      actionLabel,
                                      style: TextStyle(
                                        color: actionColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                Formatters.timeAgo(change.createdAt),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SupplyImage(
                                path: change.imagePath,
                                style: style,
                                size: 46,
                                radius: 14,
                              ),
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
                                    const SizedBox(height: 2),
                                    Text(
                                      '${change.category} · ${change.unit}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.money(change.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          ..._changes(),
                        ],
                      ),
                    ),
                    // Status ribbon
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      color: color.withValues(alpha: 0.1),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Rate  Rs 120 → Rs 140" style rows for edit requests.
  List<Widget> _changes() {
    final c = change;
    if (c.action != ChangeAction.update) return const [];
    final rows = <(String, String, String)>[
      if (c.oldName != c.name) ('Name', c.oldName ?? '', c.name),
      if (c.oldCategory != c.category)
        ('Category', c.oldCategory ?? '', c.category),
      if (c.oldUnit != c.unit) ('Unit', c.oldUnit ?? '', c.unit),
      if (c.oldPrice != c.price)
        ('Rate', Formatters.money(c.oldPrice ?? 0), Formatters.money(c.price)),
      if (c.imagePath != null) ('Photo', 'current', 'new photo'),
    ];
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (final (field, from, to) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 66,
                      child: Text(
                        field,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        from,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        to,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }
}
