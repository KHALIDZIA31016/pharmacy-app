class Product {
  final int? id;
  final String name;
  final String category;
  final String unit;
  final double price;
  final String? supplierId;
  final String? imagePath;

  /// Populated by joins; "Admin catalog" for items without a supplier.
  final String supplierName;

  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    this.supplierId,
    this.imagePath,
    this.supplierName = 'Admin catalog',
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'category': category,
    'unit': unit,
    'price': price,
    'supplier_id': supplierId,
    'image_path': imagePath,
  };

  factory Product.fromMap(Map<String, Object?> m) => Product(
    id: m['id'] as int?,
    name: m['name'] as String,
    category: m['category'] as String,
    unit: m['unit'] as String,
    price: (m['price'] as num).toDouble(),
    supplierId: m['supplier_id'] as String?,
    imagePath: m['image_path'] as String?,
    supplierName: m['supplier_name'] as String? ?? 'Admin catalog',
  );
}
