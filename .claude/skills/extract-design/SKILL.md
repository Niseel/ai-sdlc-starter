---
name: extract-design
description: "Extract the full design language from any public website URL with designlang (colors, typography, spacing, radii, shadows, gradients, components, breakpoints, motion, WCAG score). Use when the user says 'extract design', 'get design system', 'design language', 'design tokens', 'what colors/fonts does this site use', or when the design-system skill needs raw data from a reference site."
argument-hint: "[public website URL]"
allowed-tools: Bash, Read, Glob
---

# Extract Design Language

<!-- Vendored from github.com/Manavarya09/design-extract (MIT) - see UPSTREAM.md.
     Local changes: version pinned, lifecycle scripts skipped, output dir fixed,
     steps 3-4 point at the design-system skill instead of copying themes. -->

Run the `designlang` extractor against one public URL and read what it found.
This skill produces RAW data only. Turning it into the project's rules is the
job of the `design-system` skill.

## 1. Run the extraction (pinned version)

Use the pinned, audited release. Do not use `@latest`.

If Google Chrome is installed (fast path, skips the 150 MB Chromium download):

```bash
npm_config_ignore_scripts=true npx -y designlang@12.21.0 <url> \
  --system-chrome --depth 2 --screenshots --wait 2500 --no-history \
  -o .design-extract/<host>
```

If Chrome is not installed, drop both `npm_config_ignore_scripts=true` and
`--system-chrome`. The package postinstall then downloads Playwright Chromium.

- Dark-mode sites with a light variant: add `--dark`.
- Single-page apps that render late: raise `--wait` (ms).
- Never pass `--smart`: it sends a page digest to a third-party LLM API.
- Never pass `--cookie` / `--cookie-file` unless the user gives them explicitly.

## 2. Read the results

```bash
ls .design-extract/<host>
```

Read, in this order:
1. `*-DESIGN.md` - compact summary (colors, type, layout, elevation, shapes).
2. `*-variables.css` - every CSS custom property the site declares. Most exact source for colors.
3. `*-design-tokens.json` - W3C tokens, if a value is missing above.
4. `screenshots/*.png` - hero, nav, buttons, cards; view them to understand the style.

## 3. Known extractor limits (verify before trusting)

- **Fluid type and spacing**: sites that scale with `vw` (common on Webflow)
  report inflated font sizes and a noisy spacing scale. Measure the live page
  with a browser tool at 1440 px width before using any size.
- **Background role**: on dark sites `background` may be reported as `#ffffff`.
  Trust the "Dominance (share of painted area)" line instead.
- **Breakpoints** may print as `[object Object]px`. Read them from the CSS instead.
- Colors, font families, shadows and gradients are usually exact.

## 4. Present findings, then hand off

Tell the user: primary palette (hex), font families, spacing base, radius and
shadow habits, WCAG score, component patterns, and what you could not verify.

Then continue with the `design-system` skill to curate the project rules.
Do not copy the generated Tailwind/shadcn/theme files into the project unless
the user asks for them.

`.design-extract/` is scratch output. It stays out of git.
