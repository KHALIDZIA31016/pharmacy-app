import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/models/product.dart';
import '../data/models/supply_request.dart';
import '../data/repositories/product_repository.dart';
import '../data/services/invoice_service.dart';

/// Explore-supplies tab: browse rates, request missing items, build invoices.
class CatalogViewModel extends ChangeNotifier {
  final ProductRepository _repo;
  CatalogViewModel(this._repo);

  List<Product> _all = [];
  List<SupplyRequest> requests = [];
  final Map<int, int> _selected = {}; // product id -> qty
  String query = '';
  String? category;
  bool loading = false;

  List<String> get categories =>
      (_all.map((p) => p.category).toSet().toList()..sort());

  List<Product> get filtered {
    final q = query.trim().toLowerCase();
    return _all.where((p) {
      if (category != null && p.category != category) return false;
      return q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.supplierName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> load(String uid) async {
    loading = true;
    notifyListeners();
    _all = await _repo.all();
    requests = await _repo.requestsForUser(uid);
    loading = false;
    notifyListeners();
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setCategory(String? c) {
    category = c;
    notifyListeners();
  }

  int qtyOf(Product p) => _selected[p.id] ?? 0;

  void setQty(Product p, int qty) {
    qty <= 0 ? _selected.remove(p.id) : _selected[p.id!] = qty;
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  List<InvoiceLine> get invoiceLines => [
    for (final p in _all)
      if (qtyOf(p) > 0) InvoiceLine(p, qtyOf(p)),
  ];

  int get selectedCount => _selected.values.fold(0, (a, b) => a + b);
  double get selectedTotal => InvoiceService.total(invoiceLines);

  Future<void> requestSupply(AppUser user, String name, String details) async {
    await _repo.createRequest(
      SupplyRequest(
        userId: user.uid,
        userName: user.name,
        name: name.trim(),
        details: details.trim(),
        createdAt: DateTime.now(),
      ),
    );
    requests = await _repo.requestsForUser(user.uid);
    notifyListeners();
  }
}
