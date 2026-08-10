import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/domain/product_validator.dart';

void main() {
  group('validateProduct', () {
    test(
      'accepts a product with a name, unit, and non-negative minimum stock',
      () {
        expect(
          () => validateProduct(
            name: 'Café',
            unit: 'kg',
            minimumStock: 2,
            initialStock: 5,
          ),
          returnsNormally,
        );
        expect(
          () => validateProduct(name: 'Agua', unit: 'L', minimumStock: 0),
          returnsNormally,
        );
      },
    );

    test('rejects an empty name (spec 3.1)', () {
      expect(
        () => validateProduct(name: '', unit: 'kg', minimumStock: 2),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects a whitespace-only name', () {
      expect(
        () => validateProduct(name: '   ', unit: 'kg', minimumStock: 2),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects an empty unit', () {
      expect(
        () => validateProduct(name: 'Café', unit: '', minimumStock: 2),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects a whitespace-only unit', () {
      expect(
        () => validateProduct(name: 'Café', unit: '   ', minimumStock: 2),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects a negative minimum stock (spec 3.1)', () {
      expect(
        () => validateProduct(name: 'Café', unit: 'kg', minimumStock: -1),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects a negative initial stock', () {
      expect(
        () => validateProduct(
          name: 'Café',
          unit: 'kg',
          minimumStock: 2,
          initialStock: -2,
        ),
        throwsA(isA<ValidationError>()),
      );
    });
  });
}
