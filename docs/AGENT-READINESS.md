# Is the generated project ready for agents? — gap analysis for v0.1.0

> VI: Bộ khung sáu giai đoạn đã tốt. Bốn stack ngôn ngữ thì chưa: dự án sinh ra
> không cho agent một lệnh kiểm chứng nào chạy được, và `npm test` mặc định luôn
> báo thành công. Đây là danh sách thiếu sót và kế hoạch v0.2.

**Verdict.** The SDLC skeleton (artifacts, agents, skills, hooks, gates) matches the
playbook. The four runtime stacks do not yet clear the bar every major vendor now
sets: an agent must be able to *verify its own work* from a clean checkout.

## What the guidance actually says

| Source | The requirement it puts on a repo |
|---|---|
| [Anthropic, Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) | "Give Claude a check it can run: tests, a build, a screenshot to compare." Without it, "looks done" is the only signal and the human becomes the verification loop. CLAUDE.md should carry "Bash commands Claude can't guess" and testing instructions, and stay short. Hooks are the deterministic version of a rule; a Stop hook can block the turn until the check passes. |
| [Anthropic, The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) | Each stage commits an artifact the next stage reads; humans gate plan and merge. Already implemented here. |
| [OpenAI, Codex best practices](https://learn.chatgpt.com/guides/best-practices) | `AGENTS.md` should cover "repo layout and important directories", "How to run the project", "Build, test, and lint commands", "Engineering conventions and PR expectations", "Constraints and do-not rules", and "What done means and how to verify work". Keep approvals and sandboxing tight by default. |
| [agents.md](https://agents.md/) (Agentic AI Foundation) | One open file read by Codex, Cursor, Copilot, Gemini CLI, Jules, Aider and others; ~60k repos. Nested files: the nearest one wins. |
| Practitioner consensus ([agent-ready](https://github.com/tlyleung/agent-ready), [repo-readiness checks](https://www.roborhythms.com/make-your-repo-agent-ready/)) | One entry point used identically by humans, hooks, CI and agents. The test command must succeed from a clean checkout. Secret scanning in both a pre-commit hook and CI, because hooks can be skipped. |

## What v0.1.0 generates today

Measured by running `init.sh` with every runtime:

| Runtime | Files written | Can an agent build/test/lint? |
|---|---|---|
| Node | `.nvmrc`, `package.json` with `"test": "echo \"TODO test\" && exit 0"` | **No — worse than no test.** The suite always passes, so a broken change looks verified. |
| Python | `.python-version`, `pyproject.toml` (ruff config only) | No test runner, no pytest config, no type checker, no lock file. |
| Go | `go.mod` | No `Makefile`, no example `_test.go`, no linter config. `go test ./...` passes vacuously. |
| Java | **one line in `.tool-versions`** | **No build file at all.** No Maven or Gradle, so nothing to build, test or lint. |

Cross-cutting, for all four:

1. **`CLAUDE.md` ships placeholders.** The Commands section reads
   `- Test: <e.g. make test | npm test | pytest -q>`. The single most valuable
   thing in the file is left for the human to fill in, and the loop does not
   start working until they do.
2. **No `AGENTS.md`.** Every non-Claude agent — Codex, Cursor, Copilot, Gemini
   CLI — starts with zero project context, even though the same commands would serve them.
3. **No single entry point.** `.claude/settings.json` already allowlists
   `make build`, `make test` and `make lint`, but no `Makefile` is ever written.
   The allowlist points at nothing.
4. **No CI for the generated project's own code.** The two workflows cover agent
   evals and Claude review; nothing runs the project's build or tests on a PR.
5. **`evals/check.sh` ends in `exit 0`.** Same false-pass failure mode as `npm test`.
6. **No secret scanning.** `.env.example` exists, `.gitignore` covers `.env`, but
   nothing blocks a key pasted into source — the case agents actually cause.
7. **No dependency policy.** No Dependabot or Renovate, so "update the deps" is
   an unbounded agent action.
8. **No reproducible environment.** No lock files, no dev container, no setup
   script, so "works from a clean checkout" is unproven.
9. **No `.mcp.json`.** Nothing shows the team how to wire external tools.
10. **No Stop hook.** The four hooks block bad actions, but none *gates the end of
    a turn* on the project's own tests, which is the deterministic form of the
    verification loop Anthropic recommends.

## Plan for v0.2

**P0 — make the verification loop real** (without this nothing else matters)

- Per runtime, write a working test, lint and build command, and one example test
  that actually runs: Node → `node --test` (built in, no dependency); Python →
  `pytest` + config; Go → `go test ./...` + an example `_test.go`; Java → a Maven
  `pom.xml` with JUnit 5 (`mvn -q verify`).
- Generate a `Makefile` with `build`, `test`, `lint`, `fmt`, `check` that delegates
  to whichever runtimes were selected. One entry point for humans, hooks, CI and agents.
- Fill the `CLAUDE.md` Commands section automatically from the chosen runtimes.
- Generate `AGENTS.md` with the sections OpenAI lists, pointing at the same `make`
  targets, and have `CLAUDE.md` reference it instead of repeating it.
- Add `.github/workflows/ci.yml` running `make check` on push and PR.
- Delete the always-green stubs. A missing implementation must fail, not pass.

**P1 — guardrails that survive a skipped hook**

- `gitleaks` in a pre-commit hook and in CI.
- Dependabot config for the selected ecosystems.
- A Stop hook that runs `make test` and blocks the turn while it fails.
- `.mcp.json` example, commented.
- `.devcontainer/` with the pinned runtimes, so a clean checkout is one command.

**P2 — depth**

- Type checking per runtime (mypy or ty, tsc, golangci-lint, Error Prone).
- Release workflow and SBOM.
- Per-directory `AGENTS.md` for `src/` and `tests/` once a project grows.

## Open questions for the maintainer

- Java: Maven or Gradle as the default? Maven's `pom.xml` is one file and needs no
  wrapper download; Gradle needs `gradlew` committed.
- Node: plain `node --test` (zero dependencies, matches the "dependency-free"
  promise) or Vitest (better DX, adds an install step)?
- Python: `uv` as the default (fast, writes `uv.lock`) or stay with plain `pip` +
  `pyproject.toml`?
