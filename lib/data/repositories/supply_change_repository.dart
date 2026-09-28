import '../../core/constants/app_constants.dart';
import '../local/database_helper.dart';
import '../models/supply_change.dart';

class SupplyChangeRepository {
  final DatabaseHelper _helper;
  SupplyChangeRepository([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  Future<void> create(SupplyChange c) async {
    final db = await _helper.database;
    await db.insert('supply_changes', c.toMap());
  }

  Future<List<SupplyChange>> forSupplier(String uid) =>
      _query(where: 'supplier_id = ?', args: [uid]);

  Future<List<SupplyChange>> all() => _query();

  Future<List<SupplyChange>> _query({
    String? where,
    List<Object?>? args,
  }) async {
    final db = await _helper.database;
    final rows = await db.query(
      'supply_changes',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(SupplyChange.fromMap).toList();
  }

  /// Applies the change to the live catalog and marks it approved.
  /// Returns false (and marks it rejected) if the target product no longer exists.
  Future<bool> approve(SupplyChange c) async {
    final db = await _helper.database;
    return db.transaction((txn) async {
      var applied = true;
      switch (c.action) {
        case ChangeAction.add:
          await txn.insert('products', {
            'name': c.name,
            'category': c.category,
            'unit': c.unit,
            'price': c.price,
            'supplier_id': c.supplierId,
            'image_path': c.imagePath,
          });
        case ChangeAction.update:
          applied =
              await txn.update(
                'products',
                {
                  'name': c.name,
                  'category': c.category,
                  'unit': c.unit,
                  'price': c.price,
                  if (c.imagePath != null) 'image_path': c.imagePath,
                },
                where: 'id = ? AND supplier_id = ?',
                whereArgs: [c.productId, c.supplierId],
              ) >
              0;
        case ChangeAction.delete:
          applied =
              await txn.delete(
                'products',
                where: 'id = ? AND supplier_id = ?',
                whereArgs: [c.productId, c.supplierId],
              ) >
              0;
      }
      await txn.update(
        'supply_changes',
        {'status': applied ? RequestStatus.approved : RequestStatus.rejected},
        where: 'id = ?',
        whereArgs: [c.id],
      );
      return applied;
    });
  }

  Future<void> reject(int id) async {
    final db = await _helper.database;
    await db.update(
      'supply_changes',
      {'status': RequestStatus.rejected},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
