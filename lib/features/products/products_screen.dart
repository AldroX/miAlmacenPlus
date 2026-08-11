import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_almacen_plus/core/domain/entities/category.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

import 'products_providers.dart';
import 'widgets/product_card.dart';

/// Products list (spec 3.2): search bar, category chips and the inventory
/// cards. Reacts to the Drift stream — movements registered elsewhere refresh
/// the list automatically (spec 6.3, design D11).
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final categories =
        ref.watch(categoriesStreamProvider).value ?? const <Category>[];
    final filter = ref.watch(productsFilterProvider);
    final notifier = ref.watch(productsFilterProvider.notifier);
    final categoryNameOf = <String, String>{
      for (final category in categories) category.id: category.name,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('appbar-menu'),
          icon: const Icon(Icons.menu),
          tooltip: 'Menú',
          onPressed: () {},
        ),
        actions: [
          IconButton(
            key: const Key('appbar-actions'),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
            onPressed: () {},
          ),
        ],
        titleTextStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.025,
          color: Color(0xFF005A71),
        ),
        foregroundColor: const Color(0xFF005A71),
        title: const Text('Mi Almacén'),
      ),
      body: Column(
        children: [
          // Prominent rounded search pill (DESING.MD search bar).
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.marginMobile,
              AppTokens.stackSm,
              AppTokens.marginMobile,
              AppTokens.stackSm,
            ),
            child: TextField(
              key: const Key('products-search'),
              onChanged: notifier.setSearch,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF3F484C),
              ),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFFBEC8CD),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF6F787D),
                ),
                filled: true,
                fillColor: const Color(0x80D3E4FE),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTokens.borderRadiusFull,
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTokens.borderRadiusFull,
                  ),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTokens.borderRadiusFull,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Category filter chips (spec 3.2 Sc.2) — Figma pill row.
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.marginMobile,
              ),
              children: [
                _categoryChip(
                  label: 'Todos',
                  key: const Key('categoryFilter-all'),
                  selected: filter.categoryId == null,
                  onTap: () => notifier.setCategory(null),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTokens.stackSm),
                    child: _categoryChip(
                      label: category.name,
                      key: Key('categoryFilter-${category.id}'),
                      selected: filter.categoryId == category.id,
                      onTap: () => notifier.setCategory(category.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.stackSm),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('No hay productos todavía'))
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTokens.marginMobile),
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTokens.stackMd),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        key: Key('product-card-${product.id}'),
                        product: product,
                        categoryName: categoryNameOf[product.categoryId],
                        onTap: () => context.push('/products/${product.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('products-fab'),
        onPressed: () => context.push('/products/new'),
        tooltip: 'Nuevo producto',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Figma category pill: 9999px radius, 8/16 padding, 12px Inter SemiBold
  /// with 0.05em letter spacing; selected = primary fill, unselected = light
  /// blue fill.
  Widget _categoryChip({
    required String label,
    required Key key,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          height: 16 / 12,
          color: selected ? Colors.white : const Color(0xFF3F484C),
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF005A71),
      backgroundColor: const Color(0xFFDCE9FF),
      side: BorderSide.none,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusFull),
      ),
    );
  }
}
