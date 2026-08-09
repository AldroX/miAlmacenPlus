/// A product tracked in inventory.
///
/// [currentStock] is only ever changed by movements (spec requirement 2.1);
/// [copyWith] intentionally cannot touch it, which restricts edits to
/// descriptive fields plus the soft-delete flag (spec requirement 3.2).
class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.userId,
    required this.name,
    required this.unit,
    required this.minimumStock,
    required this.currentStock,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String categoryId;

  /// Creator of this product (spec requirement 2.4).
  final String userId;
  final String name;
  final String unit;
  final int minimumStock;
  final int currentStock;
  final String? description;

  /// False once soft-deleted; movements are kept (spec requirement 3.2).
  final bool isActive;

  Product copyWith({
    String? categoryId,
    String? name,
    String? unit,
    int? minimumStock,
    String? description,
    bool? isActive,
  }) {
    return Product(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      userId: userId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      minimumStock: minimumStock ?? this.minimumStock,
      currentStock: currentStock,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.categoryId == categoryId &&
      other.userId == userId &&
      other.name == name &&
      other.unit == unit &&
      other.minimumStock == minimumStock &&
      other.currentStock == currentStock &&
      other.description == description &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    userId,
    name,
    unit,
    minimumStock,
    currentStock,
    description,
    isActive,
  );
}
