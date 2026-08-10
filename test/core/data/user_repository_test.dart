import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/entities/user.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';

void main() {
  group('UserRepository', () {
    late AppDatabase db;
    late UserRepository repo;

    setUp(() {
      db = AppDatabase.inMemory();
      repo = UserRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('getById returns null for non-existent user', () async {
      final user = await repo.getById('non-existent');
      expect(user, isNull);
    });

    test('getOrCreateDefault returns the seeded user', () async {
      final user = await repo.getOrCreateDefault();
      expect(user, isNotNull);
      expect(user.name, 'Dueño');
    });

    test('getById returns the seeded user by id', () async {
      final defaultUser = await repo.getOrCreateDefault();
      final user = await repo.getById(defaultUser.id);
      expect(user, isNotNull);
      expect(user!.id, defaultUser.id);
      expect(user.name, 'Dueño');
    });

    test('multiple calls return the same user instance', () async {
      final user1 = await repo.getOrCreateDefault();
      final user2 = await repo.getOrCreateDefault();
      expect(user1.id, user2.id);
    });
  });
}