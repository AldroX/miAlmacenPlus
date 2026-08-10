import 'package:drift/drift.dart' as drift show Value;
import 'package:mi_almacen_plus/core/data/drift/app_database.dart' as db;
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/domain/entities/user.dart' as domain;
import 'package:mi_almacen_plus/core/domain/entities/category.dart' as domain;
import 'package:mi_almacen_plus/core/domain/entities/product.dart' as domain;
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart'
    as domain;
import 'package:mi_almacen_plus/core/domain/movement_rules.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/core/domain/product_validator.dart';
import 'package:uuid/uuid.dart';

/// User repository — V1 seeds a single owner; no auth flow.
class UserRepository {
  UserRepository(this._db);

  final db.AppDatabase _db;

  db.UserDao get _dao => _db.userDao;

  Future<domain.User?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapUser(row);
  }

  Future<domain.User> getOrCreateDefault() async {
    final users = await _dao.getAll();
    if (users.isNotEmpty) return _mapUser(users.first);
    // Seeded user from migration; should exist.
    return _mapUser(users.first);
  }

  domain.User _mapUser(db.User row) => domain.User(id: row.id, name: row.name);
}

/// Category repository — reads and counts seeded categories.
class CategoryRepository {
  CategoryRepository(this._db);

  final db.AppDatabase _db;

  db.CategoryDao get _dao => _db.categoryDao;

  Future<domain.Category?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapCategory(row);
  }

  Future<List<domain.Category>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_mapCategory).toList();
  }

  Future<int> count() => _dao.count();

  domain.Category _mapCategory(db.Category row) =>
      domain.Category(id: row.id, name: row.name);
}

/// Product repository — enforces domain rules; stock ONLY changes via movements.
class ProductRepository {
  ProductRepository(this._db);

  final db.AppDatabase _db;

  db.ProductDao get _dao => _db.productDao;
  db.InventoryMovementDao get _movementDao => _db.inventoryMovementDao;
  final _uuid = const Uuid();

  Future<domain.Product?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapProduct(row);
  }

  Future<List<domain.Product>> getAll({bool onlyActive = true}) async {
    final rows = await _dao.getAll(onlyActive: onlyActive);
    return rows.map(_mapProduct).toList();
  }

  Future<List<domain.Product>> getByCategory(
    String categoryId, {
    bool onlyActive = true,
  }) async {
    final rows = await _dao.getByCategory(categoryId, onlyActive: onlyActive);
    return rows.map(_mapProduct).toList();
  }

  Future<int> count({bool onlyActive = true}) =>
      _dao.count(onlyActive: onlyActive);

  /// Creates a product with initial stock; inserts INITIAL_STOCK movement.
  Future<domain.Product> create({
    required String categoryId,
    required String userId,
    required String name,
    required String unit,
    required int minimumStock,
    required int initialStock,
    String? description,
  }) async {
    validateProduct(
      name: name,
      unit: unit,
      minimumStock: minimumStock,
      initialStock: initialStock,
    );

    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      // Insert product with initialStock as currentStock
      await _dao.insertProduct(
        db.ProductsCompanion.insert(
          id: id,
          categoryId: categoryId,
          userId: userId,
          name: name,
          unit: unit,
          minimumStock: minimumStock,
          currentStock: drift.Value(initialStock),
          description: drift.Value(description),
        ),
      );

      // Insert INITIAL_STOCK movement
      final movementId = _uuid.v4();
      await _movementDao.insertMovementWithStockUpdate(
        db.InventoryMovementsCompanion.insert(
          id: movementId,
          productId: id,
          userId: userId,
          type: MovementType.incoming.index,
          reason: MovementReason.initialStock.index,
          quantity: initialStock,
          stockBefore: 0,
          stockAfter: initialStock,
          occurredAt: now,
        ),
        initialStock,
      );
    });

    return domain.Product(
      id: id,
      categoryId: categoryId,
      userId: userId,
      name: name,
      unit: unit,
      minimumStock: minimumStock,
      currentStock: initialStock,
      description: description,
    );
  }

  /// Updates descriptive fields; currentStock is NOT updatable (domain rule).
  Future<domain.Product> update({
    required String id,
    String? categoryId,
    String? name,
    String? unit,
    int? minimumStock,
    String? description,
    bool? isActive,
  }) async {
    final existing = await getById(id);
    if (existing == null) throw ValidationError('Product not found: $id');

    validateProduct(
      name: name ?? existing.name,
      unit: unit ?? existing.unit,
      minimumStock: minimumStock ?? existing.minimumStock,
      initialStock: existing.currentStock, // currentStock is fixed during edit
    );

    await _dao.updateProduct(
      db.ProductsCompanion(
        id: drift.Value(id),
        categoryId: drift.Value(categoryId ?? existing.categoryId),
        name: drift.Value(name ?? existing.name),
        unit: drift.Value(unit ?? existing.unit),
        minimumStock: drift.Value(minimumStock ?? existing.minimumStock),
        description: drift.Value(description ?? existing.description),
        isActive: drift.Value(isActive ?? existing.isActive),
        // currentStock intentionally NOT included
      ),
    );

    return existing.copyWith(
      categoryId: categoryId,
      name: name,
      unit: unit,
      minimumStock: minimumStock,
      description: description,
      isActive: isActive,
    );
  }

  /// Soft delete — preserves movements.
  Future<void> softDelete(String id) async {
    await _dao.softDelete(id);
  }

  /// Records a stock movement (IN/OUT) with atomic stock update + movement insert.
  Future<domain.InventoryMovement> recordMovement({
    required String productId,
    required String userId,
    required MovementReason reason,
    required int quantity,
    DateTime? occurredAt,
  }) async {
    validateQuantity(quantity);

    final product = await getById(productId);
    if (product == null) throw ValidationError('Product not found: $productId');

    final type = reason.type;
    if (type == MovementType.outgoing) {
      validateOut(product.currentStock, quantity);
    }

    final delta = type == MovementType.incoming ? quantity : -quantity;
    final stockBefore = product.currentStock;
    final stockAfter = stockBefore + delta;
    final movementId = _uuid.v4();
    final now = (occurredAt ?? DateTime.now()).millisecondsSinceEpoch;

    await _db.transaction(() async {
      // Insert movement
      await _movementDao.insertMovementWithStockUpdate(
        db.InventoryMovementsCompanion.insert(
          id: movementId,
          productId: productId,
          userId: userId,
          type: type.index,
          reason: reason.index,
          quantity: quantity,
          stockBefore: stockBefore,
          stockAfter: stockAfter,
          occurredAt: now,
        ),
        stockAfter,
      );
    });

    return domain.InventoryMovement(
      id: movementId,
      productId: productId,
      userId: userId,
      type: type,
      reason: reason,
      quantity: quantity,
      stockBefore: stockBefore,
      stockAfter: stockAfter,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  /// Projection invariant: recompute stock from movement trail.
  Future<int> recomputeStock(String productId) async {
    return _dao.recomputeStock(productId);
  }

  domain.Product _mapProduct(db.Product row) => domain.Product(
    id: row.id,
    categoryId: row.categoryId,
    userId: row.userId,
    name: row.name,
    unit: row.unit,
    minimumStock: row.minimumStock,
    currentStock: row.currentStock,
    description: row.description,
    isActive: row.isActive,
  );
}

/// Inventory movement repository — read-only history access.
class InventoryMovementRepository {
  InventoryMovementRepository(this._db);

  final db.AppDatabase _db;

  db.InventoryMovementDao get _dao => _db.inventoryMovementDao;

  Future<domain.InventoryMovement?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapMovement(row);
  }

  Future<List<domain.InventoryMovement>> getForProduct(
    String productId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _dao.getForProduct(
      productId,
      limit: limit,
      offset: offset,
    );
    return rows.map(_mapMovement).toList();
  }

  Future<int> count() => _dao.count();

  domain.InventoryMovement _mapMovement(db.InventoryMovement row) =>
      domain.InventoryMovement(
        id: row.id,
        productId: row.productId,
        userId: row.userId,
        type: MovementType.values[row.type],
        reason: MovementReason.values[row.reason],
        quantity: row.quantity,
        stockBefore: row.stockBefore,
        stockAfter: row.stockAfter,
        occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt),
      );
}
