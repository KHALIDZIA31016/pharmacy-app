class Validators {
  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return v.length < 6 ? 'Use at least 6 characters' : null;
  }

  static String? Function(String?) confirmPassword(
    String Function() original,
  ) =>
      (v) => v != original() ? 'Passwords do not match' : null;

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.trim().replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\+?\d{7,15}$').hasMatch(digits)
        ? null
        : 'Enter a valid phone number';
  }

  static String? positiveNumber(String? v) {
    final n = double.tryParse(v ?? '');
    return (n == null || n <= 0) ? 'Enter a valid amount' : null;
  }
}
