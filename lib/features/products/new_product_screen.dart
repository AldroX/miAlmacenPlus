import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';

import 'widgets/product_form.dart';

/// Create product screen (spec 3.1): shared [ProductForm] in create mode.
/// On success the products list refreshes automatically via the stream
/// (spec 6.3) — no manual invalidation needed.
class NewProductScreen extends ConsumerStatefulWidget {
  const NewProductScreen({super.key});

  @override
  ConsumerState<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends ConsumerState<NewProductScreen> {
  Future<void> _create(ProductFormData data) async {
    try {
      final user = await ref.read(currentUserProvider.future);
      await ref
          .read(productRepositoryProvider)
          .create(
            categoryId: data.categoryId,
            userId: user.id,
            name: data.name,
            unit: data.unit,
            minimumStock: data.minimumStock,
            initialStock: data.initialStock ?? 0,
            description: data.description,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto creado')));
      Navigator.of(context).pop();
    } on DomainException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Producto')),
      body: ProductForm(isNew: true, onSubmit: _create),
    );
  }
}
