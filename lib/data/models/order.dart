import '../../core/constants/app_constants.dart';

class OrderItem {
  final String name;
  final String unit;
  final double price;
  final int qty;

  const OrderItem({
    required this.name,
    required this.unit,
    required this.price,
    required this.qty,
  });

  double get subtotal => price * qty;

  Map<String, Object?> toMap(int orderId) => {
    'order_id': orderId,
    'name': name,
    'unit': unit,
    'price': price,
    'qty': qty,
  };

  factory OrderItem.fromMap(Map<String, Object?> m) => OrderItem(
    name: m['name'] as String,
    unit: m['unit'] as String,
    price: (m['price'] as num).toDouble(),
    qty: m['qty'] as int,
  );
}

class Order {
  final int? id;
  final String userId;
  final String userName;
  final String supplierId;
  final String supplierName;
  final String status;
  final double total;
  final String notes;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.userId,
    required this.userName,
    required this.supplierId,
    required this.supplierName,
    this.status = OrderStatus.placed,
    required this.total,
    this.notes = '',
    required this.createdAt,
    this.deliveredAt,
    this.items = const [],
  });

  bool get isDelivered => status == OrderStatus.delivered;

  /// The supplier has accepted the order (confirmed or delivered). Invoices
  /// can only be downloaded / printed from this point on.
  bool get isApproved =>
      status == OrderStatus.confirmed || status == OrderStatus.delivered;
  int get itemCount => items.fold(0, (s, i) => s + i.qty);

  Order copyWith({List<OrderItem>? items}) => Order(
    id: id,
    userId: userId,
    userName: userName,
    supplierId: supplierId,
    supplierName: supplierName,
    status: status,
    total: total,
    notes: notes,
    createdAt: createdAt,
    deliveredAt: deliveredAt,
    items: items ?? this.items,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'user_name': userName,
    'supplier_id': supplierId,
    'supplier_name': supplierName,
    'status': status,
    'total': total,
    'notes': notes,
    'created_at': createdAt.millisecondsSinceEpoch,
    'delivered_at': deliveredAt?.millisecondsSinceEpoch,
  };

  factory Order.fromMap(Map<String, Object?> m) => Order(
    id: m['id'] as int,
    userId: m['user_id'] as String,
    userName: m['user_name'] as String,
    supplierId: m['supplier_id'] as String,
    supplierName: m['supplier_name'] as String,
    status: m['status'] as String,
    total: (m['total'] as num).toDouble(),
    notes: m['notes'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    deliveredAt: m['delivered_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m['delivered_at'] as int),
  );
}
