import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// go_router page for `/products/:id/movement` (design D7): presents a modal
/// bottom sheet on arrival and pops the route once the sheet closes. The
/// sheet is the primary container for registering movements (DESING.MD
/// "Quick Action Bottom Sheets").
class MovementSheetPage extends StatefulWidget {
  const MovementSheetPage({
    super.key,
    required this.productId,
    this.initialType = MovementType.incoming,
  });

  final String productId;

  /// Direction preselected when the sheet opens (Figma Entrada/Salida quick
  /// actions). Defaults to an entry.
  final MovementType initialType;

  @override
  State<MovementSheetPage> createState() => _MovementSheetPageState();
}

class _MovementSheetPageState extends State<MovementSheetPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: MovementSheet(
          productId: widget.productId,
          initialType: widget.initialType,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Bottom sheet content: IN/OUT toggle, quantity, reason picker (Spanish
/// labels) and submit through the repository (spec 4.1).
class MovementSheet extends ConsumerStatefulWidget {
  const MovementSheet({
    super.key,
    required this.productId,
    this.initialType = MovementType.incoming,
  });

  final String productId;

  /// Direction preselected when the sheet opens (Figma Entrada/Salida quick
  /// actions). Defaults to an entry.
  final MovementType initialType;

  @override
  ConsumerState<MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends ConsumerState<MovementSheet> {
  late MovementType _type = widget.initialType;
  final _quantity = TextEditingController();
  MovementReason? _reason;
  String? _error;

  List<MovementReason> get _reasons => MovementReason.values
      .where((r) => r.type == _type && r != MovementReason.initialStock)
      .toList();

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _setType(MovementType type) {
    setState(() {
      _type = type;
      if (!_reasons.contains(_reason)) _reason = _reasons.first;
    });
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantity.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'Ingrese una cantidad válida');
      return;
    }
    final reason = _reason ?? _reasons.first;
    try {
      final user = await ref.read(currentUserProvider.future);
      await ref
          .read(productRepositoryProvider)
          .recordMovement(
            productId: widget.productId,
            userId: user.id,
            reason: reason,
            quantity: quantity,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Movimiento registrado')),
      );
    } on DomainException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncProduct = ref.watch(productByIdProvider(widget.productId));
    final product = asyncProduct.value;
    final reasons = _reasons;
    if (_reason == null && reasons.isNotEmpty) _reason = reasons.first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.marginMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar movimiento', style: theme.textTheme.headlineMedium),
            if (product != null) ...[
              const SizedBox(height: AppTokens.stackSm),
              Text(
                '${product.name} — Stock actual: ${product.currentStock}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppTokens.stackLg),
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                  value: MovementType.incoming,
                  label: Text('Entrada'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment(
                  value: MovementType.outgoing,
                  label: Text('Salida'),
                  icon: Icon(Icons.remove),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) => _setType(selection.first),
            ),
            const SizedBox(height: AppTokens.stackMd),
            TextField(
              key: const Key('movement-quantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: AppTokens.stackMd),
            DropdownButtonFormField<MovementReason>(
              key: const Key('movement-reason'),
              initialValue: _reason ?? (reasons.isEmpty ? null : reasons.first),
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: [
                for (final reason in reasons)
                  DropdownMenuItem(value: reason, child: Text(reason.label)),
              ],
              onChanged: (value) => setState(() => _reason = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTokens.stackSm),
              Text(
                _error!,
                key: const Key('movement-error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppTokens.stackLg),
            FilledButton(
              key: const Key('movement-submit'),
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
