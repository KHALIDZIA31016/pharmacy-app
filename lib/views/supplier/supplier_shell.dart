import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../widgets/main_shell.dart';
import '../common/profile_screen.dart';
import 'all_doctors_screen.dart';
import 'my_supplies_screen.dart';
import 'supplier_home_screen.dart';
import 'supplier_orders_screen.dart';

class SupplierShell extends StatefulWidget {
  const SupplierShell({super.key});

  @override
  State<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends State<SupplierShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().user!;
      context.read<SupplierViewModel>().load(user.uid);
      context.read<NotificationViewModel>().load(user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      centerAction: ShellAction(
        Icons.inventory_2_rounded,
        'My supplies',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MySuppliesScreen()),
        ),
      ),
      tabs: const [
        ShellTab(
          'Home',
          Icons.home_outlined,
          Icons.home_rounded,
          SupplierHomeScreen(),
        ),
        ShellTab(
          'Doctors',
          Icons.medical_services_outlined,
          Icons.medical_services_rounded,
          AllDoctorsScreen(),
        ),
        ShellTab(
          'Orders',
          Icons.receipt_long_outlined,
          Icons.receipt_long_rounded,
          SupplierOrdersScreen(),
        ),
        ShellTab(
          'Profile',
          Icons.person_outline,
          Icons.person_rounded,
          ProfileScreen(),
        ),
      ],
    );
  }
}
