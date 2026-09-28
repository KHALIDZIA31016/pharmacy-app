import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/models/order.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/user_repository.dart';

/// Everything the supplier tabs need: dashboard, other suppliers, orders.
class SupplierViewModel extends ChangeNotifier {
  final OrderRepository _orders;
  final UserRepository _users;
  final NotificationRepository _notifications;

  SupplierViewModel(this._orders, this._users, this._notifications);

  String? _uid;
  bool loading = false;
  List<Order> orders = [];
  List<AppUser> buyers = [];
  String? statusFilter; // null = all
  String doctorQuery = '';

  List<Order> get filteredOrders => statusFilter == null
      ? orders
      : orders.where((o) => o.status == statusFilter).toList();

  int get pendingCount => orders
      .where(
        (o) =>
            o.status == OrderStatus.placed || o.status == OrderStatus.confirmed,
      )
      .length;
  int get deliveredCount => orders.where((o) => o.isDelivered).length;
  double get revenue =>
      orders.where((o) => o.isDelivered).fold(0.0, (s, o) => s + o.total);

  Future<void> load(String uid) async {
    _uid = uid;
    loading = true;
    notifyListeners();
    orders = await _orders.forSupplier(uid);
    buyers = await _users.buyers();
    loading = false;
    notifyListeners();
  }

  List<AppUser> get filteredBuyers {
    final q = doctorQuery.trim().toLowerCase();
    if (q.isEmpty) return buyers;
    return buyers
        .where(
          (b) =>
              b.name.toLowerCase().contains(q) ||
              b.organization.toLowerCase().contains(q) ||
              b.roleLabel.toLowerCase().contains(q),
        )
        .toList();
  }

  void setDoctorQuery(String v) {
    doctorQuery = v;
    notifyListeners();
  }

  /// Orders (not cancelled) a doctor has placed with this supplier.
  int ordersFrom(String uid) => orders
      .where((o) => o.userId == uid && o.status != OrderStatus.cancelled)
      .length;

  double spentBy(String uid) => orders
      .where((o) => o.userId == uid && o.status != OrderStatus.cancelled)
      .fold(0.0, (s, o) => s + o.total);

  int countWhere(String? status) => status == null
      ? orders.length
      : orders.where((o) => o.status == status).length;

  void setFilter(String? status) {
    statusFilter = status;
    notifyListeners();
  }

  Future<void> updateStatus(Order order, String status) async {
    await _orders.updateStatus(order.id!, status);
    await _notifications.add(
      order.userId,
      'Order #${order.id} $status',
      '${order.supplierName} marked your order as $status.',
    );
    if (_uid != null) await load(_uid!);
  }
}
