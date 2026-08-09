import 'errors.dart';

/// Validates a product create/edit payload (spec requirement 3.1):
/// the name is required and neither the minimum stock nor the initial
/// quantity may be negative.
///
/// Throws [ValidationError] when a constraint is violated.
void validateProduct({
  required String name,
  required int minimumStock,
  int initialStock = 0,
}) {
  if (name.trim().isEmpty) {
    throw const ValidationError('Product name is required');
  }
  if (minimumStock < 0) {
    throw const ValidationError('Minimum stock must not be negative');
  }
  if (initialStock < 0) {
    throw const ValidationError('Initial stock must not be negative');
  }
}
