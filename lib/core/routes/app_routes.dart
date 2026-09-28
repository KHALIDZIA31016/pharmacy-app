import 'package:flutter/material.dart';

import '../../data/models/app_user.dart';
import '../../views/admin/admin_home_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/signup_screen.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/supplier/supplier_shell.dart';
import '../../views/user/user_shell.dart';
import '../constants/app_constants.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';
  static const userHome = '/user';
  static const supplierHome = '/supplier';
  static const adminHome = '/admin';

  static String homeFor(AppUser u) => switch (u.role) {
    UserRole.admin => adminHome,
    UserRole.supplier => supplierHome,
    _ => userHome,
  };

  static Route<dynamic> onGenerate(RouteSettings s) {
    final Widget page = switch (s.name) {
      onboarding => const OnboardingScreen(),
      login => const LoginScreen(),
      signup => SignupScreen(role: s.arguments as String),
      forgot => const ForgotPasswordScreen(),
      userHome => const UserShell(),
      supplierHome => const SupplierShell(),
      adminHome => const AdminHomeScreen(),
      _ => const SplashScreen(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
