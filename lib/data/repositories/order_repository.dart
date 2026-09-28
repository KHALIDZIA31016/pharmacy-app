import '../../core/constants/app_constants.dart';
import '../local/database_helper.dart';
import '../models/order.dart';

class OrderRepository {
  final DatabaseHelper _helper;
  OrderRepository([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  Future<int> place(Order order) async {
    final db = await _helper.database;
    return db.transaction((txn) async {
      final id = await txn.insert('orders', order.toMap());
      for (final item in order.items) {
        await txn.insert('order_items', item.toMap(id));
      }
      return id;
    });
  }

  Future<List<Order>> forUser(String uid) => _list('user_id', uid);
  Future<List<Order>> forSupplier(String uid) => _list('supplier_id', uid);

  Future<List<Order>> _list(String column, String uid) async {
    final db = await _helper.database;
    final rows = await db.query(
      'orders',
      where: '$column = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
    );
    final orders = <Order>[];
    for (final row in rows) {
      final o = Order.fromMap(row);
      final items = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [o.id],
      );
      orders.add(o.copyWith(items: items.map(OrderItem.fromMap).toList()));
    }
    return orders;
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _helper.database;
    await db.update(
      'orders',
      {
        'status': status,
        if (status == OrderStatus.delivered)
          'delivered_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Replaces items / notes / total of an order that is still "placed".
  /// Returns false when the order can no longer be edited.
  Future<bool> updateOrder(Order order) async {
    final db = await _helper.database;
    return db.transaction((txn) async {
      final n = await txn.update(
        'orders',
        {'total': order.total, 'notes': order.notes},
        where: 'id = ? AND status = ?',
        whereArgs: [order.id, OrderStatus.placed],
      );
      if (n == 0) return false;
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );
      for (final item in order.items) {
        await txn.insert('order_items', item.toMap(order.id!));
      }
      return true;
    });
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete('order_items', where: 'order_id = ?', whereArgs: [id]);
      await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
    });
  }
}
