<#
=============================================================================
 init.ps1   (init-ai-sdlc v0.1.0)
 EN: Scaffolds an AI-Native SDLC project (Anthropic 6-stage playbook:
     Plan -> Design -> Build -> Test -> Deploy -> Maintain).
 VI: Tao khung du an theo AI-Native SDLC cua Anthropic (6 giai doan:
     Plan -> Design -> Build -> Test -> Deploy -> Maintain).

 Usage / Cach dung:
   ./init.ps1 [NAME] [-With LIST] [-Dir PATH] [-Force] [-NoGit] [-Help]

 Examples / Vi du:
   ./init.ps1 my-app -With node,python@3.12
   ./init.ps1 svc -With go@1.22 -Dir ./svc

 Note: identical output to init.sh. Run in PowerShell 5+ / pwsh 7+.
 Neu chan chinh sach, chay: powershell -ExecutionPolicy Bypass -File init.ps1
=============================================================================
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [Alias("n")]
  [string]$Name = "",
  [Alias("w")]
  [string]$With = "",
  [Alias("d")]
  [string]$Dir = ".",
  [string]$Node = "",
  [string]$Python = "",
  [string]$Go = "",
  [string]$Java = "",
  [switch]$Force,
  [switch]$NoGit,
  [switch]$Help
)

$ErrorActionPreference = "Stop"
$SCRIPT_VERSION = "0.1.0"

function Show-Usage {
@'
init-ai-sdlc  -  AI-Native SDLC project scaffolder

EN  Options:
VI  Tuy chon:
Usage / Cach dung:
  .\init.ps1 [NAME] [-With LIST] [options]

  NAME           EN: project name (default: current folder)  VI: ten du an
  -With LIST     EN: runtimes, comma separated                VI: runtime, cach nhau dau phay
                     node,python@3.12,go@1.22,java@21
  -Name NAME     EN: project name, same as NAME              VI: nhu NAME
  -Dir PATH      EN: target directory (default: .)           VI: thu muc dich
  -Node VER      EN: pin Node version (e.g. latest, 22, 20)  VI: ghim ban Node
  -Python VER    EN: pin Python version (e.g. 3.12, 3.10)    VI: ghim ban Python
  -Go VER        EN: pin Go version (e.g. 1.22)              VI: ghim ban Go
  -Java VER      EN: pin Java version (e.g. 21)              VI: ghim ban Java
  -Force         EN: overwrite existing files                VI: ghi de file da co
  -NoGit         EN: do not run 'git init'                   VI: khong chay git init
  -Help          EN: show this help                          VI: hien tro giup

Examples / Vi du:
  .\init.ps1 my-app -With node,python@3.12
  .\init.ps1 svc -With go@1.22 -Dir ./svc

NOTE / LUU Y:
  EN: This script only PINS versions. It does NOT download runtimes.
  VI: Script CHI GHIM phien ban. KHONG tai runtime ve.
'@ | Write-Host
}

if ($Help) { Show-Usage; exit 0 }

# ---- Runtime list: -With node,python@3.12 / Danh sach runtime ---------------
# EN: "name" alone uses the default version below; "name@ver" pins that version.
# VI: Chi "ten" thi dung ban mac dinh ben duoi; "ten@ban" thi ghim dung ban do.
if ($With) {
  foreach ($item in ($With -split ",")) {
    $trimmed = $item.Trim()
    if (-not $trimmed) { continue }
    $parts = $trimmed -split "@", 2
    $runtime = $parts[0].ToLower()
    $ver = if ($parts.Count -gt 1) { $parts[1] } else { "" }
    switch ($runtime) {
      { $_ -in "node", "nodejs", "js", "ts" } { if ($ver) { $Node = $ver } else { $Node = "latest" } }
      { $_ -in "python", "py" }               { if ($ver) { $Python = $ver } else { $Python = "3.12" } }
      { $_ -in "go", "golang" }               { if ($ver) { $Go = $ver } else { $Go = "1.22" } }
      { $_ -in "java", "jvm", "kotlin" }      { if ($ver) { $Java = $ver } else { $Java = "21" } }
      default {
        Write-Host "[warn] Unknown runtime / Runtime la: $runtime" -ForegroundColor Yellow
        Show-Usage
        exit 1
      }
    }
  }
}

function Ok   ($m) { Write-Host "[ok]   $m"   -ForegroundColor Green }
function Info ($m) { Write-Host "[info] $m"   -ForegroundColor Cyan }
function Warn ($m) { Write-Host "[warn] $m"   -ForegroundColor Yellow }
function Skip ($m) { Write-Host "[skip] $m"   -ForegroundColor DarkGray }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
Set-Location $Dir
if ([string]::IsNullOrEmpty($Name)) { $Name = Split-Path -Leaf (Get-Location).Path }

Info "init-ai-sdlc $SCRIPT_VERSION"
Info "Project / Du an: $Name"
Info "Target  / Thu muc: $((Get-Location).Path)"
if ($Node)   { Info "Node:   $Node" }
if ($Python) { Info "Python: $Python" }
if ($Go)     { Info "Go:     $Go" }
if ($Java)   { Info "Java:   $Java" }

# ---- File writer: skips existing unless -Force / Ham ghi file ----------------
function Write-File {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  if ((Test-Path $Path) -and (-not $Force)) { Skip $Path; return }
  # Write UTF-8 without BOM, LF line endings, exactly one trailing newline (match bash heredocs)
  $lf = $Content -replace "`r`n", "`n"
  if (-not $lf.EndsWith("`n")) { $lf += "`n" }
  [System.IO.File]::WriteAllText((Join-Path (Get-Location) $Path), $lf, (New-Object System.Text.UTF8Encoding($false)))
  Ok $Path
}
function New-Keep { param([string]$Dir)
  New-Item -ItemType Directory -Force -Path $Dir | Out-Null
  $k = Join-Path $Dir ".gitkeep"; if (-not (Test-Path $k)) { New-Item -ItemType File -Force -Path $k | Out-Null }
}

# ---- 1) Directories ----------------------------------------------------------
$dirs = @('intent','specs','plans','docs/adr','docs/runbooks','docs/incidents',
          'evals','monitoring','src','tests','scripts',
          '.claude/agents','.claude/skills','.claude/hooks','.github/workflows')
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
New-Keep 'src'; New-Keep 'tests'; New-Keep 'scripts'

# ---- 2) Root files -----------------------------------------------------------
Write-File 'README.md' (@'
# __NAME__

> AI-Native SDLC project (Anthropic 6-stage playbook).
> Du an theo AI-Native SDLC cua Anthropic (6 giai doan).

## The loop / Vong lap
Plan -> Design -> Build -> Test -> Deploy -> Maintain, and back.
Each stage commits one version-controlled artifact that the next stage reads:
Moi giai doan commit mot artifact vao git de giai doan sau doc:

| Stage | Artifact | Folder |
|-------|----------|--------|
| Plan | `intent.md` | `intent/` |
| Design | `spec.md` | `specs/` |
| Build | `plan.md` + code | `plans/`, `src/` |
| Test | tests + evals | `tests/`, `evals/` |
| Deploy | PR + review findings | `REVIEW.md`, `.github/` |
| Maintain | incident record | `docs/incidents/`, `monitoring/` |

## Quick start / Bat dau nhanh
1. `claude` in this repo. It reads `CLAUDE.md` automatically.
2. Capture an idea:  `/intent <your idea>`  -> writes `intent/*.md`.
3. Turn it into a spec: `/spec intent/<file>.md` -> writes `specs/*.md`.
4. Build it end-to-end: `/feature specs/<file>.md` (plan -> code -> test -> review).

## Human gates / Cong duyet cua nguoi
- GATE 1: approve the plan / duyet plan.
- GATE 2: approve the commit / duyet commit. Nothing is pushed automatically.

See `docs/AI-SDLC.md` for the full guide. Xem huong dan day du o `docs/AI-SDLC.md`.
'@ -replace '__NAME__', $Name)

Write-File '.gitignore' @'
# Dependencies
node_modules/
.venv/
venv/
__pycache__/
*.pyc
vendor/
# Build output
dist/
build/
out/
target/
# Env & secrets  (NEVER commit real secrets / KHONG BAO GIO commit secret that)
.env
.env.*
!.env.example
secrets/
*.key
*.pem
# Claude local overrides
.claude/settings.local.json
.claude/agent-memory-local/
# OS / editor
.DS_Store
Thumbs.db
.idea/
.vscode/
'@

Write-File '.env.example' @'
# EN: Copy to .env and fill in. Never commit the real .env.
# VI: Copy thanh .env va dien. Khong bao gio commit .env that.
APP_ENV=development
# ANTHROPIC_API_KEY=   # only needed for CI evals / chi can cho CI evals
'@

Write-File '.editorconfig' @'
root = true
[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2
[*.{py,go}]
indent_size = 4
[*.md]
trim_trailing_whitespace = false
'@

Write-File 'REVIEW.md' @'
# Review instructions / Huong dan review

## Passes / Cac luot review
Run three passes and tag each finding with its pass:
Chay 3 luot, gan nhan cho moi phat hien:
- Bugs: logic errors, broken edge cases, subtle regressions.
- Security: injection, authentication/authorization gaps, PII in logs, secrets.
- Compliance: change matches specs/*.md, plans/*.md and design principles.

## What "Important" means / The nao la "Quan trong"
Reserve Important for findings that break behaviour, leak data, or breach policy.
Style and naming are Nits. / Style va dat ten chi la Nit.

## Cap the nits / Gioi han Nit
Report at most five nits per review; summarize the rest as a count.

## Do not report / Khong bao cao
Generated files and anything CI already enforces.
'@

Write-File 'CLAUDE.md' (@'
# __NAME__

<!-- EN: Keep this under a page. Claude reads ALL of it every session. -->
<!-- VI: Giu duoi 1 trang. Claude doc TAT CA moi phien. -->

## Commands / Lenh
<!-- EN: Fill these in for your stack. Show a healthy output example. -->
<!-- VI: Dien theo stack cua ban. Kem vi du output binh thuong. -->
- Build:     <e.g. make build | npm run build | go build ./...>
- Test:      <e.g. make test  | npm test      | pytest -q | go test ./...>
- Lint:      <e.g. make lint   | npm run lint  | ruff check .>
- Typecheck: <e.g. npm run typecheck | mypy .>

## Conventions / Quy uoc
- <language/version, formatting, patterns to follow>
- <ban rules: e.g. money is BigDecimal not float>

## Architecture / Kien truc
- src/ ... , tests/ ... , scripts/ ...
- <where domain logic lives; what is generated and must not be edited>

## Verifying your work / Kiem chung
- Run Build + Test + Lint before reporting a task done, and paste the output.
- If a test fails, fix the CODE, not the test. Never skip or delete a test.
- Chay Build + Test + Lint truoc khi bao xong, dan output ra.
- Neu test fail, sua CODE chu khong sua test. Khong bao gio skip/xoa test.

## Things Claude gets wrong / Loi Claude hay mac
<!-- EN: Add a line here every time Claude repeats a mistake twice. -->
<!-- VI: Moi khi Claude sai 2 lan, them 1 dong o day. -->
- <e.g. do not bump dependency versions; the platform team owns them>
'@ -replace '__NAME__', $Name)

# ---- 3) Stage artifacts ------------------------------------------------------
Write-File 'intent/_TEMPLATE.md' @'
# Intent: <short title>
Author: <name (role)>. Status: draft.

## Problem / Van de
<What cannot be done today; who is affected. / Hom nay khong lam duoc gi; ai bi anh huong.>

## Proposed outcome / Ket qua mong muon
<What "better" looks like. / "Tot hon" trong nhu the nao.>

## Affected users and systems / Nguoi dung & he thong lien quan
<...>

## Constraints / Rang buoc
<Security, PII, auth, budget, deadlines. / Bao mat, PII, xac thuc, ngan sach, han chot.>

## Open questions / Cau hoi con mo
1. <...>
'@

Write-File 'intent/EXAMPLE-claims-status.md' @'
# Intent: claims status self-service
Author: J. Ortiz (claims operations). Status: draft.

## Problem
Customers phone the contact center to ask where their claim is.
Handlers spend roughly a third of call time on status-only queries.

## Proposed outcome
Customers see claim status, next step and expected date in the portal.

## Affected users and systems
Claims handlers, portal team, claims-core API.

## Constraints
No new PII in the portal session. Existing authentication only.

## Open questions
Do third-party loss adjusters need access too?
'@

Write-File 'specs/_TEMPLATE.md' @'
# Spec: <title>   (from intent/<file>.md)

## Summary / Tom tat
<What we are building and why. / Xay gi va tai sao.>

## Requirements / Yeu cau
- R1: ...
- R2: ...

## Design / Thiet ke
<Approach, data model / API changes, UX. Alternatives rejected (1 line each).>
<Cach lam, mo hinh du lieu / thay doi API, UX. Phuong an loai bo (1 dong).>

## Acceptance criteria / Tieu chi chap nhan
- AC-1: Given ..., when ..., then ...
- AC-2: ...

## Areas of concern (flagged) / Diem can luu y
<Where policies conflict or risk is high; who owns the decision.>
<Noi chinh sach mau thuan hoac rui ro cao; ai quyet dinh.>

## Out of scope / Ngoai pham vi
- ...
'@

Write-File 'plans/_TEMPLATE.md' @'
# Plan: <title>   (from specs/<file>.md)

## Files that change / File se doi
<path (new/edit) - one line reason>

## Order of work / Thu tu lam
1. ...
2. ...

## Tasks / Cong viec
| ID | Task | Files | Depends on | Parallel |
|----|------|-------|------------|----------|
| T1 | ...  | src/... | - | yes |

## Risks / Rui ro
<e.g. rate limits, migrations, breaking changes.>

## Proof / Bang chung
<Which tests / screenshots prove each acceptance criterion.>

## Pipeline log
| Phase | Result | Notes |
|-------|--------|-------|
'@

# ---- docs --------------------------------------------------------------------
Write-File 'docs/AI-SDLC.md' @'
# AI-Native SDLC - how this repo works / Cach repo nay van hanh

The process is a LOOP, not a line. Each stage commits an artifact the next stage reads.
Quy trinh la VONG LAP. Moi giai doan commit 1 artifact cho giai doan sau doc.

1. Plan     -> intent/*.md   (what & why)                 skill: /intent
2. Design   -> specs/*.md    (requirements + design)      skill: /spec
3. Build    -> plans/*.md + code (plan mode first)        skill: /feature
4. Test     -> tests + evals/* (agent verifies itself)    agents: tester, verifier
5. Deploy   -> PR + REVIEW.md findings (human approves)   agent: reviewer + CI
6. Maintain -> docs/incidents/* + monitoring/bands.yaml   (loop restarts as intent)

## Roles / Vai tro
- planner  : writes plans, never edits code.
- coder    : implements the approved plan, fixes failures.
- tester   : writes/runs tests from acceptance criteria, only edits test files.
- reviewer : read-only review against REVIEW.md + the plan.
- verifier : runs the app in a fresh context to confirm behaviour.

## Guardrails / Hang rao (see .claude/)
- guard-bash.sh    : blocks destructive commands (rm -rf outside repo, push, sudo...).
- format.sh        : auto-formats edited files.
- protect-tests.sh : blocks edits to test files during a fix task (set FIX_MODE=1).
- production-gate.sh: pauses production deploys until a named approval.

## Human stays above the loop / Nguoi o tren vong lap
Approve the plan (GATE 1) and the commit (GATE 2). Nothing pushes automatically.
'@

Write-File 'docs/adr/0001-record-architecture-decisions.md' @'
# 1. Record architecture decisions / Ghi lai quyet dinh kien truc

Date: <YYYY-MM-DD>
Status: accepted

## Context / Boi canh
We need a lightweight, versioned record of significant technical decisions.
Can mot cach ghi lai quyet dinh ky thuat quan trong, nhe, co version.

## Decision / Quyet dinh
Use Architecture Decision Records (ADRs), one Markdown file per decision, in docs/adr/.

## Consequences / He qua
Decisions are reviewable in PRs and become part of the audit trail.
Quyet dinh duoc review trong PR va tro thanh mot phan cua audit trail.
'@

Write-File 'docs/runbooks/rollback-deploy.md' @'
# Runbook: rollback a deploy / Hoan tac trien khai

> EN: Rollback must be the most rehearsed path. Practise it in staging.
> VI: Rollback phai la duong duoc dien tap nhieu nhat. Tap o staging.

## Trigger / Khi nao
Post-deploy error rate breaches the band in monitoring/bands.yaml.

## Steps / Cac buoc
1. <single command to roll back / mot lenh de hoan tac>
2. Verify metric back to baseline / kiem tra metric ve muc nen.
3. Record in docs/incidents/ / ghi vao docs/incidents/.
'@

Write-File 'docs/incidents/_TEMPLATE.md' @'
# Incident: <title>
Date: <YYYY-MM-DD>. Severity: <sev>. Owner: <name>.

## What happened / Chuyen gi xay ra
## Detection / Phat hien the nao (which band / alert)
## Impact / Anh huong
## Fix / Cach xu ly
## Follow-up / Viec tiep theo
- [ ] Add an eval for this incident class (evals/) / Them eval cho lop su co nay.
- [ ] Update CLAUDE.md if a recurring mistake / Cap nhat CLAUDE.md neu loi lap lai.
'@

# ---- 4) Test stage: evals ----------------------------------------------------
Write-File 'evals/example.json' @'
{
  "name": "example-endpoint-returns-200",
  "prompt": "Ensure GET /health returns 200 and the tests in tests/ pass.",
  "checks": ["tests pass", "lint clean"]
}
'@

Write-File 'evals/check.sh' @'
#!/usr/bin/env bash
# EN: Grade one eval result. Replace with real assertions for your stack.
# VI: Cham 1 ket qua eval. Thay bang assertion that theo stack cua ban.
set -euo pipefail
eval_file="${1:?usage: check.sh <eval.json> <result.json>}"
result_file="${2:?usage: check.sh <eval.json> <result.json>}"
echo "Checking $(basename "$eval_file") against $(basename "$result_file")"
# TODO: parse result_file and assert the checks in eval_file.
exit 0
'@

# ---- 5) Maintain stage: monitoring ------------------------------------------
Write-File 'monitoring/bands.yaml' @'
# EN: Deterministic monitoring. A breached band invokes Claude; the tier sets
#     what it may do. No model is involved in detection itself.
# VI: Giam sat tat dinh. Vuot band se goi Claude; muc do quyet dinh Claude
#     duoc lam gi. Ban than viec phat hien khong dung model.
metric: ci_test_failure_rate
baseline: rolling_30d
rules: western_electric
tiers:
  1sigma: { action: log }
  2sigma: { action: diagnose, tools: "Read,Grep,Bash(gh run view *)" }
  3sigma: { action: propose, routes: [pull_request, "runbook:rollback-deploy"] }
'@

# ---- 6) .claude/ agents ------------------------------------------------------
Write-File '.claude/agents/planner.md' @'
---
name: planner
description: Tech lead. Turns a spec/intent into a testable plan in plans/. Use before any non-trivial change. Never edits source code.
tools: Read, Grep, Glob, Write, WebFetch, WebSearch
model: opus
effort: high
color: blue
memory: project
---
You are the tech lead / planner. You NEVER modify source or tests.
Only files you may write: plans/*.md and your own agent memory.

## Process
1. Check your memory for repo patterns and pitfalls.
2. Read CLAUDE.md and the given specs/*.md (or intent/*.md).
3. Explore the code the change touches; find patterns and tests to reuse.
4. List ambiguities under "Open questions", each with a recommended default.
   Never guess on behaviour, data model, public API, security or UX copy.
5. Write/update plans/<slug>.md from plans/_TEMPLATE.md.
6. Save codebase learnings to memory.

## Final message (parsed by the orchestrator - keep exact)
PLAN_PATH: plans/<slug>.md
STATUS: READY | NEEDS_ANSWERS
OPEN_QUESTIONS:
1. <question> - recommended default: <answer>
SUMMARY: <max 5 lines>
'@

Write-File '.claude/agents/coder.md' @'
---
name: coder
description: Implements tasks from an APPROVED plan in plans/, and fixes failures from the tester or reviewer. Use for all production-code changes once a plan is approved.
tools: Read, Edit, Write, Bash, Grep, Glob
model: inherit
color: green
memory: project
---
You are a senior engineer. Implement exactly what the approved plan says.

## Rules
1. Read the whole plan and CLAUDE.md first. Check your memory.
2. Implement only your assigned tasks. No scope creep or drive-by refactors.
3. Reuse existing patterns and error-handling. Match surrounding code.
4. If the plan is wrong or ambiguous about behaviour: STOP, return STATUS: BLOCKED
   with the exact question. Do not invent product decisions.
5. Fixing tests: fix the root cause in production code. NEVER delete, skip or
   weaken a test. If a test itself is wrong, return BLOCKED and explain.
6. Run build / typecheck / lint / tests (commands in CLAUDE.md). All green.
7. Do NOT commit, push, or switch branches. The orchestrator handles git.
8. Record non-obvious repo knowledge in memory.

## Final message (keep format)
STATUS: DONE | BLOCKED
TASKS: <ids>
FILES_CHANGED:
- path - reason
CHECKS:
- <command> -> pass/fail
NOTES: <deviations / follow-ups / blocking question>
'@

Write-File '.claude/agents/tester.md' @'
---
name: tester
description: QA engineer. Writes and runs tests that prove the acceptance criteria, then reports PASS/FAIL with evidence. Use after the coder finishes and after every fix.
tools: Read, Write, Edit, Bash, Grep, Glob
color: yellow
---
You find out whether the feature really works - not to make it look like it does.

## Rules
1. Derive tests from the ACCEPTANCE CRITERIA (in specs/plans), black-box:
   happy path, edge cases, invalid input, permissions, empty/large data.
2. You may ONLY create/edit test files and fixtures. NEVER touch production code;
   if it is wrong, report it as a failure.
3. Follow the existing framework, layout and naming. Reuse fixtures/helpers.
4. Run new tests AND the relevant existing suite (commands in CLAUDE.md).
5. For UI/user-facing changes, smoke-test the running app if a run/verify skill exists.
6. Classify failures: PRODUCT_BUG, TEST_BUG (fix it), ENV/FLAKY (re-run once).

## Final message (keep format)
VERDICT: PASS | FAIL
COVERAGE:
| AC | Test (file::name) | Result |
FAILURES:
- [PRODUCT_BUG] file:line - expected ... / actual ... - repro: <cmd> - cause: ...
COMMANDS:
- <command> -> <summary>
'@

Write-File '.claude/agents/reviewer.md' @'
---
name: reviewer
description: Senior code reviewer. Reviews the branch diff against the plan and REVIEW.md. Read-only. Use after tests pass and before anything is committed.
tools: Read, Grep, Glob, Bash
model: opus
effort: high
color: purple
memory: project
---
Strict but pragmatic. You do NOT edit code (only your own memory).
Bash is for read-only commands: git diff/log/status/show, linters, test runs.

## Process
1. Check memory for recurring issues.
2. Read REVIEW.md, the plan, then git diff <base>...HEAD plus uncommitted changes.
3. Review per REVIEW.md passes: Bugs, Security, Compliance (matches spec + plan).
   Also: error handling, migrations/back-compat, performance, conventions, dead code,
   and test quality (were any tests weakened, skipped or deleted?).
4. Skip formatting nits - the formatter hook handles those.
5. Save recurring patterns to memory.

## Severity
- BLOCKER: bug, security hole, data loss, AC not met -> must fix
- MAJOR: likely bug / maintainability problem -> must fix
- MINOR / NIT: optional, never blocks

## Final message (keep format)
VERDICT: APPROVE | REQUEST_CHANGES   (REQUEST_CHANGES only if a BLOCKER/MAJOR exists)
FINDINGS:
- [BLOCKER] path:line - problem - why it matters - suggested fix
SUMMARY: <max 5 lines>
'@

Write-File '.claude/agents/verifier.md' @'
---
name: verifier
description: Runs the app in a fresh context and checks the change works before the session reports done. Read + run only; never fixes anything.
tools: Bash, Read
color: cyan
---
Start the app using the project's run command (see CLAUDE.md). Exercise the
changed behaviour and the two nearest neighbouring flows. Report what you ran,
what you saw, and any behaviour that does not match the plan. Do not fix
anything; report only.

## Final message
RESULT: OK | MISMATCH
OBSERVED:
- <what you ran> -> <what you saw>
MISMATCHES:
- <expected vs actual, referencing the plan>
'@

# ---- skills ------------------------------------------------------------------
Write-File '.claude/skills/feature/SKILL.md' @'
---
name: feature
description: Run the full plan -> code -> test -> review pipeline for one change using the planner, coder, tester, reviewer (and verifier) subagents, with two human gates.
argument-hint: "[specs/<file>.md | intent/<file>.md | free text]"
disable-model-invocation: true
---
# Feature pipeline

You are the ORCHESTRATOR. You do not write production code or tests yourself:
delegate to subagents, check their structured output, advance the phases.
Talk to the user in the language they use.

Request: $ARGUMENTS

## Ground rules
- Subagents start EMPTY. Every delegation must include the artifact path (spec/plan),
  the task IDs or goal, and any failures/findings verbatim. Never say "see above".
- Wait for each subagent's result before the next phase (except parallel coding).
- After each phase append one row to the plan's "Pipeline log".
- Never push, merge, deploy, or rewrite git history.

## Phase 1 - Plan
Delegate to planner with the artifact. If STATUS: NEEDS_ANSWERS, ask the user
with AskUserQuestion (planner's default first), send answers back. Max 3 rounds.

## GATE 1 - Human approves the plan (REQUIRED)
Show plan path, acceptance criteria, tasks, risks. Ask Approve / Request changes / Cancel.
Do not continue without "Approve". On changes -> planner -> repeat.

## Phase 2 - Implement
If the tree is dirty, ask the user. Else: git switch -c feat/<slug>.
Delegate to coder in dependency order. Parallel tasks with disjoint files may
go to separate coders. BLOCKED -> ask user, or send back to planner + GATE 1.

## Phase 3 - Test loop (max 3 rounds)
Delegate to tester. PASS -> Phase 4. FAIL -> send PRODUCT_BUG failures to coder,
run tester again. After 3 fails: stop and ask the user.

## Phase 4 - Review loop (max 2 rounds)
Delegate to reviewer with the plan + base branch. APPROVE -> Phase 5.
REQUEST_CHANGES -> BLOCKER/MAJOR to coder -> tester (regression) -> reviewer.
(Optional: run verifier for user-facing changes.) After 2 rounds unresolved: escalate.

## Phase 5 - Wrap up + GATE 2 (REQUIRED)
Report files changed, AC status table, test commands + results, review verdict,
leftover nits, and a ready-to-paste PR description.
Ask Commit / Request changes / Stop. On Commit: commit locally on the feature branch
with a conventional message referencing the plan file. Do NOT push.
'@

Write-File '.claude/skills/intent/SKILL.md' @'
---
name: intent
description: Capture an idea as a version-controlled intent.md (Stage 1 Plan). Use when someone has an idea, ticket, or incident to turn into an actionable artifact.
argument-hint: "[free text idea]"
disable-model-invocation: true
---
# Capture intent

Idea: $ARGUMENTS

1. Brainstorm with the user until the idea is concrete. Ask what an analyst would:
   scope, users, constraints, what success looks like, what is out of scope.
2. Write the result to intent/<slug>.md using intent/_TEMPLATE.md.
3. Let the user correct anything you misunderstood.
4. Summarize and tell them the next step is /spec intent/<slug>.md.

Do not start design or code here. This stage only produces intent.md.
'@

Write-File '.claude/skills/spec/SKILL.md' @'
---
name: spec
description: Turn an approved intent.md into a requirements + design spec.md (Stage 2 Design), applying the repo's policy skills. Use after an intent is accepted.
argument-hint: "[intent/<file>.md]"
disable-model-invocation: true
---
# Requirements & design

Read the attached intent file: $ARGUMENTS

1. Load any policy skills available (security, brand, UX, compliance).
2. Produce a requirements + design spec that the engineering team can plan against.
3. Clearly flag areas of concern, especially where policies conflict.
4. Write it to specs/<slug>.md using specs/_TEMPLATE.md, alongside the intent.
5. Summarize and tell the user the next step is /feature specs/<slug>.md.

Do not write code here. This stage only produces spec.md.
'@

Write-File '.claude/skills/secure-api-review/SKILL.md' @'
---
name: secure-api-review
description: Apply the API security standard. Use whenever creating or modifying an external-facing endpoint, reviewing API code, or generating an OpenAPI spec.
---
# Secure API review

When you create or change an API endpoint:
1. Authentication: every endpoint requires the gateway token; no anonymous routes
   outside /health.
2. Input validation: validate bodies against the schema; reject unknown fields.
3. Audit: every state-changing endpoint emits an audit event (actor, action,
   entity, timestamp).
4. Data classification: fields tagged PII must never appear in logs or errors.

<!-- EN: This is an example policy skill. Replace with your real standard. -->
<!-- VI: Day la skill mau. Thay bang chuan that cua ban. -->
'@

# ---- hooks -------------------------------------------------------------------
Write-File '.claude/hooks/guard-bash.sh' @'
#!/usr/bin/env bash
# PreToolUse (matcher: Bash). Blocks destructive commands for the main session
# and every subagent. Exit 2 = block; stderr is sent back to Claude.
INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
[ -z "$CMD" ] && exit 0
block(){ echo "Blocked by guard-bash.sh: $1. If truly needed, ask the user to run it manually." >&2; exit 2; }
S='[[:space:]]'
chk(){ printf '%s' "$CMD" | grep -Eiq -- "$1"; }
chk "rm${S}+-[a-z]*r[a-z]*${S}+(/|~|\\\$HOME|\.\.)" && block "recursive delete outside the project"
chk "git${S}+reset${S}+--hard"                        && block "git reset --hard discards work"
chk "git${S}+clean${S}+-[a-z]*f"                       && block "git clean deletes untracked files"
chk "git${S}+(checkout|restore)${S}+(--${S}+)?\.(${S}|$)" && block "discarding all local changes"
chk "git${S}+branch${S}+-D"                            && block "force-deleting a branch"
chk "git${S}+push"                                     && block "pushing is done by a human"
chk "(drop|truncate)${S}+(table|database|schema)"      && block "destructive SQL"
chk "(curl|wget)[^|]*\|${S}*(sudo${S}+)?(ba|z)?sh"     && block "piping a download into a shell"
chk "(^|[;&|]${S}*)sudo${S}"                           && block "sudo"
chk "chmod${S}+-R${S}+777"                             && block "chmod -R 777"
exit 0
'@

Write-File '.claude/hooks/format.sh' @'
#!/usr/bin/env bash
# PostToolUse (matcher: Edit|Write). Auto-formats the changed file. Never blocks.
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
{ [ -z "$FILE" ] || [ ! -f "$FILE" ]; } && exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.html|*.vue|*.svelte|*.yml|*.yaml)
    [ -x node_modules/.bin/prettier ] && node_modules/.bin/prettier --write "$FILE" >/dev/null 2>&1 ;;
  *.py)
    command -v ruff >/dev/null 2>&1 && { ruff format "$FILE" >/dev/null 2>&1; ruff check --fix "$FILE" >/dev/null 2>&1; } ;;
  *.go)  command -v gofmt   >/dev/null 2>&1 && gofmt -w "$FILE" >/dev/null 2>&1 ;;
  *.rs)  command -v rustfmt >/dev/null 2>&1 && rustfmt "$FILE" >/dev/null 2>&1 ;;
esac
exit 0
'@

Write-File '.claude/hooks/protect-tests.sh' @'
#!/usr/bin/env bash
# PreToolUse (matcher: Edit|Write). Guards the feedback loop: an agent fixing a
# bug must not weaken the test that proves it. Set FIX_MODE=1 in the environment
# during a fix task to activate. Exit 2 = block.
[ "${FIX_MODE:-0}" = "1" ] || exit 0
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
[ -z "$FILE" ] && exit 0
case "$FILE" in
  *test*|*spec*|*/tests/*|*/__tests__/*)
    echo "Blocked by protect-tests.sh: cannot edit test files during a fix task. Fix the code instead." >&2
    exit 2 ;;
esac
exit 0
'@

Write-File '.claude/hooks/production-gate.sh' @'
#!/usr/bin/env bash
# PreToolUse (matcher: Bash). Production deploys require a named authorization.
# Exit 2 = block; the message goes to Claude.
CMD="$(jq -r '.tool_input.command // empty' < /dev/stdin)"
if printf '%s' "$CMD" | grep -Eiq 'deploy' && printf '%s' "$CMD" | grep -Eiq 'prod'; then
  if [ -z "${RELEASE_APPROVAL:-}" ]; then
    echo "Production deploy needs a release authorization (set RELEASE_APPROVAL)." >&2
    exit 2
  fi
fi
exit 0
'@

# ---- settings.json -----------------------------------------------------------
Write-File '.claude/settings.json' @'
{
  "permissions": {
    "allow": [
      "Bash(git status)", "Bash(git status *)", "Bash(git diff *)",
      "Bash(git log *)", "Bash(git show *)", "Bash(git switch -c *)",
      "Bash(git add *)",
      "Bash(npm test *)", "Bash(npm run test *)", "Bash(npm run lint *)",
      "Bash(npm run build *)", "Bash(npm run typecheck *)",
      "Bash(pytest *)", "Bash(ruff *)",
      "Bash(go test *)", "Bash(go vet *)",
      "Bash(make build)", "Bash(make test)", "Bash(make lint)"
    ],
    "deny": [
      "Bash(git push *)",
      "Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)",
      "Edit(./.claude/settings.json)", "Edit(./.claude/hooks/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/guard-bash.sh" },
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/production-gate.sh" }
        ] },
      { "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-tests.sh" }
        ] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/format.sh" }
        ] }
    ]
  }
}
'@

# ---- 7) CI workflows ---------------------------------------------------------
Write-File '.github/workflows/agent-evals.yml' @'
name: Agent evals
# EN: Regression-test the config that steers the agent (CLAUDE.md, .claude/**).
# VI: Regression-test cau hinh dieu khien agent (CLAUDE.md, .claude/**).
on:
  pull_request:
    paths: ['CLAUDE.md', '.claude/**', 'evals/**']
  schedule:
    - cron: '0 2 * * *'
jobs:
  evals:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g @anthropic-ai/claude-code
      - name: Run eval suite
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          for eval in evals/*.json; do
            [ "$(basename "$eval")" = "example.json" ] && continue
            claude -p "$(jq -r '.prompt' "$eval")" \
              --allowedTools "Read,Edit,Bash(make test)" \
              --output-format json > result.json
            ./evals/check.sh "$eval" result.json
          done
'@

Write-File '.github/workflows/claude-review.yml' @'
name: Claude PR review
# EN: Uses claude-code-action to review PRs against REVIEW.md. Add ANTHROPIC_API_KEY
#     to repo secrets. For untrusted forks, review the action's security guidance.
# VI: Dung claude-code-action de review PR theo REVIEW.md. Them ANTHROPIC_API_KEY
#     vao secrets. Voi PR tu fork la, doc huong dan bao mat cua action.
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "Review this PR following REVIEW.md. Post findings tagged by severity."
'@

# ---- 8) Version pinning ------------------------------------------------------
$toolVersions = @()

if ($Node) {
  if ($Node -eq "latest") { Write-File '.nvmrc' "node`n" } else { Write-File '.nvmrc' "$Node`n" }
  if ((-not (Test-Path 'package.json')) -or $Force) {
    $engine = $Node; if ($Node -eq "latest") { $engine = ">=20" }
    $pkg = @'
{
  "name": "__NAME__",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": { "node": "__ENGINE__" },
  "scripts": {
    "build": "echo \"TODO build\"",
    "test": "echo \"TODO test\" && exit 0",
    "lint": "echo \"TODO lint\""
  }
}
'@ -replace '__NAME__', $Name -replace '__ENGINE__', $engine
    Write-File 'package.json' $pkg
  } else { Skip 'package.json' }
  $toolVersions += "nodejs $Node"
}

if ($Python) {
  Write-File '.python-version' "$Python`n"
  if ((-not (Test-Path 'pyproject.toml')) -or $Force) {
    $req = if ($Python -eq "latest") { ">=3.11" } else { ">=$Python" }
    $py = @'
[project]
name = "__NAME__"
version = "0.1.0"
requires-python = "__REQ__"

[tool.ruff]
line-length = 100
'@ -replace '__NAME__', $Name -replace '__REQ__', $req
    Write-File 'pyproject.toml' $py
  } else { Skip 'pyproject.toml' }
  $toolVersions += "python $Python"
}

if ($Go) {
  if ((-not (Test-Path 'go.mod')) -or $Force) {
    $gv = if ($Go -eq "latest") { "1.22" } else { $Go }
    $gomod = @'
module __NAME__

go __GV__
'@ -replace '__NAME__', $Name -replace '__GV__', $gv
    Write-File 'go.mod' $gomod
  } else { Skip 'go.mod' }
  $toolVersions += "golang $Go"
}

if ($Java) { $toolVersions += "java $Java" }

if ($toolVersions.Count -gt 0) {
  if ((-not (Test-Path '.tool-versions')) -or $Force) {
    Write-File '.tool-versions' (($toolVersions -join "`n") + "`n")
  } else { Skip '.tool-versions' }
}

# ---- 9) git init -------------------------------------------------------------
if (-not $NoGit) {
  if (-not (Test-Path '.git')) {
    if (Get-Command git -ErrorAction SilentlyContinue) {
      git init -q; Ok "git init"
    } else { Warn "git not found - skipping / khong co git - bo qua" }
  } else { Skip "git (already a repo / da la repo)" }
}

# ---- Done --------------------------------------------------------------------
Write-Host ""
Ok "AI-Native SDLC scaffold ready in $((Get-Location).Path)"
Ok "Khung AI-Native SDLC da san sang trong $((Get-Location).Path)"
Write-Host ""
Info "Next / Tiep theo:"
Write-Host "  1. Edit CLAUDE.md - fill in Commands/Conventions. / Sua CLAUDE.md."
if ($toolVersions.Count -gt 0) { Write-Host "  2. Install runtimes: 'mise install' or use nvm/asdf. / Cai runtime." }
Write-Host "  3. Open Claude Code here, then run: /intent <your idea>"
Write-Host "  4. Read docs/AI-SDLC.md for the full loop. / Doc docs/AI-SDLC.md."
