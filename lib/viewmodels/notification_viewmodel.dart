import 'package:flutter/foundation.dart';

import '../data/models/app_notification.dart';
import '../data/repositories/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repo;
  NotificationViewModel(this._repo);

  String? _uid;
  List<AppNotification> items = [];

  int get unread => items.where((n) => !n.isRead).length;

  Future<void> load(String uid) async {
    _uid = uid;
    await refresh();
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    items = await _repo.forUser(uid);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null || unread == 0) return;
    await _repo.markAllRead(uid);
    await refresh();
  }

  void clear() {
    _uid = null;
    items = [];
    notifyListeners();
  }
}
