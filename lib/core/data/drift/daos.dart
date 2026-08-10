import 'package:drift/drift.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';

part 'daos.g.dart';

/// DAO for user table access — V1 has no auth; a single owner row is seeded.
@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<User?> getById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<List<User>> getAll() => select(users).get();
}

/// DAO for category table access.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<Category?> getById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<List<Category>> getAll() => select(categories).get();

  Future<int> count() => select(categories).get().then((c) => c.length);
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

  Future<List<Product>> getByCategory(String categoryId, {bool onlyActive = true}) {
    final query = select(products)..where((p) => p.categoryId.equals(categoryId));
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
  Future<int> insertProduct(ProductsCompanion product) => into(products).insert(product);

  Future<int> updateProduct(ProductsCompanion product) =>
      (update(products)..where((p) => p.id.equals(product.id.value))).write(product);

  Future<int> softDelete(String id) =>
      (update(products)..where((p) => p.id.equals(id))).write(ProductsCompanion(isActive: const Value(false)));

  /// Recomputes currentStock as the projection of the full movement trail
  /// (spec 2.1: currentStock == f(movements)). A pure sum over quantities is
  /// order-independent, so it is robust to movements sharing a timestamp.
  Future<int> recomputeStock(String productId) async {
    final rows = await (select(inventoryMovements)
          ..where((m) => m.productId.equals(productId)))
        .get();
    var stock = 0;
    for (final row in rows) {
      stock += row.type == MovementType.incoming.index ? row.quantity : -row.quantity;
    }
    return stock;
  }
}

/// DAO for inventory movement table access.
@DriftAccessor(tables: [InventoryMovements, Products])
class InventoryMovementDao extends DatabaseAccessor<AppDatabase> with _$InventoryMovementDaoMixin {
  InventoryMovementDao(super.db);

  Future<InventoryMovement?> getById(String id) =>
      (select(inventoryMovements)..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<List<InventoryMovement>> getForProduct(String productId, {int limit = 50, int offset = 0}) {
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
}