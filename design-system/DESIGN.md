# Design system - "Midnight Glass"

Rules for every UI in this repo. Agents: read this file fully before writing
markup or styles, then use `tokens.css` + `components.css`. The `design-system`
skill enforces it.

## Source

| | |
|---|---|
| Reference | https://www.orchid.security/ (design language only) |
| Captured | 2026-09-19, live computed styles at 1440 x 900 + `designlang@12.21.0` (7 pages) |
| Font swap | Aeonik (commercial) -> **Be Vietnam Pro** (Google Fonts, has `vietnamese`). Mono: **Inconsolata** (same as source). |
| Not borrowed | Logo, brand name, copy, images, illustrations. Never copy these. |

## 1. Principles

1. **Dark first.** One deep midnight canvas (`--bg-page`). No white sections, no light theme.
2. **Glass on midnight.** Surfaces are soft vertical gradients with a 1-1.5 px gradient ring, not flat fills with hard borders.
3. **Light type, big air.** Headings are regular weight (400), never bold. Display numbers are light (300). Whitespace does the work.
4. **Violet acts, lavender guides, lime sparks.** Violet only on primary actions. Lavender for accents, links, rings, icons. Lime at most once per viewport.
5. **Glow, not shadow.** Depth comes from blurred color glows and background orbs, not dark drop shadows.
6. **Pills and soft corners.** Controls are pills. Cards 24 px, big panels 32 px.

## 2. Color

| Role | Token | Value | Use |
|---|---|---|---|
| Page | `--bg-page` | `#080023` | Body background. Only one. |
| Band | `--bg-band` | white 5% | Full-width section tint to separate bands |
| Text | `--text` | `#ededed` | Default body and headings |
| Strong | `--text-strong` | `#ffffff` | Text on violet, hover |
| Muted | `--text-muted` | white 70% | Paragraphs under headings, descriptions |
| Subtle | `--text-subtle` | `#9999a7` | Labels, meta, captions (7.2:1 on page) |
| Accent | `--accent` | `#ac91ff` | Links, icons, rings, highlights in text |
| Action | `--action` | `#5e30ff` | Primary action color (via button gradient) |
| Highlight | `--highlight` | `#ddff6f` | Status dot, one key highlight per view |
| Info / decor | `--info`, `--decor` | `#7dd7e0`, `#ff8bfb` | Data viz and decoration only |
| Hairline | `--border-hairline` | lavender 15% | Glass borders, dividers |

Rules:
- Never use `--action` violet as text on the page: 3.2:1, fails AA. Use `--accent` for colored text.
- Never pure black (`#000`) backgrounds. Never gray drop shadows on dark.
- Text on the primary button is `--text-strong` (white), 5:1 or better.
- Gradients live in tokens (`--grad-*`). Do not write new ones inline.

## 3. Typography

| Token | Size | Weight | Line height | Use |
|---|---|---|---|---|
| `--fs-display` | 72 -> 150 px | 300 | 1.05, -0.01em | Big stat numbers only |
| `--fs-h1` | 40 -> 72 px | 400 | 1.1 | Hero title, section titles |
| `--fs-h2` | 32 -> 48 px | 400 | 1.1 | Sub-section titles, CTA panel |
| `--fs-h3` | 26 -> 32 px | 400 | 1.1 | Card titles (large), quotes |
| `--fs-h4` | 20 -> 24 px | 400 | 1.2 | Card titles, FAQ questions |
| `--fs-lead` | 18 -> 20 px | 400 | 1.4 | Intro paragraph under a title |
| `--fs-body` | 16 -> 18 px | 400 | 1.4 | Body, buttons |
| `--fs-small` | 16 px | 400 | 1.4 | Tags, secondary text |
| `--fs-xs` | 14 px | 500 | 1.4 | Labels, meta |
| `--fs-code` | 17 px | 400 | 1.4 | Inconsolata code |

Rules:
- Headings in **Title Case** (English). Vietnamese headings: sentence case.
- Weight 700 only for tiny labels. Never bold a heading.
- One `h1` per page. Keep paragraphs within `--measure` (60ch).
- Stat numbers: number in `--grad-text-fade`, unit (`%`, `+`, `x`) in `--grad-text-lavender`.

## 4. Space and layout

- Scale: `--space-1..10` = 4, 8, 12, 16, 20, 24, 32, 48, 64, 100 px. No other gaps.
- Containers: `--container` 1116 px (default), `--container-wide` 1240 px. Side gutter `--gutter` 20 -> 40 px.
- Sections: `--section-y` vertical padding (64 -> 100 px). Section head is centered: tag, title, lead, then `--space-9` to content.
- Grids: `--grid-gap` 32 px. Bento layouts: one large card + two stacked.
- Mobile (< 768 px): single column, buttons may go full width, nav collapses.

## 5. Surfaces

| Recipe | Look | Use |
|---|---|---|
| `.card` | `--grad-card` + 1.5 px lavender ring, radius 24 | Default content card, stats |
| `.card--angled` | 220deg gradient | Alternate card in a bento |
| `.card--step` | `--grad-step` (deeper indigo) | Numbered steps, timeline items |
| `.card--glass` | transparent -> white 5%, hairline border, blur 40 | Cards over orbs / imagery |
| `.panel` | glass, radius 32, 64 px padding | Big CTA or testimonial blocks |
| `.section--band` | white 5% full width | Separate one band from the next |

## 6. Components (in `components.css`)

- **Buttons** `.btn` + `--primary` (violet gradient) / `--secondary` (white -> grey, ink text) / `--ghost` (glass). Pill, 16 x 28 px padding, 18 px / 500. Max two side by side: primary first. `.btn--sm` in the nav.
- **Tag** `.tag` - eyebrow above section titles. Optional `.tag__dot` (lime) for "live / new".
- **Stat** `.stat__value > .num + .unit`, `.stat__label`, `.stat__note`.
- **Icon badge** `.icon-badge` - 48 px lavender circle with glow. Icons are 1.5 px outline, `currentColor`.
- **Code** `.code-inline`, `.codeblock` (with `.prompt`, `.comment`, `.ok`, `.info`).
- **Tabs** `.tabs` with `role="tab"` buttons; selected tab gets the primary gradient.
- **Form** `.field` + `.input` (also on `select`).
- **FAQ** `.faq` with native `details/summary`.
- **Decor** `.orb.orb--violet|--blue` absolute, behind content; `.hairline` gradient divider.
- **Toggling**: use the `hidden` attribute; `components.css` forces it to win over `display`.

## 7. Motion

- Durations: `--dur-fast` 150, `--dur-base` 200, `--dur-slow` 300, `--dur-reveal` 600 ms. Easing `--ease-out`.
- Reveal on scroll: JS adds `has-reveal` to `<html>`, then toggles `.reveal` -> `.is-visible` (fade + 24 px rise). Without JS nothing is hidden. Stagger siblings by 80 ms, 320 ms max.
- Hover: buttons brighten + lavender glow; link cards lift 4 px + glow. No bounce, no spin.
- Always honor `prefers-reduced-motion` (already in `components.css`).

## 8. Accessibility

- Contrast: `--text` 16:1, `--text-muted` about 9:1, `--text-subtle` 7.2:1, `--accent` 8:1 on the page.
- Focus: `:focus-visible` lavender 2 px outline, 3 px offset. Never remove it.
- Orbs never sit behind body text at full opacity. Decorative SVG gets `aria-hidden="true"`.
- Interactive targets at least 44 x 44 px on touch.

## 9. Do / Don't

Do:
- Start every section with tag -> title -> lead, centered.
- Use one primary button per view.
- Put code and commands in `.codeblock` with a copy button.

Don't:
- Invent hex values, font sizes, radii or shadows. Add a token first (and log it below).
- Use bold headings, all-caps headings, or more than 2 font families.
- Put lime on large areas, or violet text on the dark page.
- Use flat gray cards or hard 1 px white borders.

## 10. Gaps

Needs not covered by the reference. Add one line each time you work around one.

- Light theme: not defined by the reference. Out of scope.
- Error / success states: no reference. Use `--highlight` for success, `--decor` for error until defined.
- HTML `<meta name="theme-color">` and SVG favicons need literal colors. Mirror `--bg-page` / `--accent` there; nowhere else.
