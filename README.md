# AI-Native SDLC Starter

One command scaffolds a project that runs Anthropic's [AI-Native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
— Plan → Design → Build → Test → Deploy → Maintain — with the Claude Code agents,
skills and guardrail hooks that drive the loop, and a stack that can actually
build, test and lint itself. macOS, Linux and Windows.

**→ Guide, install-command builder and the full walkthrough:
<https://niseel.github.io/ai-sdlc-starter/>**

VI: Một lệnh dựng khung dự án theo AI-Native SDLC của Anthropic, kèm agent, skill,
hook bảo vệ và bộ build/test/lint chạy thật. Hướng dẫn đầy đủ ở link trên.

## Install

```bash
curl -fsSL https://niseel.github.io/ai-sdlc-starter/init.sh | bash -s -- my-app -w node
```

```powershell
irm https://niseel.github.io/ai-sdlc-starter/init.ps1 -OutFile init.ps1
powershell -ExecutionPolicy Bypass -File .\init.ps1 my-app -With node
```

Runtimes: `-w node`, `python`, `go`, `java` — pinned with `@` (`-w python@3.11`),
comma separated for a polyglot repo. For a build that can never change, use the
tagged URL instead of the short one:
`https://raw.githubusercontent.com/Niseel/ai-sdlc-starter/v0.2.0/init.sh`.

The script only pins versions (`.nvmrc`, `.python-version`, `.tool-versions`,
manifests). It does not download runtimes — use [mise](https://mise.jdx.dev), nvm
or asdf. Re-running is safe: existing files are skipped unless you pass `--force`.
`-h` lists every option.

## What you get

```
your-project/
├── intent/ specs/ plans/    # one artifact per stage, committed to git
├── src/ tests/ evals/       # code, tests, agent regression evals
├── Makefile                 # make check = lint + test, the gate
├── AGENTS.md CLAUDE.md      # the same contract for every coding agent
├── REVIEW.md monitoring/    # review policy, alert bands
├── docs/ .github/workflows/ # guide, ADRs, runbooks + CI
└── .claude/                 # 5 agents, 4 skills, 4 guardrail hooks, permissions
```

Then, in Claude Code: `/intent <idea>` → `/spec intent/<file>.md` →
`/feature specs/<file>.md`. Two human gates: approve the plan, approve the commit.
Nothing is pushed for you.

## This repo

| Path | What it is |
|---|---|
| `init.sh`, `init.ps1` | the scaffolders — byte-identical output, checked in CI on Linux, macOS and Windows |
| `index.html`, `assets/` | the landing page (GitHub Pages) |
| `design-system/` | tokens and rules every page here is built from |
| `.claude/skills/` | `design-system` and `extract-design` |
| `docs/AGENT-READINESS.md` | what the generated stacks still miss, and the plan |

Ideas and bug reports: [open an issue](https://github.com/Niseel/ai-sdlc-starter/issues).

MIT — see [LICENSE](LICENSE).
