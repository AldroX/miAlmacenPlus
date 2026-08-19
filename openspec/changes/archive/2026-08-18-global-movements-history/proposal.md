# Proposal: Global Movements History List

## Intent

The Movements tab (`/movements`) is a placeholder showing only "Historial de movimientos" text. Users expect a full history of inventory movements across all products — consistent with the per-product `HistoryScreen` and the dashboard's `RecentMovementsSection` pattern. This change converts the placeholder into a functional global movements list.

## Scope

### In Scope
- Add `allMovementsProvider` in `stream_providers.dart` (limit: 50, separate from dashboard's 5)
- Convert `MovementsScreen` to `ConsumerWidget` watching `allMovementsProvider` + `productsStreamProvider`
- Reuse/adapt `RecentMovementsSection` UI pattern: `ListView`, `_MovementItem`, empty state
- Product name resolution via `productsStreamProvider` map with "—" fallback

### Out of Scope
- Filtering by date/type/product (future enhancement)
- Pagination/infinite scroll (future)
- Movement detail drill-down (future)
- New data layer — all DAO/repository methods already exist

## Capabilities

### New Capabilities
- `global-movements-list`: Full-screen reactive list of all inventory movements across products, newest-first, with product names, signed quantities, and relative timestamps

### Modified Capabilities
- None — this is a new screen implementation using existing capabilities

## Approach

1. **Data layer**: `InventoryMovementDao.watchRecent(limit)` and `InventoryMovementRepository.watchRecent(limit)` already support global queries. Add a dedicated provider `allMovementsProvider` with `limit: 50` in `stream_providers.dart` (separate from dashboard's `recentMovementsProvider` with `limit: 5`).

2. **UI layer**: Transform `MovementsScreen` from `StatelessWidget` to `ConsumerWidget`. Watch `allMovementsProvider` and `productsStreamProvider`. Build a `ListView.separated` using the existing `_MovementItem` pattern (copy/adapt from `RecentMovementsSection`). Handle loading/error/empty states with the same patterns as `HistoryScreen`.

3. **Product resolution**: Build a `Map<String, String>` from `productsStreamProvider` value to resolve `productId` → `name`, defaulting to "—" when the product stream hasn't emitted yet (graceful fallback).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/core/providers/stream_providers.dart` | Modified | Add `allMovementsProvider` (limit 50) |
| `lib/features/inventory/movements_screen.dart` | Modified | Convert to `ConsumerWidget` with full list implementation |
| `lib/features/dashboard/widgets/recent_movements_section.dart` | Referenced | Reuse `_MovementItem` and `_formatTimestamp` patterns |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Product name resolution timing — products stream may not have emitted when movements arrive | Medium | "—" fallback in map lookup; UI remains usable, names populate reactively |
| Duplicating `_MovementItem` logic instead of extracting shared widget | Low | Extract to shared location if pattern stabilizes; acceptable duplication for MVP |

## Rollback Plan

Revert `movements_screen.dart` to the original `StatelessWidget` placeholder (15 lines). Remove `allMovementsProvider` from `stream_providers.dart`. No database migrations or schema changes involved.

## Dependencies

- None new — all data layer methods (`watchRecent`, `watchAll`) already exist in DAO and Repository

## Success Criteria

- [ ] Navigating to `/movements` shows a scrollable list of movements (newest first)
- [ ] Each row shows: product name, relative timestamp ("Hoy 10:30"), signed quantity (+/-) with color coding
- [ ] Empty state shows "Aún no hay movimientos" when no movements exist
- [ ] Loading state shows `CircularProgressIndicator` while streams initialize
- [ ] Error state shows "Error al cargar el historial" on stream failure
- [ ] Product names resolve correctly; missing products show "—" without crashing
- [ ] List capped at 50 items (MVP — pagination deferred)