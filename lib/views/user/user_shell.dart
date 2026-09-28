import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/user_home_viewmodel.dart';
import '../../widgets/main_shell.dart';
import '../common/profile_screen.dart';
import 'explore_screen.dart';
import 'order_supplies_screen.dart';
import 'user_home_screen.dart';

/// Doctor / pharmacist bottom-navigation host.
class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().user!;
      context.read<UserHomeViewModel>().load(user.uid);
      context.read<NotificationViewModel>().load(user.uid);
      context.read<CatalogViewModel>().load(user.uid);
      context.read<OrderViewModel>().loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainShell(
      tabs: [
        ShellTab(
          'Home',
          Icons.home_outlined,
          Icons.home_rounded,
          UserHomeScreen(),
        ),
        ShellTab(
          'Order',
          Icons.shopping_bag_outlined,
          Icons.shopping_bag_rounded,
          OrderSuppliesScreen(),
        ),
        ShellTab(
          'Explore',
          Icons.search_rounded,
          Icons.manage_search_rounded,
          ExploreScreen(),
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
