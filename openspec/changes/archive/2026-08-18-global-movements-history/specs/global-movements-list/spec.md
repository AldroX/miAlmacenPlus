# Global Movements List Specification

## Purpose

Full-screen reactive list of all inventory movements across products, newest-first, with product names, signed quantities, and relative timestamps. Converts the current `/movements` placeholder into a functional history screen.

## Requirements

### Requirement: FR-01 — Scrollable List Newest-First

The system SHALL display a vertically scrollable list of all inventory movements ordered by timestamp descending (newest first).

#### Scenario: User opens Movements tab with existing movements

- GIVEN the user navigates to `/movements`
- AND at least one movement exists in the database
- WHEN the streams emit data
- THEN the list renders all movements with newest at the top
- AND the list is capped at 50 items (MVP)

### Requirement: FR-02 — Row Shows Product Name, Timestamp, Signed Quantity

The system SHALL render each movement row with: product name, relative timestamp, and signed quantity with color coding (green for incoming, red for outgoing).

#### Scenario: Movement row displays correctly

- GIVEN a movement with productId "prod-1", quantity +5, timestamp 2026-08-17 10:30
- AND product "prod-1" has name "Laptop"
- WHEN the row renders
- THEN product name shows "Laptop" (Inter 14w600)
- AND timestamp shows "Hoy 10:30" (bodyMedium onSurfaceVariant)
- AND quantity shows "+5" in Plus Jakarta Sans 20w600 green

#### Scenario: Outgoing movement shows negative quantity in red

- GIVEN a movement with quantity -3
- WHEN the row renders
- THEN quantity shows "−3" in Plus Jakarta Sans 20w600 red

### Requirement: FR-03 — Empty State

The system SHALL display "Aún no hay movimientos" when no movements exist in the database.

#### Scenario: User opens Movements tab with no movements

- GIVEN the database has zero movements
- WHEN the user navigates to `/movements`
- AND the streams emit empty list
- THEN the screen shows centered "Aún no hay movimientos" text
- AND no list items are rendered

### Requirement: FR-04 — Loading State

The system SHALL display a CircularProgressIndicator while streams are initializing.

#### Scenario: Initial load shows spinner

- GIVEN the user navigates to `/movements`
- WHEN the providers are still loading
- THEN a centered CircularProgressIndicator is shown
- AND no list or empty state is visible yet

### Requirement: FR-05 — Error State

The system SHALL display "Error al cargar el historial" with a retry hint when the movements stream fails.

#### Scenario: Stream error shows error message

- GIVEN the movements stream emits an error
- WHEN the error state is received
- THEN the screen shows "Error al cargar el historial"
- AND a retry hint is visible

### Requirement: FR-06 — Product Name Resolution with Fallback

The system SHALL resolve product names reactively via productsStreamProvider, showing "—" as fallback when the product stream hasn't emitted the name yet.

#### Scenario: Product name not yet loaded shows fallback

- GIVEN a movement with productId "prod-new" arrives
- AND productsStreamProvider has not yet emitted "prod-new"
- WHEN the row renders
- THEN product name shows "—"
- AND when products stream later emits the name
- THEN the row updates to show the resolved name

### Requirement: FR-07 — List Capped at 50 Items (MVP)

The system SHALL limit the movements list to the 50 most recent items for MVP.

#### Scenario: More than 50 movements exist

- GIVEN the database has 100 movements
- WHEN the user navigates to `/movements`
- THEN only the 50 newest movements are displayed
- AND no pagination controls are shown (deferred)

### Requirement: NFR-01 — Stream Reactivity Within 200ms

The system SHALL react to new movements within 200ms of DAO watch() emission.

#### Scenario: New movement appears reactively

- GIVEN the user is on `/movements`
- WHEN a new movement is registered elsewhere
- THEN the list updates within 200ms to include the new movement at the top

### Requirement: NFR-02 — Smooth Rendering of 50 Items

The system SHALL render 50 items without jank (no expensive builds per frame).

#### Scenario: List renders smoothly

- GIVEN 50 movements exist
- WHEN the list renders
- THEN frame times stay within budget (no jank)
- AND ListView.separated with const itemBuilder is used

### Requirement: NFR-03 — No Database Schema Changes

The system SHALL implement this feature without new database schema or migrations.

#### Scenario: No migrations required

- GIVEN the feature is implemented
- WHEN the app runs
- THEN no database migration runs
- AND existing DAO methods (watchRecent, watchAll) are used

## UI/UX Specs

- Reuse `_MovementItem` visual pattern from `RecentMovementsSection`
- 40px circle icon (incoming: secondaryContainer, outgoing: errorContainer)
- Product name: Inter 14w600, timestamp: bodyMedium onSurfaceVariant
- Quantity: Plus Jakarta Sans 20w600, +green/−red with sign prefix
- Relative timestamps: "Hoy 10:30", "Ayer 16:45", "dd/MM HH:mm"
- Separator: Divider height 1
- Padding: AppTokens.marginMobile horizontal, AppTokens.stackMd vertical

## Data Specs

- Provider: `allMovementsProvider = StreamProvider<List<InventoryMovement>>((ref) => ref.watch(movementRepositoryProvider).watchRecent(limit: 50))`
- Joins with `productsStreamProvider` for name resolution
- Same `_formatTimestamp` logic as `RecentMovementsSection`

## Acceptance Criteria

- All FR/NFR verified via widget tests
- Integration test: navigate to `/movements` → list renders with data