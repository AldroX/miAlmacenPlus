import 'package:drift_dev/api/migrations_native.dart' show SchemaVerifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/drift/schema_versions/schema.dart'
    show GeneratedHelper;

/// Verifies the additive-only migration policy (spec 1):
/// a v1 database with data must upgrade to v2 with every row intact and the
/// resulting schema matching the exported v2 snapshot.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test(
    'migrating v1 to v2 keeps rows (additive) and schema matches export',
    () async {
      // Start from the frozen v1 schema snapshot (drift_schemas/export).
      final schema = await verifier.schemaAt(1);

      // Row created while the database still is at v1.
      schema.rawDatabase.execute(
        'INSERT INTO categories (id, name) VALUES (?, ?)',
        ['cat-legacy', 'Categoría Legada'],
      );

      final db = AppDatabase(schema.newConnection());
      try {
        // Runs the real onUpgrade (1 -> 2) and validates the final schema
        // against the exported v2 snapshot.
        await verifier.migrateAndValidate(db, 2);

        final cat = await db.categoryDao.getById('cat-legacy');
        expect(
          cat,
          isNotNull,
          reason: 'v1 rows must survive an additive migration',
        );
        expect(cat!.name, 'Categoría Legada');

        // The additive v2 change (users.email) must be present in the migrated
        // schema — this is what makes the migration "additive".
        final emailColumnCount = await db
            .customSelect(
              "SELECT COUNT(*) AS c FROM pragma_table_info('users') "
              "WHERE name = 'email'",
            )
            .getSingle();
        expect(emailColumnCount.read<int>('c'), 1);
      } finally {
        await db.close();
      }
    },
  );
}
