import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';

/// The single Drift database instance.
///
/// Injected at the app root with the on-disk database
/// (`lib/main.dart`) and overridden with an in-memory database in tests
/// (widget suites use `ProviderScope(overrides: [...])`).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'databaseProvider must be overridden at the app root or in tests',
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(databaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(databaseProvider)),
);

final movementRepositoryProvider = Provider<InventoryMovementRepository>(
  (ref) => InventoryMovementRepository(ref.watch(databaseProvider)),
);
