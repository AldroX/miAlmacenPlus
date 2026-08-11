import 'movement_type.dart';

/// Business reasons for stock movements (spec requirement 2.3).
///
/// Each reason carries its Spanish [label] — the Figma copy shown in the UI —
/// and the [type] bucket it belongs to. The mapping is bipartite:
/// incoming = Compra a Proveedor, Devolución, Stock Inicial (INITIAL_STOCK);
/// outgoing = Consumo Interno, Mermas, Venta Mostrador, Venta Online.
enum MovementReason {
  purchase(label: 'Compra a Proveedor', type: MovementType.incoming),
  sale(label: 'Venta Mostrador', type: MovementType.outgoing),
  consumption(label: 'Consumo Interno', type: MovementType.outgoing),
  return_(label: 'Devolución', type: MovementType.incoming),
  loss(label: 'Mermas', type: MovementType.outgoing),
  online(label: 'Venta Online', type: MovementType.outgoing),

  /// Internal reason assigned when a product is created with initial stock;
  /// not offered in the movement picker.
  initialStock(label: 'Stock Inicial', type: MovementType.incoming);

  const MovementReason({required this.label, required this.type});

  final String label;
  final MovementType type;

  /// All reasons that belong to [type], for filter-driven pickers.
  static List<MovementReason> ofType(MovementType type) =>
      values.where((reason) => reason.type == type).toList();
}
