import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../local/database_helper.dart';
import '../models/app_user.dart';

class UserRepository {
  final DatabaseHelper _helper;
  UserRepository([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  Future<AppUser?> getById(String uid) async {
    final db = await _helper.database;
    final rows = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  /// Inserts or replaces the profile.
  Future<void> save(AppUser user) async {
    final db = await _helper.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AppUser>> suppliers({String? excludeUid}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'users',
      where: 'role = ? AND uid != ?',
      whereArgs: [UserRole.supplier, excludeUid ?? ''],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<List<AppUser>> buyers({String? excludeUid}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'users',
      where: 'role = ? AND uid != ?',
      whereArgs: [UserRole.user, excludeUid ?? ''],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<void> saveFcmToken(String uid, String token) async {
    final db = await _helper.database;
    await db.update(
      'users',
      {'fcm_token': token},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }
}
