---
name: Quantum Finance Dark
colors:
  surface: '#10131a'
  surface-dim: '#10131a'
  surface-bright: '#363940'
  surface-container-lowest: '#0b0e14'
  surface-container-low: '#191c22'
  surface-container: '#1d2026'
  surface-container-high: '#272a31'
  surface-container-highest: '#32353c'
  on-surface: '#e1e2eb'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#e1e2eb'
  inverse-on-surface: '#2e3037'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#ffb95f'
  on-secondary: '#472a00'
  secondary-container: '#ee9800'
  on-secondary-container: '#5b3800'
  tertiary: '#ffb3ad'
  on-tertiary: '#68000a'
  tertiary-container: '#ff7a73'
  on-tertiary-container: '#79000e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#ffddb8'
  secondary-fixed-dim: '#ffb95f'
  on-secondary-fixed: '#2a1700'
  on-secondary-fixed-variant: '#653e00'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ad'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930013'
  background: '#10131a'
  on-background: '#e1e2eb'
  surface-variant: '#32353c'
  surface-glass: '#1e293b'
  border-glass: '#334155'
  market-up: '#10b981'
  market-down: '#ef4444'
  gold-accent: '#f59e0b'
typography:
  display-lg:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  display-lg-mobile:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 12px
    fontWeight: '500'
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
  section-margin: 32px
  stack-gap: 16px
  inner-padding: 12px
  container-padding: 20px
  unit: 4px
---

## Brand & Style

Quantum Finance Dark is an advanced investment interface designed for professional traders and retail investors seeking high-density information with a premium, focused aesthetic. The brand personality is **authoritative, precise, and tech-forward**, evoking a sense of calm control amidst volatile market data.

The design style is a sophisticated hybrid of **Modern Corporate** and **Glassmorphism**. It utilizes a deep-space monochromatic base to minimize eye strain during long sessions, accented by vibrant, functional colors that signal market movement. Translucent layers ("Glass-cards") and subtle glowing gradients create a sense of depth without sacrificing the systematic grid alignment essential for financial clarity.

## Colors

The palette is optimized for a **Dark Mode** first experience. 

- **Primary (#10B981):** Represents growth, stability, and "positive" market action. Used for success states, uptrends, and primary calls to action.
- **Secondary (#F59E0B):** A warm gold used for branding, featured highlights, and active navigation states.
- **Background (#0B0E14):** A near-black neutral that provides a high-contrast foundation for text and data visualizations.
- **Glass Surfaces:** Utilizes a custom slate-gray (#1E293B) with low-opacity borders to create the signature semi-transparent card effect.

Functional color logic is strict: Emerald for gains, Crimson for losses, and Amber for warnings or highlights.

## Typography

The system uses **IBM Plex Sans Arabic** across all levels to ensure a technical, structured feel that supports high-density data and multilingual support. 

- **Display levels** are reserved for brand headers and primary financial figures (e.g., stock prices). 
- **Headline levels** use semi-bold weights to categorize sections clearly.
- **Label levels** use an increased letter-spacing for uppercase or condensed data points, ensuring legibility at small sizes.
- **Alignment:** For RTL (Arabic) contexts, text is right-aligned by default, while numerical data and sparklines maintain a logical left-to-right flow where appropriate.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a max-width of 1280px (7xl) for desktop environments. 

- **Horizontal Margins:** A consistent `container-padding` of 20px ensures content doesn't hit the screen edges on mobile.
- **Vertical Rhythm:** A base `unit` of 4px is used to scale gaps. Major sections are separated by 32px, while related items within a section (like cards in a list) use a 16px gap.
- **Ticker Component:** A full-width, edge-to-edge ticker resides below the header to provide a constant stream of global market data without interrupting the main content flow.
- **Adaptation:** On mobile, the grid collapses to a single column. On tablets and desktops, the Watchlist cards reflow into a 2 or 3-column grid.

## Elevation & Depth

Hierarchy is established through **Glassmorphism and Tonal Layering** rather than traditional heavy shadows.

- **Level 0 (Background):** Pure `#0B0E14` neutral.
- **Level 1 (Cards):** Semi-transparent `#1E293B` with a 1px border (#334155). This creates a "glass" effect that feels elevated above the background.
- **Level 2 (Active States):** Subtle glowing effects (radial gradients) are used behind primary cards to indicate "Pulse" or "Active" states.
- **Navigation:** The bottom navigation bar uses a high `backdrop-blur` (20px+) and 80% opacity to maintain context of the content scrolling behind it.

## Shapes

The shape language is **Modern Rounded**. 

- **Cards and Sections:** Use a radius of 0.75rem (12px) to feel friendly yet professional.
- **Buttons and Filter Chips:** Utilize "Pill" shapes (full-round) for quick actions and category toggles to distinguish them from structural layout cards.
- **Interactive Elements:** Active states on icons use a perfect circle background for hover and press feedback.

## Components

### Buttons & Chips
- **Primary Action:** Pill-shaped, solid `#10B981` background with high-contrast text.
- **Filter Chips:** Outlined or low-intensity surface color. Active state switches to the primary background with a subtle glow shadow.

### Cards
- **Glass Card:** The workhorse of the system. Includes a 1px stroke, consistent 16px-24px padding, and flexbox internal layouts. Hover states should slightly brighten the border color or increase the glow effect.

### Data Visualization
- **Sparklines:** Minimalist, 2px stroke width, no-fill SVG paths. Color should match the trend (Primary for up, Tertiary for down).
- **Progress Bars:** Dual-sided bars used for sentiment or liquidity indicators, using high-contrast colors against a dark track.

### Navigation
- **Top App Bar:** Sticky, containing the brand and global actions (notifications, market selector).
- **Bottom Nav:** Optimized for thumb reach on mobile with clear icons and 12px label text.

### Feedback
- **Badges:** Small, high-contrast pills (e.g., red for notifications) placed on the top-right of parent icons.