# Tasks: Global Movements History List

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 200-250 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Provider + Screen + Tests | PR 1 | `flutter test test/features/inventory/movements_screen_test.dart` | In-memory Drift via TestHarness | Revert movements_screen.dart + stream_providers.dart |

## Phase 1: Provider Layer

- [x] 1.1 Add `allMovementsProvider` to `lib/core/providers/stream_providers.dart` after `recentMovementsProvider` (around line 42) with `limit: 50`, import `InventoryMovement` from domain entities
- [x] 1.2 Verify provider compiles with no type errors

## Phase 2: Screen Layer — MovementsScreen Rewrite

- [x] 2.1 Convert `MovementsScreen` from `StatelessWidget` to `ConsumerWidget` in `lib/features/inventory/movements_screen.dart`, add imports: `flutter_riverpod`, `stream_providers.dart`, `products_providers.dart`, `movement_type.dart`, `inventory_movement.dart`, `product.dart`, `app_theme.dart`
- [x] 2.2 Implement build method with `AsyncValue.when` on `allMovementsProvider`: loading → `CircularProgressIndicator`, error → `Text('Error al cargar el historial')`, data → `ListView.separated` with itemBuilder
- [x] 2.3 Add product name resolution map inside build: `final nameOf = <String, String>{ for (final p in products) p.id: p.name };` where `products` from `ref.watch(productsStreamProvider).value ?? []`; fallback `nameOf[movement.productId] ?? '—'`
- [x] 2.4 Implement private `_MovementItem` class (duplicated from `RecentMovementsSection`) with fields `movement`, `productName`, 40px circle icon, product name + timestamp, signed quantity; colors: incoming → secondaryContainer/green, outgoing → errorContainer/red
- [x] 2.5 Add `_formatTimestamp` helper (copy logic from `RecentMovementsSection._formatTimestamp`) returning "Hoy HH:MM", "Ayer HH:MM", "dd/MM HH:MM"
- [x] 2.6 Add empty state handling in data branch: `if (movements.isEmpty) return Center(child: Text('Aún no hay movimientos'));`
- [x] 2.7 Verify widget compiles and route `/movements` still works

## Phase 3: Widget Tests

- [x] 3.1 Create `test/features/inventory/movements_screen_test.dart` with loading state test: override `allMovementsProvider` with `AsyncValue.loading()`, verify `CircularProgressIndicator` present
- [x] 3.2 Add empty state test: override provider with empty list, verify "Aún no hay movimientos" text
- [x] 3.3 Add list renders test: override both `allMovementsProvider` and `productsStreamProvider` with test data (incoming/outgoing movements with product names), verify product name, timestamp format, signed quantity with color
- [x] 3.4 Add error state test: override provider with `AsyncValue.error`, verify error text
- [x] 3.5 Add reactive update test: use test harness to add movement, verify list rebuilds with new item at top

## Phase 4: Integration Test

- [x] 4.1 Add router navigation test to `test/core/routing/app_router_test.dart`: navigate to `/movements` via router, verify list renders (or empty state)

(End of file - total 50 lines)