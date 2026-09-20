---
name: design-system
description: The project's UI design system (rules, tokens, component recipes in design-system/). Use BEFORE creating or changing any UI - HTML, CSS, JSX/TSX, Vue/Svelte templates, Tailwind classes, landing pages, emails, charts. Also use to build or rebuild the design system from a reference website URL.
argument-hint: "[reference URL to (re)build, or empty to apply]"
---
# Design system

Files (source of truth, in this order):
- `design-system/DESIGN.md` - rules and design language. Read it fully first.
- `design-system/tokens.css` - every allowed color, font, size, space, radius, shadow, gradient, motion value.
- `design-system/components.css` - base styles and component recipes built only from tokens.

Request: $ARGUMENTS

If the request is a URL, go to **B. Build**. Otherwise go to **A. Apply**.

## A. Apply (every UI change)

1. Read `design-system/DESIGN.md` before writing markup or styles.
2. Load `tokens.css` then `components.css` in the page or app entry. Use the
   recipes (`.btn`, `.tag`, `.card`, `.stat`, ...) before writing new CSS.
3. Style only with `var(--token)`. No raw hex/rgb, font names, font sizes,
   radii, shadows or durations outside `tokens.css`. Layout-only values
   (grid tracks, widths of one element) are fine.
4. A need the tokens do not cover: use the closest token, then report the gap
   in your reply and append it to the "Gaps" list in `DESIGN.md`. Never invent a token silently.
5. Before you finish, run the check and fix every hit:
   ```bash
   grep -nE '#[0-9a-fA-F]{3,8}\b|rgba?\(' <changed files other than design-system/*>
   ```
6. Check the page at 375 px and 1440 px wide. Check keyboard focus is visible.

## B. Build from a reference URL

Ask before overwriting an existing `design-system/`. Tell the user: we borrow
the design *language* only - never logos, brand names, copy or images.

1. **Extract** - run the `extract-design` skill on the URL. Output goes to `.design-extract/<host>/`.
2. **Verify live** - open the URL in a browser tool at 1440 x 900. Read computed
   styles for: `body`, `h1`-`h4`, main text sizes, primary and secondary buttons
   (and their inner elements), cards, tags, containers, section padding.
   Live computed values beat extractor numbers.
3. **Fonts** - if the source font is commercial, pick the closest Google Font
   that has every subset the project needs (for this repo: `vietnamese`).
   Record the substitution in `DESIGN.md`.
4. **Write** the three files:
   - `tokens.css`: primitives first (raw palette), then semantic tokens that
     point at primitives. Semantic names describe the role (`--text-muted`,
     `--surface-card`), not the color.
   - `components.css`: reset, base typography, then one recipe per component
     seen on the source.
   - `DESIGN.md`: keep the existing section order (Source, Principles, Color,
     Typography, Space and layout, Surfaces, Components, Motion, Accessibility,
     Do / Don't, Gaps).
5. **Prove it** - build a small sample section with the recipes and screenshot
   it next to the source. Report what matches and what does not.
