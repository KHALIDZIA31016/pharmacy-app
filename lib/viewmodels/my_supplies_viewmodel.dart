import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/supply_suggestions.dart';
import '../data/models/app_user.dart';
import '../data/models/product.dart';
import '../data/models/supply_change.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/supply_change_repository.dart';

/// A supplier's own supplies. Every add / edit / delete becomes a request
/// that the admin must approve before the live list changes.
class MySuppliesViewModel extends ChangeNotifier {
  final ProductRepository _products;
  final SupplyChangeRepository _changes;
  MySuppliesViewModel(this._products, this._changes);

  AppUser? _supplier;
  bool loading = false;
  List<Product> products = [];
  List<SupplyChange> changes = [];
  String query = '';
  String? category;

  Future<void> load(AppUser supplier) async {
    _supplier = supplier;
    loading = true;
    notifyListeners();
    products = await _products.bySupplier(supplier.uid);
    changes = await _changes.forSupplier(supplier.uid);
    loading = false;
    notifyListeners();
  }

  // ---- derived state

  SupplyChange? pendingFor(Product p) =>
      changes.where((c) => c.isPending && c.productId == p.id).firstOrNull;

  List<SupplyChange> get pendingAdds => changes
      .where((c) => c.isPending && c.action == ChangeAction.add)
      .toList();

  int get pendingCount => changes.where((c) => c.isPending).length;

  List<String> get categories => ({
    ...products.map((p) => p.category),
    ...changes.map((c) => c.category),
    ...supplySuggestions.map((s) => s.$2),
  }.toList()..sort());

  /// Relevance of [name]/[cat] to the search query (0 = no match).
  int _score(String name, String cat) {
    if (category != null && cat != category) return -1;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 1;
    final n = name.toLowerCase();
    if (n == q) return 100;
    if (n.startsWith(q)) return 80;
    if (n.split(RegExp(r'[\s(]+')).any((w) => w.startsWith(q))) return 60;
    if (n.contains(q)) return 40;
    if (cat.toLowerCase().contains(q)) return 20;
    return 0;
  }

  /// Keeps matches only, best match first (original order when no query).
  List<T> _rank<T>(
    Iterable<T> items,
    String Function(T) name,
    String Function(T) cat,
  ) {
    final scored = [
      for (final i in items) (i, _score(name(i), cat(i))),
    ].where((e) => e.$2 > 0).toList();
    if (query.trim().isNotEmpty) {
      scored.sort((a, b) => b.$2.compareTo(a.$2));
    }
    return [for (final e in scored) e.$1];
  }

  List<Product> get filteredProducts =>
      _rank(products, (p) => p.name, (p) => p.category);

  List<SupplyChange> get filteredPendingAdds =>
      _rank(pendingAdds, (c) => c.name, (c) => c.category);

  /// Price-list items the supplier has not added or requested yet.
  List<(String, String, String, double)> get suggestions => _rank(
    supplySuggestions.where((s) => !takenNames.contains(s.$1.toLowerCase())),
    (s) => s.$1,
    (s) => s.$2,
  );

  /// True if the latest add-request for [name] was declined by the admin.
  bool wasDeclined(String name) {
    final n = name.toLowerCase();
    final last = changes
        .where((c) => c.action == ChangeAction.add && c.name.toLowerCase() == n)
        .firstOrNull; // newest first
    return last != null && last.status == RequestStatus.rejected;
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setCategory(String? c) {
    category = c;
    notifyListeners();
  }

  // ---- requests (return an error message, or null on success)

  Future<String?> requestAdd(
    String name,
    String category,
    String unit,
    double price, {
    String? imagePath,
  }) async {
    final n = name.trim().toLowerCase();
    final exists =
        products.any((p) => p.name.toLowerCase() == n) ||
        pendingAdds.any((c) => c.name.toLowerCase() == n);
    if (exists) {
      return '"$name" is already in your supplies or awaiting approval.';
    }
    await _submit(
      SupplyChange(
        supplierId: _supplier!.uid,
        supplierName: _supplier!.name,
        action: ChangeAction.add,
        name: name.trim(),
        category: category.trim(),
        unit: unit.trim(),
        price: price,
        imagePath: imagePath,
        createdAt: DateTime.now(),
      ),
    );
    return null;
  }

  /// Names already live or requested (lower-case).
  Set<String> get takenNames => {
    ...products.map((p) => p.name.toLowerCase()),
    ...pendingAdds.map((c) => c.name.toLowerCase()),
  };

  Future<String?> requestUpdate(
    Product p,
    String name,
    String category,
    String unit,
    double price, {
    String? imagePath,
  }) async {
    if (pendingFor(p) != null) {
      return 'This supply already has a change awaiting approval.';
    }
    final n = name.trim().toLowerCase();
    if (products.any((o) => o.id != p.id && o.name.toLowerCase() == n)) {
      return 'You already have a supply called "$name".';
    }
    await _submit(
      SupplyChange(
        supplierId: _supplier!.uid,
        supplierName: _supplier!.name,
        action: ChangeAction.update,
        productId: p.id,
        name: name.trim(),
        category: category.trim(),
        unit: unit.trim(),
        price: price,
        oldName: p.name,
        oldCategory: p.category,
        oldUnit: p.unit,
        oldPrice: p.price,
        imagePath: imagePath,
        createdAt: DateTime.now(),
      ),
    );
    return null;
  }

  Future<String?> requestDelete(Product p) async {
    if (pendingFor(p) != null) {
      return 'This supply already has a change awaiting approval.';
    }
    await _submit(
      SupplyChange(
        supplierId: _supplier!.uid,
        supplierName: _supplier!.name,
        action: ChangeAction.delete,
        productId: p.id,
        name: p.name,
        category: p.category,
        unit: p.unit,
        price: p.price,
        oldName: p.name,
        oldCategory: p.category,
        oldUnit: p.unit,
        oldPrice: p.price,
        createdAt: DateTime.now(),
      ),
    );
    return null;
  }

  Future<void> _submit(SupplyChange c) async {
    await _changes.create(c);
    await load(_supplier!);
  }
}
