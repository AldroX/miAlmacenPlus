/// Seed category names inserted when the database is first created
/// (spec requirement 3.3, decision #76). Spanish labels with correct
/// accents; the data layer assigns stable UUID ids on insert.
const List<String> seedCategoryNames = [
  'Alimentos',
  'Bebidas',
  'Limpieza',
  'Higiene',
  'Electrónica',
  'Herramientas',
  'Otros',
];
