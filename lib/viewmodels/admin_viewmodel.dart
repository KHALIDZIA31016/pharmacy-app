import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/models/product.dart';
import '../data/models/supply_change.dart';
import '../data/models/supply_request.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/supply_change_repository.dart';
import '../data/repositories/user_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final ProductRepository _repo;
  final NotificationRepository _notifications;
  final UserRepository _users;
  final SupplyChangeRepository _changes;
  AdminViewModel(this._repo, this._notifications, this._users, this._changes);

  bool loading = false;
  List<SupplyRequest> requests = [];
  List<SupplyChange> changes = [];
  List<Product> products = [];
  List<AppUser> suppliers = [];
  List<AppUser> doctors = [];

  int get pendingRequests =>
      requests.where((r) => r.status == RequestStatus.pending).length;
  int get pendingChanges => changes.where((c) => c.isPending).length;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    requests = await _repo.allRequests();
    changes = await _changes.all();
    products = await _repo.all();
    suppliers = await _users.suppliers();
    doctors = await _users.buyers();
    loading = false;
    notifyListeners();
  }

  // ---- doctors' "please add this item" requests

  Future<void> approve(SupplyRequest r, String unit, double price) async {
    await _repo.approveRequest(r, unit, price);
    await _notifications.add(
      r.userId,
      'Request approved',
      '"${r.name}" has been added to the supplies list.',
    );
    await load();
  }

  Future<void> reject(SupplyRequest r) async {
    await _repo.rejectRequest(r.id!);
    await _notifications.add(
      r.userId,
      'Request declined',
      '"${r.name}" could not be added.',
    );
    await load();
  }

  // ---- suppliers' add / edit / delete requests

  String _verb(SupplyChange c) => switch (c.action) {
    ChangeAction.add => 'new supply',
    ChangeAction.update => 'update',
    _ => 'deletion',
  };

  Future<void> approveChange(SupplyChange c) async {
    final applied = await _changes.approve(c);
    await _notifications.add(
      c.supplierId,
      applied ? 'Supply change approved' : 'Supply change failed',
      applied
          ? 'Your ${_verb(c)} for "${c.name}" is now live.'
          : 'Your ${_verb(c)} for "${c.name}" could not be applied because the supply no longer exists.',
    );
    await load();
  }

  Future<void> rejectChange(SupplyChange c) async {
    await _changes.reject(c.id!);
    await _notifications.add(
      c.supplierId,
      'Supply change declined',
      'Your ${_verb(c)} for "${c.name}" was declined. Your list is unchanged.',
    );
    await load();
  }
}
