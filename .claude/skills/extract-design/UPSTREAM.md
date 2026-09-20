# Upstream and audit record

| | |
|---|---|
| Upstream repo | https://github.com/Manavarya09/design-extract (MIT, ~4.1k stars) |
| Upstream skill | `skills/extract-design/SKILL.md` at commit `47f75bb68cd6fcb51c172868a3a1b814cd6bdeb4` |
| Pinned CLI | `designlang@12.21.0` (npm `latest` on 2026-09-19) |
| npm integrity | `sha512-BTu2lxRlf3ybLZrw3WVikNAC0V2kHjXxwKZvuGWESct4DVwti93JZnHN7wz4XpJ2HRLuareW1ItXd62tX2Fb1g==` |
| Audited | 2026-09-19 |

## Why this one

Compared on 2026-09-19:

| Candidate | Result |
|---|---|
| Manavarya09/design-extract (`designlang`) | Chosen. Most complete extraction (colors, type, spacing, shadows, gradients, components, motion, a11y), multi-page crawl, active, MIT. |
| arvindrk/extract-design-system | Smaller output (tokens.json + tokens.css only). Fine, but less data to curate from. |
| kalilfagundes/design-system-extractor-skill | No license, 7 stars. Rejected. |

## What was checked

- Published npm tarball 12.21.0 was unpacked and grepped. Outbound hosts: the
  target site, Google Fonts, and LLM APIs (Anthropic / OpenAI / AtlasCloud).
- The LLM calls live in `src/classifiers/smart.js` and run only with `--smart`.
  The skill forbids that flag, so no page data leaves the machine by default.
- No telemetry or analytics calls. `child_process` is used only to open a
  browser with `--open` and to run `ffmpeg` for screencasts.
- The npm package has a postinstall: `npx playwright install chromium --with-deps`.
  On Linux, `--with-deps` may try `sudo apt-get`. The skill skips lifecycle
  scripts when system Chrome is available.
- End-to-end run against https://www.orchid.security/ (7 pages, ~100 s): exit 0.
  Colors and fonts matched the site's own `:root` variables exactly. Font sizes
  and spacing did not (fluid Webflow type): hence the "verify live" rule.

## Updating

1. Pick a new version, unpack it with `npm pack designlang@<ver>` and repeat the checks above.
2. Update the version in `SKILL.md` and this file.
