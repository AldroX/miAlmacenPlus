---
name: Mi Almacén
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3f484c'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6f787d'
  outline-variant: '#bec8cd'
  surface-tint: '#006781'
  primary: '#005a71'
  on-primary: '#ffffff'
  primary-container: '#0e7490'
  on-primary-container: '#d3f1ff'
  inverse-primary: '#81d1f0'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#764900'
  on-tertiary: '#ffffff'
  tertiary-container: '#965f00'
  on-tertiary-container: '#ffe9d4'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b9eaff'
  primary-fixed-dim: '#81d1f0'
  on-primary-fixed: '#001f29'
  on-primary-fixed-variant: '#004d62'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-stock:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-stock:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  margin-mobile: 20px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style
The design system focuses on empowering small business owners through a friendly, non-intimidating interface. It moves away from the rigid, data-heavy feel of traditional ERPs toward a "Modern Minimalist" aesthetic that feels as approachable as a lifestyle app but as reliable as a financial tool.

The style emphasizes clarity, high-quality whitespace, and a sense of "lightness." By using soft depth and rounded geometry, the UI reduces the cognitive load associated with inventory management, making productivity feel effortless and welcoming.

## Colors
The palette is rooted in productivity and status clarity. 

- **Primary (Teal-Blue):** Used for main actions, navigation, and brand presence. It strikes a balance between professional trust and modern freshness.
- **Success (Emerald):** Specifically designated for "Entrada" (Inbound) actions and healthy stock levels.
- **Warning (Amber):** Used for "Low Stock" alerts to prompt reordering without causing panic.
- **Danger (Coral/Terracotta):** Reserved for "Out of Stock" or errors, using a softer tone than standard "System Red" to maintain the friendly vibe.
- **Neutrals:** A range of cool grays and off-whites ensure the interface feels spacious and clean. Backgrounds should use a very light gray (#F8FAFC) to let white cards pop.

## Typography
The typography system prioritizes the legibility of numbers. **Plus Jakarta Sans** is used for headlines and primary stock displays due to its friendly, open counters and modern geometric feel. **Inter** is used for all functional body text and labels to ensure maximum clarity at small sizes.

A specialized `display-stock` level is defined for high-visibility inventory counts. When displaying currency or quantities, use medium or semi-bold weights to ensure the data is the first thing the user sees.

## Layout & Spacing
This design system utilizes a fluid 4-column grid for mobile devices with a generous 20px side margin to prevent the UI from feeling cramped. 

The vertical rhythm follows a strict 4px/8px baseline. Large touch targets (minimum 48px height) are mandatory for all interactive elements to support "on-the-go" usage in warehouse or retail environments. 

Bottom sheets are the primary container for adding or editing items, keeping the most frequent actions within the natural "thumb zone" at the bottom two-thirds of the screen.

## Elevation & Depth
Depth is created through **Tonal Layering** and soft **Ambient Shadows**. 

- **Surface Layer:** The main background is a flat, light tint.
- **Card Layer:** White surfaces use a very soft, diffused shadow (Blur: 15px, Y: 4px, Opacity: 5%) to appear lifted and tappable.
- **Modal Layer:** Bottom sheets use a high-elevation shadow and a 40% opacity neutral-dark backdrop blur to focus the user's attention.

Avoid using harsh borders; instead, use subtle 1px inner strokes in a slightly darker neutral shade to define boundaries on white backgrounds.

## Shapes
The shape language is "Extra Rounded" to evoke friendliness and safety. 

- **Cards & Sheets:** Use a consistent 24px corner radius (`rounded-xl` in this system).
- **Buttons & Inputs:** Use a 16px radius (`rounded-lg`) to maintain a cohesive look with larger containers.
- **Status Chips:** Use a full "Pill" shape (999px) to distinguish them clearly from interactive buttons.

## Components
- **Inventory Cards:** Must feature the `display-stock` number prominently on the right side. The background of the card should remain white, but can feature a subtle left-edge accent color indicating status (Success/Warning/Danger).
- **Primary Buttons:** High-contrast Teal-Blue with white text, 56px height for maximum thumb-friendliness.
- **Status Chips:** Small, pill-shaped badges with a low-opacity background tint (e.g., 10% Success Color) and high-contrast text for stock status.
- **Quick Action Bottom Sheets:** Triggered from a centered Floating Action Button (FAB). These should contain large, clear input fields with 16px padding.
- **Stock Toggles:** Large "Plus" and "Minus" buttons in "Entrada/Salida" flows should be styled as tactile, circular icons to prevent input errors.
- **Search Bar:** A prominent, rounded input at the top of the inventory list with a 12% gray fill to distinguish it from the item cards.