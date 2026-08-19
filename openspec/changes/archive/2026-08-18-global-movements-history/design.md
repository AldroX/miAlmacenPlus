# Design: Global Movements History List

## Technical Approach

Convert the `/movements` placeholder screen into a functional reactive list using the existing Riverpod + Drift streaming pattern. The approach mirrors `HistoryScreen` and `RecentMovementsSection`: a `StreamProvider` feeds a `ConsumerWidget` that watches both movements and products streams, resolves product names via a map, and renders a `ListView.separated` with the established `_MovementItem` visual pattern.

## Architecture Decisions

### Decision: Provider Limit (50 vs 5/10)

**Choice**: `allMovementsProvider` uses `limit: 50` in `stream_providers.dart`
**Alternatives considered**: Reuse `recentMovementsProvider` (limit 5), use repository default (limit 10)
**Rationale**: The dashboard tile shows only 3 rows (limit 5 with buffer). The History screen uses limit 50. A full-screen list warrants more items; 50 matches History and defers pagination. Separate provider avoids coupling dashboard UX to global list UX.

### Decision: Duplicate `_MovementItem` vs Extract Shared Widget

**Choice**: Duplicate `_MovementItem` and `_formatTimestamp` into `movements_screen.dart` with `// TODO: extract to shared widget when pattern stabilizes`
**Alternatives considered**: Extract to `lib/features/inventory/widgets/movement_list_item.dart`
**Rationale**: MVP favors velocity; the pattern is identical to `RecentMovementsSection`. Extraction adds a file and import complexity for zero behavior change. The TODO documents intent to unify when the pattern proves stable across 3+ consumers.

### Decision: Product Name Resolution Timing

**Choice**: Build `Map<String, String>` from `productsStreamProvider.value ?? []`; fallback to `'—'` when product not yet in map
**Alternatives considered**: Wait for both streams to emit, use `AsyncValue.when` for products too
**Rationale**: Movements and products streams are independent. Waiting blocks the list. The fallback `'—'` is the same pattern used in `RecentMovementsSection` (line 58). When products stream emits, the map rebuilds and rows update reactively — no extra code needed.

### Decision: Error State Retry

**Choice**: Show "Error al cargar el historial" without explicit retry button (matches `HistoryScreen` line 24)
**Alternatives considered**: Add retry button calling `ref.invalidate(allMovementsProvider)`
**Rationale**: `HistoryScreen` (the established pattern for full-screen movement lists) shows error text only. StreamProvider auto-retries on reconnect; manual retry adds marginal value for MVP.

## Data Flow

```
Drift DB (inventory_movements)
       │
       ▼
InventoryMovementDao.watchRecent(limit: 50)  ──► Stream<List<InventoryMovement>>
       │
       ▼
InventoryMovementRepository.watchRecent(limit: 50)  ──► Stream<List<InventoryMovement>>
       │
       ▼
allMovementsProvider (StreamProvider)  ──► AsyncValue<List<InventoryMovement>>
       │
       ▼
MovementsScreen (ConsumerWidget)
       │                           │
       │                    productsStreamProvider
       │                           │
       ▼                           ▼
  movements                    products list
       │                           │
       └──────► Map<String, String> (productId → name)
                    │
                    ▼
           ListView.separated
                    │
                    ▼
             _MovementItem
                    │
                    ▼
           productName = map[id] ?? '—'
           timestamp = _formatTimestamp(occurredAt)
           quantity = ±quantity with color
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/core/providers/stream_providers.dart` | Modify | Add `allMovementsProvider` after `recentMovementsProvider` (limit 50) |
| `lib/features/inventory/movements_screen.dart` | Rewrite | Convert from `StatelessWidget` to `ConsumerWidget` with full list implementation |

## Interfaces / Contracts

### New Provider

```dart
// lib/core/providers/stream_providers.dart

/// All movements across products, newest-first — drives the Movements tab
/// (design D11 / global movements list). Capped at 50 for MVP; pagination deferred.
final allMovementsProvider = StreamProvider<List<InventoryMovement>>((ref) {
  return ref.watch(movementRepositoryProvider).watchRecent(limit: 50);
});
```

### MovementsScreen Signature (unchanged route)

```dart
// lib/features/inventory/movements_screen.dart
// Route: /movements (already defined in app_router.dart lines 57-63)

class MovementsScreen extends ConsumerWidget {
  const MovementsScreen({super.key});
  // build returns Scaffold with AppBar + AsyncValue.when body
}
```

No new domain models or repository methods — uses existing `InventoryMovement` entity and `watchRecent`.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|--------------|----------|
| Widget | Loading state renders `CircularProgressIndicator` | Pump widget with overridden provider returning `AsyncValue.loading()` |
| Widget | Empty state renders "Aún no hay movimientos" | Override provider with empty list; verify text present |
| Widget | List renders with mocked movements (product resolution, signed quantities, timestamps) | Override providers with test data; verify `_MovementItem` content |
| Widget | Error state renders "Error al cargar el historial" | Override provider with `AsyncValue.error`; verify text |
| Widget | Reactive update when new movement added | Add to stream; verify list rebuilds with new item at top |
| Integration | Navigate via router to `/movements` → verify list renders | `appRouter.go('/movements')`; await pump; find list items |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary changes. The `/movements` route already exists in `app_router.dart`.

## Migration / Rollout

No migration required. No database schema changes. No feature flags needed. The change is purely additive on the UI layer.

## Rollback Plan

1. Revert `lib/features/inventory/movements_screen.dart` to the original 15-line `StatelessWidget` placeholder
2. Remove `allMovementsProvider` from `lib/core/providers/stream_providers.dart`

No database or repository changes to revert.

## Open Questions

- [ ] None — all decisions resolved with rationale above.