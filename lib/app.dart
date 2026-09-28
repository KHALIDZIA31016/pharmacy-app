import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/supply_change_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/fcm_service.dart';
import 'data/services/invoice_service.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/catalog_viewmodel.dart';
import 'viewmodels/my_supplies_viewmodel.dart';
import 'viewmodels/nav_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'viewmodels/order_viewmodel.dart';
import 'viewmodels/supplier_viewmodel.dart';
import 'viewmodels/user_home_viewmodel.dart';

class PharmacyApp extends StatelessWidget {
  final AuthService authService;
  const PharmacyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Data layer
        Provider<AuthService>.value(value: authService),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<ProductRepository>(create: (_) => ProductRepository()),
        Provider<OrderRepository>(create: (_) => OrderRepository()),
        Provider<SupplyChangeRepository>(
          create: (_) => SupplyChangeRepository(),
        ),
        Provider<NotificationRepository>(
          create: (_) => NotificationRepository(),
        ),
        Provider<InvoiceService>(create: (_) => InvoiceService()),

        // View models
        ChangeNotifierProvider(
          create: (c) =>
              NotificationViewModel(c.read<NotificationRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AuthViewModel(
            authService,
            c.read<UserRepository>(),
            FcmService(
              c.read<UserRepository>(),
              c.read<NotificationRepository>(),
            ),
          )..onPushReceived = c.read<NotificationViewModel>().refresh,
        ),
        ChangeNotifierProvider(create: (_) => NavViewModel()),
        ChangeNotifierProvider(
          create: (c) => UserHomeViewModel(
            c.read<OrderRepository>(),
            c.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => OrderViewModel(
            c.read<UserRepository>(),
            c.read<ProductRepository>(),
            c.read<OrderRepository>(),
            c.read<NotificationRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => CatalogViewModel(c.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => SupplierViewModel(
            c.read<OrderRepository>(),
            c.read<UserRepository>(),
            c.read<NotificationRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => MySuppliesViewModel(
            c.read<ProductRepository>(),
            c.read<SupplyChangeRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => AdminViewModel(
            c.read<ProductRepository>(),
            c.read<NotificationRepository>(),
            c.read<UserRepository>(),
            c.read<SupplyChangeRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerate,
      ),
    );
  }
}
