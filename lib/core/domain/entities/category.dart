/// Product category. `categoryId` on products is mandatory, so a category
/// always carries its id alongside its Spanish [name].
class Category {
  const Category({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
