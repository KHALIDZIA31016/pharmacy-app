import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_notification.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationViewModel _vm;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<NotificationViewModel>();
    _vm.refresh();
  }

  @override
  void dispose() {
    // Keep unread highlighting visible during this visit, mark read on exit.
    _vm.markAllRead();
    super.dispose();
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return Formatters.date(d);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final all = vm.items;
    final shown = _unreadOnly ? all.where((n) => !n.isRead).toList() : all;

    // Flatten into day headers + cards.
    final rows = <Object>[];
    String? lastDay;
    for (final n in shown) {
      final label = _dayLabel(n.createdAt);
      if (label != lastDay) {
        rows.add(label);
        lastDay = label;
      }
      rows.add(n);
    }

    return Scaffold(
      body: Column(
        children: [
          _Header(
            unread: vm.unread,
            total: all.length,
            unreadOnly: _unreadOnly,
            onFilter: (v) => setState(() => _unreadOnly = v),
            onMarkAll: vm.markAllRead,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              child: rows.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 90),
                        EmptyState(
                          icon: _unreadOnly
                              ? Icons.done_all_rounded
                              : Icons.notifications_off_outlined,
                          title: _unreadOnly
                              ? 'You are all caught up'
                              : 'Nothing yet',
                          message: _unreadOnly
                              ? 'No unread notifications.'
                              : 'Order updates and alerts will show up here.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        if (row is String) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              4,
                              i == 0 ? 4 : 18,
                              4,
                              8,
                            ),
                            child: Text(
                              row.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NotificationTile(row as AppNotification),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unread;
  final int total;
  final bool unreadOnly;
  final ValueChanged<bool> onFilter;
  final VoidCallback onMarkAll;

  const _Header({
    required this.unread,
    required this.total,
    required this.unreadOnly,
    required this.onFilter,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        16,
        18,
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
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unread > 0)
                TextButton.icon(
                  onPressed: onMarkAll,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark all read'),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 0, 14),
            child: Text(
              unread > 0
                  ? 'You have $unread unread notification${unread == 1 ? '' : 's'}'
                  : 'You are all caught up',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                _Pill('All · $total', !unreadOnly, () => onFilter(false)),
                const SizedBox(width: 8),
                _Pill('Unread · $unread', unreadOnly, () => onFilter(true)),
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
  final bool selected;
  final VoidCallback onTap;
  const _Pill(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

/// Picks an icon and colour from the notification wording.
({IconData icon, Color color}) _styleFor(String title) {
  final t = title.toLowerCase();
  if (t.contains('declin') ||
      t.contains('cancel') ||
      t.contains('reject') ||
      t.contains('fail')) {
    return (icon: Icons.cancel_outlined, color: AppColors.danger);
  }
  if (t.contains('deliver') || t.contains('approved') || t.contains('live')) {
    return (icon: Icons.check_circle_outline, color: AppColors.success);
  }
  if (t.contains('confirm')) {
    return (icon: Icons.thumb_up_alt_outlined, color: AppColors.primary);
  }
  if (t.contains('new order')) {
    return (icon: Icons.shopping_bag_outlined, color: AppColors.accent);
  }
  if (t.contains('placed')) {
    return (icon: Icons.receipt_long_outlined, color: AppColors.primary);
  }
  if (t.contains('request') || t.contains('supply')) {
    return (icon: Icons.inventory_2_outlined, color: AppColors.warning);
  }
  return (icon: Icons.notifications_none_rounded, color: AppColors.primary);
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  const _NotificationTile(this.n);

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(n.title);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.isRead ? AppColors.surface : s.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: n.isRead ? AppColors.border : s.color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(s.icon, color: s.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: n.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!n.isRead)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.timeAgo(n.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
