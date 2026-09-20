# ai-sdlc-starter

One-command scaffolder for Anthropic's AI-Native SDLC playbook, plus its landing page.

- `init.sh` / `init.ps1` - the scaffolders. `VERSION` - current release.
- `index.html`, `assets/` - landing page, served by GitHub Pages from the repo root.
- `design-system/` - UI rules and tokens for every page in this repo.

## Rules

- **UI work** (anything in `index.html`, `assets/`, or any new page): invoke the
  `design-system` skill first and follow `design-system/DESIGN.md`. Style only with
  tokens from `design-system/tokens.css` and recipes from `design-system/components.css`.
- To change the design language from a reference site: `/design-system <url>`.
- **Scripts**: `init.sh` and `init.ps1` must produce byte-identical
  files. Change both together. Keep them ASCII-only and dependency-free.
- Bump `VERSION` and the version string inside both scripts together, then tag `v<VERSION>`.
- CI (`.github/workflows/scaffold-test.yml`) runs both scripts on Linux, macOS and Windows and diffs the output. Keep it green.
