import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/entities/category.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/entities/user.dart';

import 'app_providers.dart';

/// Seeded owner user ('Dueño', design D10) — there is no auth flow in the MVP;
/// every product and movement references this user id.
final currentUserProvider = FutureProvider<User>((ref) {
  return ref.watch(userRepositoryProvider).getOrCreateDefault();
});

/// All active products as a reactive stream (design D11) — the UI auto-
/// refreshes after every create/update/movement without manual invalidation.
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll();
});

/// All categories as a reactive stream (design D11) — a quick-create shows up
/// in pickers immediately.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

/// Single product by id (design D11) — drives ProductDetail inline edit.
final productByIdProvider = StreamProvider.family<Product?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).watchById(id);
});

/// A product's movement trail, newest-first (design D11) — drives History.
final movementsForProductProvider =
    StreamProvider.family<List<InventoryMovement>, String>((ref, productId) {
  return ref.watch(movementRepositoryProvider).watchForProduct(productId);
});

/// Recent movements across all products, newest-first (design D11 / dash 5.1)
/// — drives the dashboard's recent-movements tile. Explicitly capped at 5 at
/// the data layer; the widget further caps the visible list.
final recentMovementsProvider = StreamProvider<List<InventoryMovement>>((ref) {
  return ref.watch(movementRepositoryProvider).watchRecent(limit: 5);
});
