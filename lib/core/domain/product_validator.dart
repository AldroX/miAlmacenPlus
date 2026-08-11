import 'errors.dart';

/// Validates a product create/edit payload (spec requirement 3.1):
/// the name is required, the unit is required, and neither the minimum
/// stock nor the initial quantity may be negative.
///
/// Throws [ValidationError] when a constraint is violated.
void validateProduct({
  required String name,
  required String unit,
  required int minimumStock,
  int initialStock = 0,
}) {
  if (name.trim().isEmpty) {
    throw const ValidationError('Product name is required');
  }
  if (unit.trim().isEmpty) {
    throw const ValidationError('Product unit is required');
  }
  if (minimumStock < 0) {
    throw const ValidationError('Minimum stock must not be negative');
  }
  if (initialStock < 0) {
    throw const ValidationError('Initial stock must not be negative');
  }
}
