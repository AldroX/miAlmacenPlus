/// V1 user model: identifies who created products and movements for future
/// workspace support. There is no auth flow in the MVP (spec requirement 2.4).
class User {
  const User({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is User && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
