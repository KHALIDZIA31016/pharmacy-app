import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../data/models/app_user.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/invoice_service.dart';

/// State of the doctor's "order supplies" tab and order CRUD.
///
/// The list shows every supply of every supplier (optionally filtered to one
/// supplier). Selected supplies go into one bucket; submitting places one
/// order per supplier.
class OrderViewModel extends ChangeNotifier {
  final UserRepository _users;
  final ProductRepository _products;
  final OrderRepository _orders;
  final NotificationRepository _notifications;

  OrderViewModel(
    this._users,
    this._products,
    this._orders,
    this._notifications,
  );

  List<AppUser> suppliers = [];
  Map<String, int> productCounts = {}; // supplier uid -> number of supplies
  /// Every approved supply: suppliers' own items plus admin-catalog items
  /// (approved doctor requests) that have no supplier yet.
  List<Product> allProducts = [];

  static const kNoSupplier = '_none';

  /// Supplier chosen to fulfil admin-catalog items in the bucket.
  String? unassignedSupplierId;

  /// Current supplier filter; null = all suppliers.
  AppUser? supplier;

  final Map<int, int> _cart = {}; // product id -> qty (any supplier)
  String notes = '';
  String query = '';
  String? category;
  bool loading = false;
  bool placing = false;
  String? error;

  /// Set while the doctor is editing an already-placed order.
  Order? editing;

  // ------------------------------------------------------------- loading

  Future<void> loadSuppliers() async {
    loading = true;
    notifyListeners();
    suppliers = await _users.suppliers();
    final all = await _products.all();
    allProducts = all;
    productCounts = {};
    for (final p in allProducts) {
      final s = p.supplierId;
      if (s != null) productCounts[s] = (productCounts[s] ?? 0) + 1;
    }
    loading = false;
    notifyListeners();
  }

  /// Supplies in the current scope (one supplier, or all).
  List<Product> get products => supplier == null
      ? allProducts
      : allProducts.where((p) => p.supplierId == supplier!.uid).toList();

  void selectSupplier(AppUser s) {
    supplier = s;
    query = '';
    category = null;
    notifyListeners();
  }

  void showAll() {
    supplier = null;
    query = '';
    category = null;
    notifyListeners();
  }

  // -------------------------------------------------------------- products

  List<String> get categories =>
      (products.map((p) => p.category).toSet().toList()..sort());

  /// 0 = no match, -1 = filtered out by category. Higher = more relevant.
  int _score(Product p) {
    if (category != null && p.category != category) return -1;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 1;
    final n = p.name.toLowerCase();
    if (n == q) return 100;
    if (n.startsWith(q)) return 80;
    if (n.split(RegExp(r'[\s(/-]+')).any((w) => w.startsWith(q))) return 60;
    if (n.contains(q)) return 40;
    if (p.category.toLowerCase().contains(q)) return 20;
    if (p.supplierName.toLowerCase().contains(q)) return 10;
    return 0;
  }

  /// Supplies matching the search and category, most relevant first.
  List<Product> get filteredProducts {
    final hasQuery = query.trim().isNotEmpty;
    final scored = [
      for (final p in products) (p, _score(p)),
    ].where((e) => e.$2 > 0).toList();
    scored.sort((a, b) {
      if (hasQuery && a.$2 != b.$2) return b.$2.compareTo(a.$2);
      return a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());
    });
    return [for (final e in scored) e.$1];
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setCategory(String? c) {
    category = c;
    notifyListeners();
  }

  int qtyOf(Product p) => _cart[p.id] ?? 0;

  void setQty(Product p, int qty) {
    if (qty <= 0) {
      _cart.remove(p.id);
    } else {
      _cart[p.id!] = qty;
    }
    notifyListeners();
  }

  bool get allFilteredSelected {
    final list = filteredProducts;
    return list.isNotEmpty && list.every((p) => qtyOf(p) > 0);
  }

  /// Adds one of every product in the current view that is not yet chosen.
  void selectAllFiltered() {
    for (final p in filteredProducts) {
      _cart.putIfAbsent(p.id!, () => 1);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------- bucket

  /// Everything chosen, across suppliers.
  List<Product> get bucket => [
    for (final p in allProducts)
      if (qtyOf(p) > 0) p,
  ];

  /// Bucket grouped by supplier id (one future order each).
  Map<String, List<Product>> get bucketBySupplier {
    final map = <String, List<Product>>{};
    for (final p in bucket) {
      final key = p.supplierId ?? unassignedSupplierId ?? kNoSupplier;
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  /// The bucket holds admin-catalog items that no supplier owns yet.
  bool get hasUnassigned => bucket.any((p) => p.supplierId == null);

  /// Ordering is blocked until a supplier is chosen for those items.
  bool get needsSupplier => hasUnassigned && unassignedSupplierId == null;

  void setUnassignedSupplier(String? id) {
    unassignedSupplierId = id;
    notifyListeners();
  }

  String supplierNameFor(String id, List<Product> list) {
    if (id == kNoSupplier) return 'Choose a supplier';
    return suppliers.where((s) => s.uid == id).firstOrNull?.name ??
        list
            .firstWhere((p) => p.supplierId == id, orElse: () => list.first)
            .supplierName;
  }

  double subtotalFor(List<Product> list) =>
      list.fold(0.0, (s, p) => s + p.price * qtyOf(p));

  /// Lines for a draft invoice built straight from the bucket.
  List<InvoiceLine> get invoiceLines => [
    for (final p in bucket) InvoiceLine(p, qtyOf(p)),
  ];

  int get cartCount => _cart.values.fold(0, (a, b) => a + b);
  int get cartLines => bucket.length;
  int get supplierCount => bucketBySupplier.length;
  double get total => subtotalFor(bucket);

  // ---------------------------------------------------- reorder / edit modes

  /// Fills the bucket from a past order. Items the supplier does not stock are
  /// skipped; returns how many were skipped.
  Future<int> prefillFromOrder(Order order, AppUser target) async {
    await loadSuppliers();
    editing = null;
    _cart.clear();
    selectSupplier(target);
    return _fillCart(order, target.uid);
  }

  /// Loads an open order back into the bucket so it can be changed.
  /// Returns skipped items, or -1 when the supplier no longer exists.
  Future<int> startEdit(Order order) async {
    await loadSuppliers();
    final s =
        suppliers.where((x) => x.uid == order.supplierId).firstOrNull ??
        await _users.getById(order.supplierId);
    if (s == null) return -1;
    _cart.clear();
    selectSupplier(s);
    final skipped = _fillCart(order, s.uid);
    notes = order.notes;
    editing = order;
    notifyListeners();
    return skipped;
  }

  int _fillCart(Order order, String supplierId) {
    var skipped = 0;
    for (final item in order.items) {
      final match = allProducts
          .where(
            (p) =>
                p.supplierId == supplierId &&
                p.name.toLowerCase() == item.name.toLowerCase(),
          )
          .firstOrNull;
      if (match == null) {
        skipped++;
      } else {
        _cart[match.id!] = item.qty;
      }
    }
    notifyListeners();
    return skipped;
  }

  void cancelEdit() {
    editing = null;
    _cart.clear();
    notes = '';
    supplier = null;
    notifyListeners();
  }

  // ----------------------------------------------------------------- CRUD

  Order _build({
    required AppUser buyer,
    required String supplierId,
    required String supplierName,
    required List<Product> list,
    int? id,
    required DateTime createdAt,
  }) => Order(
    id: id,
    userId: buyer.uid,
    userName: buyer.name,
    supplierId: supplierId,
    supplierName: supplierName,
    status: OrderStatus.placed,
    total: subtotalFor(list),
    notes: notes.trim(),
    createdAt: createdAt,
    items: [
      for (final p in list)
        OrderItem(name: p.name, unit: p.unit, price: p.price, qty: qtyOf(p)),
    ],
  );

  /// Places one order per supplier in the bucket (or saves changes when
  /// [editing] is set). Every supplier is notified. Returns the saved orders;
  /// empty on failure.
  Future<List<Order>> placeOrder(AppUser buyer) async {
    if (bucket.isEmpty) return const [];
    if (needsSupplier) {
      error = 'Choose a supplier for the admin-catalog items first.';
      return const [];
    }
    placing = true;
    error = null;
    notifyListeners();

    try {
      final saved = <Order>[];
      final base = editing;

      if (base != null) {
        final list = bucket
            .where((p) => p.supplierId == base.supplierId)
            .toList();
        if (list.isEmpty) return const [];
        final order = _build(
          buyer: buyer,
          supplierId: base.supplierId,
          supplierName: base.supplierName,
          list: list,
          id: base.id,
          createdAt: base.createdAt,
        );
        final ok = await _orders.updateOrder(order);
        if (!ok) {
          error = 'This order can no longer be edited.';
          return const [];
        }
        await _notifications.add(
          base.supplierId,
          'Order #${order.id} updated',
          '${buyer.name} changed the order: ${order.itemCount} item(s), ${Formatters.money(order.total)}.',
        );
        await _notifications.add(
          buyer.uid,
          'Order #${order.id} updated',
          '${base.supplierName} has been notified of your changes.',
        );
        saved.add(order);
      } else {
        for (final entry in bucketBySupplier.entries) {
          final list = entry.value;
          final name = supplierNameFor(entry.key, list);
          final draft = _build(
            buyer: buyer,
            supplierId: entry.key,
            supplierName: name,
            list: list,
            createdAt: DateTime.now(),
          );
          final id = await _orders.place(draft);
          final order = _build(
            buyer: buyer,
            supplierId: entry.key,
            supplierName: name,
            list: list,
            id: id,
            createdAt: draft.createdAt,
          );
          await _notifications.add(
            entry.key,
            'New order #$id',
            '${buyer.name} ordered ${order.itemCount} item(s) worth ${Formatters.money(order.total)}.',
          );
          await _notifications.add(
            buyer.uid,
            'Order #$id placed',
            'Your order was sent to $name.',
          );
          saved.add(order);
        }
      }

      _cart.clear();
      notes = '';
      editing = null;
      unassignedSupplierId = null;
      return saved;
    } finally {
      placing = false;
      notifyListeners();
    }
  }

  /// Cancels an order that the supplier has not confirmed yet.
  Future<bool> cancelOrder(Order o, AppUser buyer) async {
    if (o.status != OrderStatus.placed) return false;
    await _orders.updateStatus(o.id!, OrderStatus.cancelled);
    await _notifications.add(
      o.supplierId,
      'Order #${o.id} cancelled',
      '${buyer.name} cancelled their order.',
    );
    return true;
  }

  /// Removes a cancelled order from the history.
  Future<bool> deleteOrder(Order o) async {
    if (o.status != OrderStatus.cancelled) return false;
    await _orders.delete(o.id!);
    return true;
  }
}
