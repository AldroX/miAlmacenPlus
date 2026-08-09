import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';

void main() {
  group('stockStatusOf', () {
    test('returns outOfStock when stock is zero, checked first', () {
      expect(stockStatusOf(0, 5), StockStatus.outOfStock);
      expect(stockStatusOf(0, 0), StockStatus.outOfStock);
    });

    test('returns lowStock when 0 < stock <= minStock', () {
      expect(stockStatusOf(1, 5), StockStatus.lowStock);
      expect(stockStatusOf(4, 5), StockStatus.lowStock);
      expect(stockStatusOf(5, 5), StockStatus.lowStock);
    });

    test('returns normal when stock > minStock', () {
      expect(stockStatusOf(6, 5), StockStatus.normal);
      expect(stockStatusOf(10, 0), StockStatus.normal);
    });

    test('rejects a negative stock', () {
      expect(() => stockStatusOf(-1, 5), throwsArgumentError);
    });

    test('rejects a negative minStock', () {
      expect(() => stockStatusOf(5, -1), throwsArgumentError);
    });
  });
}
