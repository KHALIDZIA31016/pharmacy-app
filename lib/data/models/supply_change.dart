import '../../core/constants/app_constants.dart';

/// A supplier's request to add / update / delete one of their supplies.
/// Nothing touches the live catalog until an admin approves it.
class SupplyChange {
  final int? id;
  final String supplierId;
  final String supplierName;
  final String action; // ChangeAction.*
  final int? productId;
  final String name;
  final String category;
  final String unit;
  final double price;

  /// Snapshot of the live product (update / delete) so the admin can compare.
  final String? oldName;
  final String? oldCategory;
  final String? oldUnit;
  final double? oldPrice;

  /// Photo for add; for update, non-null means "replace the photo".
  final String? imagePath;

  final String status;
  final DateTime createdAt;

  const SupplyChange({
    this.id,
    required this.supplierId,
    required this.supplierName,
    required this.action,
    this.productId,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    this.oldName,
    this.oldCategory,
    this.oldUnit,
    this.oldPrice,
    this.imagePath,
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  bool get isPending => status == RequestStatus.pending;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'supplier_id': supplierId,
    'supplier_name': supplierName,
    'action': action,
    'product_id': productId,
    'name': name,
    'category': category,
    'unit': unit,
    'price': price,
    'old_name': oldName,
    'old_category': oldCategory,
    'old_unit': oldUnit,
    'old_price': oldPrice,
    'image_path': imagePath,
    'status': status,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory SupplyChange.fromMap(Map<String, Object?> m) => SupplyChange(
    id: m['id'] as int,
    supplierId: m['supplier_id'] as String,
    supplierName: m['supplier_name'] as String,
    action: m['action'] as String,
    productId: m['product_id'] as int?,
    name: m['name'] as String,
    category: m['category'] as String,
    unit: m['unit'] as String,
    price: (m['price'] as num).toDouble(),
    oldName: m['old_name'] as String?,
    oldCategory: m['old_category'] as String?,
    oldUnit: m['old_unit'] as String?,
    oldPrice: (m['old_price'] as num?)?.toDouble(),
    imagePath: m['image_path'] as String?,
    status: m['status'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}
