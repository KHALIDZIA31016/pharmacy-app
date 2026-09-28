import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class Formatters {
  static final _money = NumberFormat.currency(
    symbol: AppConstants.currency,
    decimalDigits: 2,
  );
  static final _moneyWhole = NumberFormat.currency(
    symbol: AppConstants.currency,
    decimalDigits: 0,
  );
  static final _date = DateFormat('d MMM yyyy');
  static final _dateTime = DateFormat('d MMM yyyy, h:mm a');

  static String money(num v) =>
      v == v.roundToDouble() ? _moneyWhole.format(v) : _money.format(v);
  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  static String timeAgo(DateTime d, [DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _date.format(d);
  }

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
