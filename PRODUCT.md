# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Primary user: the small business owner running a small store. They manage inventory on the move — often standing, in the store or warehouse, phone in hand — and are not ERP operators. The job is keeping stock accurate without the overhead of a rigid enterprise tool. For v1, no secondary audience is confirmed.

## Product Purpose

Mi Almacén is an Android app that lets a small business owner track inventory simply: record inbound and outbound movements, see current stock at a glance, and get clear low-stock and out-of-stock alerts. It deliberately positions itself as the friendly, non-intimidating alternative to data-heavy ERP systems — approachable like a lifestyle app, reliable like a financial tool.

## Positioning

The meaningful mechanism is removing the intimidation from inventory control: a small owner gets ERP-grade stock accuracy through a friendly, minimalist, touch-first interface, without learning enterprise terminology or workflows. A neighboring product could copy "inventory tracking", but not the claim that this is the first one that feels safe for a non-ERP owner to use daily.

## Operating Context

Usage happens in the real store or warehouse: sometimes with the phone in one hand while moving boxes, sometimes during a quick pause at the counter. Frequent actions (inbound/outbound, stock checks) must be reachable in seconds, one-handed, inside the thumb zone (bottom two-thirds of the screen). The UI language is Spanish, confirmed — the design brief itself uses the terms "Entrada" and "Salida" for inbound and outbound.

## Capabilities and Constraints

Confirmed v1 scope — inventory only:

- Record inbound (Entrada) and outbound (Salida) stock movements.
- View current stock per item with a prominent quantity display.
- Low-stock and out-of-stock alerts with clear status signals.

Explicitly out of v1 (deliberate, not scope creep): purchasing/supplier management, sales/mini-ERP features, multi-store support.

Technical constraints:

- Flutter app (Dart SDK ^3.12.2), Material Design enabled, `flutter_lints 6` as the analysis standard.
- Android is the only confirmed target platform (no `ios/` folder present).
- Project is a fresh template: `lib/main.dart` is a placeholder, no state-management dependency chosen yet, no tests exist yet, no git repository initialized yet.
- Strict TDD is active for the working session: tests must exist before implementation (runner: `flutter test`).

## Brand Commitments

- Name: **Mi Almacén**.
- The visual authority is the design system already defined in `DESING.MD` at the project root — treat it as a pinned design brief, not a suggestion: "Modern Minimalist" aesthetic, friendly and non-intimidating, a sense of lightness.
- Color semantics are committed: teal-blue primary for actions and brand; emerald for inbound actions and healthy stock; amber for low-stock warnings; softer coral/terracotta (not system red) for out-of-stock and errors; cool gray/off-white neutrals on a very light background (`#F8FAFC`/`#f8f9ff`).
- Typography is committed: Plus Jakarta Sans for headlines and primary stock displays (numerals must stay legible first), Inter for body and labels; a specialized `display-stock` level exists for high-visibility counts.
- Shape language is committed: "Extra Rounded" — 24px cards/sheets, 16px buttons/inputs, pill-shaped status chips; soft ambient shadows and tonal layering instead of harsh borders; 4-column mobile grid with 20px side margins and a 4/8px baseline; minimum 48px touch targets; bottom sheets as the primary add/edit container; a centered FAB for quick actions; prominent rounded search bar.
- Do not silently expand this system. Any visual decision beyond the brief is a change to a committed world and needs explicit discussion.

## Evidence on Hand

- `DESING.MD` — the complete design system at the project root (palette with hex values, typography scale with sizes/weights/line-heights, radii, spacing, and per-component specs: inventory cards, buttons, status chips, bottom sheets, stock toggles, search bar). This is the authoritative design reference for all future UI work.
- `pubspec.yaml` / `analysis_options.yaml` — Flutter template, Dart ^3.12.2, `flutter_lints 6`.
- `lib/main.dart` — placeholder "Hello World" app; no feature code exists yet.
- Absences that future work must not fabricate: no testimonials, customers, benchmarks, pricing, licensing, or deployment claims; no screenshots or real store data.

## Product Principles

1. **Approachability wins.** The owner is not an ERP operator; every screen and every word must feel friendly and safe, never like enterprise software.
2. **Seconds, one-handed, on the move.** The most frequent actions — inbound, outbound, stock check — are reachable within thumb reach without hunting.
3. **Status clarity over dashboards.** Healthy / low / out-of-stock must be readable at a glance; the data is the first thing the user sees.
4. **Inventory-first scope.** V1 does exactly inventory well; sales, purchasing, and accounts are future product decisions, not silent additions.
5. **Spanish-first voice.** The interface speaks the owner's language, with terms the brief itself commits to (Entrada, Salida), in a calm assistant tone, not a system tone.

## Accessibility & Inclusion

- Minimum 48px touch targets are a committed requirement (on-the-go use in warehouse and retail).
- Stock status must stay readable: high-contrast text on low-opacity status tints for chips, so status does not depend on color alone to be legible.
- No additional product-specific accessibility standard has been established for v1.