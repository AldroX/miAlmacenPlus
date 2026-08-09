import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';

void main() {
  test('defines exactly the 6 Figma reasons plus internal INITIAL_STOCK', () {
    expect(MovementReason.values, hasLength(7));
  });

  group('Spanish labels', () {
    test('match the Figma copy verbatim', () {
      expect(MovementReason.purchase.label, 'Compra a Proveedor');
      expect(MovementReason.sale.label, 'Venta Mostrador');
      expect(MovementReason.consumption.label, 'Consumo Interno');
      expect(MovementReason.return_.label, 'Devolución');
      expect(MovementReason.loss.label, 'Mermas');
      expect(MovementReason.online.label, 'Venta Online');
      expect(MovementReason.initialStock.label, 'Stock Inicial');
    });
  });

  group('bipartite IN/OUT mapping (spec 2.3)', () {
    test('incoming reasons are exactly the 3 IN reasons', () {
      expect(
        MovementReason.ofType(
          MovementType.incoming,
        ).map((r) => r.label).toSet(),
        {'Compra a Proveedor', 'Devolución', 'Stock Inicial'},
      );
    });

    test('outgoing reasons are exactly the 4 OUT reasons', () {
      expect(
        MovementReason.ofType(
          MovementType.outgoing,
        ).map((r) => r.label).toSet(),
        {'Consumo Interno', 'Mermas', 'Venta Mostrador', 'Venta Online'},
      );
    });

    test('a purchase reason can never be registered as an OUT movement', () {
      // Domain translation of "GIVEN OUT with reason Compra a Proveedor;
      // WHEN validated; THEN rejected": purchase is hard-wired to the
      // incoming bucket, so no outgoing registration can carry it.
      expect(MovementReason.purchase.type, MovementType.incoming);
      expect(
        MovementReason.ofType(MovementType.outgoing),
        isNot(contains(MovementReason.purchase)),
      );
    });
  });
}
