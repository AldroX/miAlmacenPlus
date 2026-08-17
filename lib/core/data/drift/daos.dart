import 'package:drift/drift.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart'
    as domain;
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_rules.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';

part 'daos.g.dart';

/// DAO for user table access — V1 has no auth; a single owner row is seeded.
@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<User?> getById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<List<User>> getAll() => select(users).get();

  /// Reactive stream over all users (design D11) — the UI watches this
  /// instead of polling so it auto-refreshes after writes.
  Stream<List<User>> watchAll() => select(users).watch();
}

/// DAO for category table access.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<Category?> getById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<List<Category>> getAll() => select(categories).get();

  Future<int> count() => select(categories).get().then((c) => c.length);

  /// Inserts a category (used for inline quick-create, spec 3.3 Sc.1).
  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  /// Reactive stream over all categories (design D11) — a quick-create is
  /// reflected in the UI immediately.
  Stream<List<Category>> watchAll() => select(categories).watch();
}

/// DAO for product table access.
@DriftAccessor(tables: [Products, InventoryMovements])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<Product?> getById(String id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<Product>> getAll({bool onlyActive = true}) {
    final query = select(products);
    if (onlyActive) {
      query.where((p) => p.isActive.equals(true));
    }
    return query.get();
  }

  Future<List<Product>> getByCategory(
    String categoryId, {
    bool onlyActive = true,
  }) {
    final query = select(products)
      ..where((p) => p.categoryId.equals(categoryId));
    if (onlyActive) {
      query.where((p) => p.isActive.equals(true));
    }
    return query.get();
  }

  Future<int> count({bool onlyActive = true}) async {
    final rows = await getAll(onlyActive: onlyActive);
    return rows.length;
  }

  /// Inserts a new product.
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  Future<int> updateProduct(ProductsCompanion product) => (update(
    products,
  )..where((p) => p.id.equals(product.id.value))).write(product);

  Future<int> softDelete(String id) =>
      (update(products)..where((p) => p.id.equals(id))).write(
        ProductsCompanion(isActive: const Value(false)),
      );

  /// Recomputes currentStock as the projection of the full movement trail
  /// (spec 2.1: currentStock == f(movements)). Delegates the arithmetic to
  /// the pure domain rule [projectStock] — order-independent, so it is robust
  /// to movements sharing a timestamp; it also guards the invariant that a
  /// trail never projects below zero.
  Future<int> recomputeStock(String productId) async {
    final rows = await (select(
      inventoryMovements,
    )..where((m) => m.productId.equals(productId))).get();
    return projectStock(
      initialStock:
          0, // trails start at 0; INITIAL_STOCK movement covers seeding
      movements: rows
          .map(
            (row) => domain.InventoryMovement(
              id: row.id,
              productId: row.productId,
              userId: row.userId,
              type: MovementType.values[row.type],
              reason: MovementReason.values[row.reason],
              quantity: row.quantity,
              stockBefore: row.stockBefore,
              stockAfter: row.stockAfter,
              occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt),
            ),
          )
          .toList(),
    );
  }

  /// Reactive stream over products, newest-inserted first (design D11).
  /// [onlyActive] mirrors [getAll] so soft-deleted rows disappear live.
  Stream<List<Product>> watchAll({bool onlyActive = true}) {
    final query = select(products)..orderBy([(p) => OrderingTerm.desc(p.id)]);
    if (onlyActive) {
      query.where((p) => p.isActive.equals(true));
    }
    return query.watch();
  }

  /// Reactive stream for a single product row (design D11) — emits null once
  /// the row disappears (e.g. hard removal, never in the MVP).
  Stream<Product?> watchById(String id) => (select(
    products,
  )..where((p) => p.id.equals(id))).watchSingleOrNull();
}

/// DAO for inventory movement table access.
@DriftAccessor(tables: [InventoryMovements, Products])
class InventoryMovementDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryMovementDaoMixin {
  InventoryMovementDao(super.db);

  Future<InventoryMovement?> getById(String id) => (select(
    inventoryMovements,
  )..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<List<InventoryMovement>> getForProduct(
    String productId, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(inventoryMovements)
          ..where((m) => m.productId.equals(productId))
          ..orderBy([(m) => OrderingTerm.desc(m.occurredAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Inserts a movement and updates product stock atomically.
  /// Caller must wrap in a transaction (e.g., `db.transaction(() async { ... })`).
  Future<void> insertMovementWithStockUpdate(
    InventoryMovementsCompanion movement,
    int newStock,
  ) async {
    await attachedDatabase.into(inventoryMovements).insert(movement);
    await (attachedDatabase.update(products)
          ..where((p) => p.id.equals(movement.productId.value)))
        .write(ProductsCompanion(currentStock: Value(newStock)));
  }

  Future<int> count() => select(inventoryMovements).get().then((c) => c.length);

  /// Reactive stream over a product's movement trail, newest-first (design
  /// D11) — drives History and the dashboard's recent-movements tile.
  Stream<List<InventoryMovement>> watchForProduct(
    String productId, {
    int limit = 50,
  }) {
    return (select(inventoryMovements)
          ..where((m) => m.productId.equals(productId))
          ..orderBy([(m) => OrderingTerm.desc(m.occurredAt)])
          ..limit(limit))
        .watch();
  }

  /// Reactive stream over the most recent movements across all products,
  /// newest-first (design D11 / dash 5.1) — feeds the dashboard's
  /// recent-movements tile. [limit] caps the trail length; default 5 matches
  /// the Figma tile height (3 sample rows + buffer).
  Stream<List<InventoryMovement>> watchRecent({int limit = 5}) {
    return (select(inventoryMovements)
          ..orderBy([(m) => OrderingTerm.desc(m.occurredAt)])
          ..limit(limit))
        .watch();
  }
}
