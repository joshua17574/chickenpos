import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/widgets/pos_shell.dart';
import '../../presentation/features/menu/menu_screen.dart';
import '../../presentation/features/checkout/checkout_screen.dart';
import '../../presentation/features/receipt/receipt_screen.dart';
import '../../presentation/features/orders/kds_screen.dart';
import '../../presentation/features/admin/admin_screen.dart';
import '../../presentation/features/admin/menu_management_screen.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../domain/entities/order.dart';

/// Centralized route names to avoid magic strings.
abstract class Routes {
  static const login = '/login';
  static const menu = '/';
  static const checkout = '/checkout';
  static const receipt = '/receipt';
  static const kds = '/kds';
  static const admin = '/admin';
  static const menuManagement = '/admin/menu';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.menu,
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      // Full-screen flows (no nav rail) for focused tasks.
      GoRoute(
        path: Routes.checkout,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: Routes.receipt,
        builder: (context, state) =>
            ReceiptScreen(order: state.extra! as Order),
      ),
      GoRoute(
        path: Routes.menuManagement,
        builder: (_, __) => const MenuManagementScreen(),
      ),
      // Shell hosts the persistent navigation rail (tablet) / bottom bar (phone).
      ShellRoute(
        builder: (context, state, child) => PosShell(child: child),
        routes: [
          GoRoute(
            path: Routes.menu,
            builder: (_, __) => const MenuScreen(),
          ),
          GoRoute(
            path: Routes.kds,
            builder: (_, __) => const KdsScreen(),
          ),
          GoRoute(
            path: Routes.admin,
            builder: (_, __) => const AdminScreen(),
          ),
        ],
      ),
    ],
  );
});
