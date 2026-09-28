import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? color;

  /// Optional profile photo; falls back to initials.
  final String? path;

  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 28,
    this.color,
    this.path,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final photo = path;
    if (photo != null && photo.isNotEmpty && File(photo).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(photo)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.withValues(alpha: 0.14),
      child: Text(
        Formatters.initials(name),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }
}

/// FileImage for a saved profile photo, or null when there is none.
ImageProvider? profileImage(String? path) {
  if (path == null || path.isEmpty) return null;
  final f = File(path);
  return f.existsSync() ? FileImage(f) : null;
}
