import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/features/dashboard/dashboard_screen.dart';
import 'package:mi_almacen_plus/features/inventory/history_screen.dart';
import 'package:mi_almacen_plus/features/inventory/movement_sheet_page.dart';
import 'package:mi_almacen_plus/features/inventory/movements_screen.dart';
import 'package:mi_almacen_plus/features/products/new_product_screen.dart';
import 'package:mi_almacen_plus/features/products/product_detail_screen.dart';
import 'package:mi_almacen_plus/features/products/products_screen.dart';
import 'package:mi_almacen_plus/features/profile/profile_screen.dart';

import 'app_shell.dart';

/// Central go_router configuration (design D7, spec 6.1).
///
/// Routes:
/// - `/dashboard` — Dashboard (shell tab)
/// - `/products` — Products list (shell tab)
/// - `/movements` — Global movements (shell tab, placeholder)
/// - `/profile` — Profile (shell tab, placeholder)
/// - `/products/new` — create product (full screen)
/// - `/products/:id` — ProductDetail (full screen, inline edit)
/// - `/products/:id/movement` — modal bottom-sheet page; `?type=out` preselects
///   an outgoing movement
/// - `/products/:id/history` — movement history (full screen)
///
/// A fresh `GlobalKey` is created per call so tests can build an isolated
/// router without sharing navigator state (the singleton `appRouter` below
/// keeps its state between tests otherwise).
GoRouter buildAppRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, _) => const ProductsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movements',
                builder: (_, _) => const MovementsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/products/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const NewProductScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'movement',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              opaque: false,
              barrierColor: Colors.transparent,
              transitionDuration: Duration.zero,
              transitionsBuilder: (_, _, _, child) => child,
              child: MovementSheetPage(
                productId: state.pathParameters['id']!,
                initialType: state.uri.queryParameters['type'] == 'out'
                    ? MovementType.outgoing
                    : MovementType.incoming,
              ),
            ),
          ),
          GoRoute(
            path: 'history',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) =>
                HistoryScreen(productId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}

/// App router singleton used by `lib/main.dart` (and any non-test entry).
final appRouter = buildAppRouter();
