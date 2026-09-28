import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class OnboardingPage {
  final IconData icon;
  final String title;
  final String body;
  const OnboardingPage(this.icon, this.title, this.body);
}

class OnboardingViewModel extends ChangeNotifier {
  static const pages = [
    OnboardingPage(
      Icons.local_shipping_outlined,
      'Order in seconds',
      'Restock clinic and pharmacy supplies from trusted suppliers with a few taps.',
    ),
    OnboardingPage(
      Icons.price_check_rounded,
      'Compare rates',
      'Explore live supply rates, request missing items and generate invoices instantly.',
    ),
    OnboardingPage(
      Icons.notifications_active_outlined,
      'Stay updated',
      'Get notified the moment your order is confirmed and delivered.',
    ),
  ];

  final controller = PageController();
  int index = 0;

  bool get isLast => index == pages.length - 1;

  void onPageChanged(int i) {
    index = i;
    notifyListeners();
  }

  void next() => controller.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsOnboardingSeen, true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
