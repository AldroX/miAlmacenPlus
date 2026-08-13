import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/entities/category.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Payload emitted by [ProductForm] when the user submits.
class ProductFormData {
  const ProductFormData({
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.minimumStock,
    this.description,
    this.initialStock,
  });

  final String name;
  final String unit;
  final String categoryId;
  final int minimumStock;
  final String? description;

  /// Only set in create mode; null in edit mode (stock is never editable).
  final int? initialStock;
}

/// Shared product form (design D8): used by NewProduct (create mode) and
/// ProductDetail inline edit (edit mode).
///
/// Edit mode keeps `currentStock` read-only (spec 3.2) — the only way stock
/// changes is a movement (spec 2.1).
class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({
    super.key,
    required this.isNew,
    this.initialProduct,
    required this.onSubmit,
  });

  final bool isNew;
  final Product? initialProduct;
  final void Function(ProductFormData data) onSubmit;

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.initialProduct?.name ?? '',
  );
  late final TextEditingController _unit = TextEditingController(
    text: widget.initialProduct?.unit ?? '',
  );
  late final TextEditingController _minimumStock = TextEditingController(
    text: widget.initialProduct?.minimumStock.toString() ?? '0',
  );
  late final TextEditingController _initialStock = TextEditingController(
    text: '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.initialProduct?.description ?? '',
  );
  final _newCategory = TextEditingController();

  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialProduct?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _minimumStock.dispose();
    _initialStock.dispose();
    _description.dispose();
    _newCategory.dispose();
    super.dispose();
  }

  /// Inline quick-create (spec 3.3 Sc.1): creates the category and selects it
  /// immediately; the categories stream makes it show in the picker.
  Future<void> _quickCreate() async {
    final name = _newCategory.text.trim();
    if (name.isEmpty) return;
    try {
      final created = await ref
          .read(categoryRepositoryProvider)
          .quickCreate(name);
      if (!mounted) return;
      setState(() {
        _categoryId = created.id;
        _newCategory.clear();
      });
    } on DomainException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String? _validateMinimumStock(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Ingrese un número válido';
    if (parsed < 0) return 'El stock mínimo no puede ser negativo';
    return null;
  }

  String? _validateInitialStock(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // empty initial stock means 0
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Ingrese un número válido';
    if (parsed < 0) return 'La cantidad inicial no puede ser negativa';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categories =
        ref.read(categoriesStreamProvider).value ?? const <Category>[];
    widget.onSubmit(
      ProductFormData(
        name: _name.text.trim(),
        unit: _unit.text.trim(),
        categoryId:
            _categoryId ?? (categories.isNotEmpty ? categories.first.id : ''),
        minimumStock: int.parse(_minimumStock.text.trim()),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        initialStock: widget.isNew
            ? (int.tryParse(_initialStock.text.trim()) ?? 0)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesStreamProvider).value ?? const <Category>[];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shadow =
        theme.extension<AppThemeExtra>()?.cardShadow ??
        AppThemeExtra.light.cardShadow;

    // Default the create-mode picker to the first category once loaded.
    if (widget.isNew && _categoryId == null && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _categoryId == null) {
          setState(() => _categoryId = categories.first.id);
        }
      });
    }
    final categoryId =
        _categoryId ?? (categories.isNotEmpty ? categories.first.id : null);

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.marginMobile,
                AppTokens.stackSm,
                AppTokens.marginMobile,
                AppTokens.stackLg,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTokens.gutter),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppTokens.borderRadiusMd,
                    ),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0x4D / 255),
                    ),
                    boxShadow: shadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        key: const Key('product-name'),
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _fieldDecoration(
                          label: 'Nombre del Producto',
                          hint: 'Ej: Tornillos Allen M6',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'El nombre es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: AppTokens.stackMd),
                      TextFormField(
                        key: const Key('product-description'),
                        controller: _description,
                        minLines: 3,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _fieldDecoration(
                          label: 'Descripción (Opcional)',
                          hint: 'Detalles del producto...',
                        ),
                      ),
                      const SizedBox(height: AppTokens.stackMd),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: const Key('product-category'),
                              initialValue: categoryId,
                              decoration: _fieldDecoration(
                                label: 'Categoría',
                                hint: 'Seleccionar...',
                              ),
                              items: [
                                for (final category in categories)
                                  DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.name),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _categoryId = value),
                            ),
                          ),
                          const SizedBox(width: AppTokens.gutter),
                          Expanded(
                            child: TextFormField(
                              key: const Key('product-unit'),
                              controller: _unit,
                              decoration: _fieldDecoration(
                                label: 'Unidad',
                                hint: 'Ej: kg',
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'La unidad es obligatoria'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.stackSm),
                      // Inline quick-create (spec 3.3).
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('quick-create-category'),
                              controller: _newCategory,
                              decoration: _fieldDecoration(
                                label: '',
                                hint: 'Nueva categoría…',
                              ),
                              onSubmitted: (_) => _quickCreate(),
                            ),
                          ),
                          IconButton(
                            key: const Key('quick-create-add'),
                            onPressed: _quickCreate,
                            tooltip: 'Crear categoría',
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.stackMd),
                      if (widget.isNew)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('product-initial-stock'),
                                controller: _initialStock,
                                keyboardType: TextInputType.number,
                                decoration: _fieldDecoration(
                                  label: 'Stock Inicial',
                                  hint: '0',
                                ),
                                validator: _validateInitialStock,
                              ),
                            ),
                            const SizedBox(width: AppTokens.gutter),
                            Expanded(
                              child: TextFormField(
                                key: const Key('product-min-stock'),
                                controller: _minimumStock,
                                keyboardType: TextInputType.number,
                                decoration: _fieldDecoration(
                                  label: 'Stock Mínimo',
                                  hint: '10',
                                ),
                                validator: _validateMinimumStock,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        TextFormField(
                          key: const Key('product-min-stock'),
                          controller: _minimumStock,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: 'Stock Mínimo',
                            hint: '10',
                          ),
                          validator: _validateMinimumStock,
                        ),
                        const SizedBox(height: AppTokens.stackMd),
                        // currentStock is read-only in edit mode (spec 3.2).
                        Container(
                          key: const Key('current-stock-readonly'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.gutter,
                            vertical: AppTokens.stackMd,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppTokens.borderRadiusDefault,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Stock actual',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const Spacer(),
                              Text(
                                '${widget.initialProduct?.currentStock ?? 0}',
                                style: AppTheme.displayStock.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _bottomBar(theme),
      ],
    );
  }

  /// Delegates to InputDecorationTheme (fill, radius, padding, colors).
  InputDecoration _fieldDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      hintText: hint,
    );
  }

  /// Figma fixed bottom action bar: translucent white, top hairline, full-width
  /// "Guardar Producto" button (56px, 12px radius, primary fill).
  Widget _bottomBar(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTokens.marginMobile),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0xE6 / 255),
        border: Border(
          top:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0x33 / 255)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            key: const Key('product-form-submit'),
            onPressed: _submit,
            icon: const Icon(Icons.save_outlined),
            label: Text(widget.isNew ? 'Guardar Producto' : 'Guardar cambios'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.borderRadiusMd),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
