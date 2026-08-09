import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/seed_categories.dart';

void main() {
  test(
    'seeds exactly the 7 agreed categories with correct Spanish accents',
    () {
      expect(seedCategoryNames, [
        'Alimentos',
        'Bebidas',
        'Limpieza',
        'Higiene',
        'Electrónica',
        'Herramientas',
        'Otros',
      ]);
    },
  );
}
