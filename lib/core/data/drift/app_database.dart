import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mi_almacen_plus/core/domain/seed_categories.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'daos.dart';

/// Re-export DAOs so repositories can access them via `db.UserDao`, etc.
export 'daos.dart' show UserDao, CategoryDao, ProductDao, InventoryMovementDao;

part 'app_database.g.dart';

/// App database for the local-first MVP.
///
/// Schema:
/// - users (id TEXT PK, name TEXT)
/// - categories (id TEXT PK, name TEXT)
/// - products (id TEXT PK, categoryId TEXT FK, userId TEXT FK, name TEXT,
///   unit TEXT, minimumStock INTEGER, currentStock INTEGER, description TEXT,
///   isActive INTEGER, CHECK (currentStock >= 0))
/// - inventory_movements (id TEXT PK, productId TEXT FK, userId TEXT FK,
///   type INTEGER, reason INTEGER, quantity INTEGER, stockBefore INTEGER,
///   stockAfter INTEGER, occurredAt INTEGER)
///
/// Migration policy is additive-only; schema export lives in drift_schemas/.
///
/// All PKs are UUID v4 stored as TEXT. Foreign keys enforced.
@DriftDatabase(
  tables: [Users, Categories, Products, InventoryMovements],
  daos: [UserDao, CategoryDao, ProductDao, InventoryMovementDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-disk database in the app documents directory.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mi_almacen.db'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  /// In-memory database for tests.
  static AppDatabase inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // Seed the 7 fixed categories (decision #76, spec 3.3) and the
      // default device owner (decision #81 D10) exactly once, inside the
      // schema-creation transaction. Ids are UUID v4 (spec 1).
      final uuid = const Uuid();
      for (final name in seedCategoryNames) {
        await into(
          categories,
        ).insert(CategoriesCompanion.insert(id: uuid.v4(), name: name));
      }
      await into(
        users,
      ).insert(UsersCompanion.insert(id: uuid.v4(), name: 'Dueño'));
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations go here.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// User table — V1 has no auth; a single device owner row is seeded.
class Users extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Category table — seeded with 7 fixed names at creation.
class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Product table — stock only changes via movements; currentStock guarded by CHECK.
class Products extends Table {
  TextColumn get id => text()();

  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();

  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.restrict)();

  TextColumn get name => text()();

  TextColumn get unit => text()();

  IntColumn get minimumStock => integer()();

  /// Stock never negative — enforced in domain (validateOut) AND at the DB
  /// level with a CHECK constraint (amendment 2: defense in depth).
  IntColumn get currentStock => integer()
      .withDefault(const Constant(0))
      .check(currentStock.isBiggerOrEqualValue(0))();

  TextColumn get description => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Inventory movement table — full traceability with stockBefore/stockAfter.
class InventoryMovements extends Table {
  TextColumn get id => text()();

  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.restrict)();

  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.restrict)();

  /// 0 = incoming, 1 = outgoing (matches MovementType enum order).
  IntColumn get type => integer()();

  /// MovementReason enum index (0=purchase, 1=sale, 2=consumption, 3=return_,
  /// 4=loss, 5=online, 6=initialStock).
  IntColumn get reason => integer()();

  IntColumn get quantity => integer()();

  IntColumn get stockBefore => integer()();

  IntColumn get stockAfter => integer()();

  IntColumn get occurredAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
