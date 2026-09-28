import 'package:flutter/material.dart';

/// Icon + colour used to make each supply category instantly recognisable.
class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);

  static const _fallback = CategoryStyle(
    Icons.category_outlined,
    Color(0xFF5C6BC0),
  );

  static CategoryStyle of(String category) {
    final c = category.toLowerCase();
    if (c.contains('inject')) {
      return const CategoryStyle(Icons.vaccines_outlined, Color(0xFFE0526B));
    }
    if (c.contains('tablet') || c.contains('medicine')) {
      return const CategoryStyle(Icons.medication_outlined, Color(0xFF0E8A8C));
    }
    if (c.contains('fluid') || c.contains('iv')) {
      return const CategoryStyle(Icons.water_drop_outlined, Color(0xFF2F80ED));
    }
    if (c.contains('surg') || c.contains('consum')) {
      return const CategoryStyle(Icons.healing_outlined, Color(0xFFE59A1F));
    }
    if (c.contains('equip')) {
      return const CategoryStyle(
        Icons.monitor_heart_outlined,
        Color(0xFF8E5BD9),
      );
    }
    return _fallback;
  }
}
