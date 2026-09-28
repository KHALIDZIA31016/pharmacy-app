import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/category_style.dart';

/// Product photo if there is one, otherwise the category icon on a tinted box.
class SupplyImage extends StatelessWidget {
  final String? path;
  final CategoryStyle style;
  final double size;
  final double radius;

  const SupplyImage({
    super.key,
    required this.path,
    required this.style,
    this.size = 44,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(style.icon, color: style.color, size: size * 0.5),
    );
    final p = path;
    if (p == null || p.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(p),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
