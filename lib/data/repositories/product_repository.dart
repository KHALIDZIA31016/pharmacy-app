import '../local/database_helper.dart';
import '../models/product.dart';
import '../models/supply_request.dart';
import '../../core/constants/app_constants.dart';

class ProductRepository {
  final DatabaseHelper _helper;
  ProductRepository([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  static const _select = '''
    SELECT p.*, u.name AS supplier_name
    FROM products p LEFT JOIN users u ON u.uid = p.supplier_id
  ''';

  Future<List<Product>> all() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('$_select ORDER BY p.name COLLATE NOCASE');
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> bySupplier(String supplierId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      '$_select WHERE p.supplier_id = ? ORDER BY p.name COLLATE NOCASE',
      [supplierId],
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<void> add(Product p) async {
    final db = await _helper.database;
    await db.insert('products', p.toMap());
  }

  Future<void> updatePrice(int id, double price) async {
    final db = await _helper.database;
    await db.update(
      'products',
      {'price': price},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Supply requests (user asks admin to add an item) ----

  Future<void> createRequest(SupplyRequest r) async {
    final db = await _helper.database;
    await db.insert('supply_requests', r.toMap());
  }

  Future<List<SupplyRequest>> requestsForUser(String uid) async {
    final db = await _helper.database;
    final rows = await db.query(
      'supply_requests',
      where: 'user_id = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
    );
    return rows.map(SupplyRequest.fromMap).toList();
  }

  Future<List<SupplyRequest>> allRequests() async {
    final db = await _helper.database;
    final rows = await db.query('supply_requests', orderBy: 'created_at DESC');
    return rows.map(SupplyRequest.fromMap).toList();
  }

  /// Approve: add the item to the catalog (no supplier) and mark approved.
  Future<void> approveRequest(
    SupplyRequest r,
    String unit,
    double price,
  ) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.insert('products', {
        'name': r.name,
        'category': 'Requested',
        'unit': unit,
        'price': price,
        'supplier_id': null,
      });
      await txn.update(
        'supply_requests',
        {'status': RequestStatus.approved},
        where: 'id = ?',
        whereArgs: [r.id],
      );
    });
  }

  Future<void> rejectRequest(int id) async {
    final db = await _helper.database;
    await db.update(
      'supply_requests',
      {'status': RequestStatus.rejected},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
