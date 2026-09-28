import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/user_repository.dart';

/// Data for the doctor/pharmacist home tab and their order history.
class UserHomeViewModel extends ChangeNotifier {
  final OrderRepository _orders;
  final UserRepository _users;
  UserHomeViewModel(this._orders, this._users);

  bool loading = false;
  List<Order> orders = [];
  List<AppUser> suppliers = [];

  Order? get latestDelivered {
    for (final o in orders) {
      if (o.isDelivered) return o;
    }
    return null;
  }

  Future<void> load(String uid) async {
    loading = true;
    notifyListeners();
    orders = await _orders.forUser(uid);
    suppliers = await _users.suppliers();
    loading = false;
    notifyListeners();
  }
}
