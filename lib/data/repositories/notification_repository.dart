import '../local/database_helper.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  final DatabaseHelper _helper;
  NotificationRepository([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  Future<void> add(String userId, String title, String body) async {
    final db = await _helper.database;
    await db.insert(
      'notifications',
      AppNotification(
        userId: userId,
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<List<AppNotification>> forUser(String uid) async {
    final db = await _helper.database;
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markAllRead(String uid) async {
    final db = await _helper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [uid],
    );
  }
}
