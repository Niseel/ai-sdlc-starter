#!/usr/bin/env bash
# =============================================================================
# init.sh   (init-ai-sdlc v0.1.0)
# EN: Scaffolds an AI-Native SDLC project (Anthropic 6-stage playbook:
#     Plan -> Design -> Build -> Test -> Deploy -> Maintain).
# VI: Tao khung du an theo AI-Native SDLC cua Anthropic (6 giai doan:
#     Plan -> Design -> Build -> Test -> Deploy -> Maintain).
#
# Usage / Cach dung:
#   ./init.sh [NAME] [-w LIST] [-d PATH] [-f] [--no-git] [--help]
#
# Examples / Vi du:
#   ./init.sh my-app -w node,python@3.12
#   ./init.sh svc -w go@1.22 -d ./svc
# =============================================================================
set -euo pipefail

VERSION="0.1.0"
NAME=""
DIR="."
NODE_VER=""
PY_VER=""
GO_VER=""
JAVA_VER=""
FORCE=0
DO_GIT=1

# ---- Bilingual print helpers / Ham in song ngu ------------------------------
if [ -t 1 ]; then
  c_reset=$'\033[0m'; c_ok=$'\033[32m'; c_info=$'\033[36m'; c_warn=$'\033[33m'; c_skip=$'\033[90m'
else
  c_reset=""; c_ok=""; c_info=""; c_warn=""; c_skip=""
fi
msg()  { printf '%s\n' "$*"; }
ok()   { printf '%s[ok]%s   %s\n'   "$c_ok"   "$c_reset" "$*"; }
info() { printf '%s[info]%s %s\n'   "$c_info" "$c_reset" "$*"; }
warn() { printf '%s[warn]%s %s\n'   "$c_warn" "$c_reset" "$*"; }
skip() { printf '%s[skip]%s %s\n'   "$c_skip" "$c_reset" "$*"; }

usage() {
  cat <<'USAGE'
init-ai-sdlc  -  AI-Native SDLC project scaffolder

EN  Options:
VI  Tuy chon:
Usage / Cach dung:
  init.sh [NAME] [-w LIST] [options]

  NAME             EN: project name (default: current folder)  VI: ten du an
  -w, --with LIST  EN: runtimes, comma separated                VI: runtime, cach nhau dau phay
                       node,python@3.12,go@1.22,java@21
  -n, --name NAME  EN: project name, same as NAME              VI: nhu NAME
  -d, --dir PATH   EN: target directory (default: .)           VI: thu muc dich
  --node VER       EN: pin Node version (e.g. latest, 22, 20)  VI: ghim ban Node
  --python VER     EN: pin Python version (e.g. 3.12, 3.10)    VI: ghim ban Python
  --go VER         EN: pin Go version (e.g. 1.22)              VI: ghim ban Go
  --java VER       EN: pin Java version (e.g. 21)              VI: ghim ban Java
  -f, --force      EN: overwrite existing files                VI: ghi de file da co
  --no-git         EN: do not run 'git init'                   VI: khong chay git init
  -h, --help       EN: show this help                          VI: hien tro giup

Examples / Vi du:
  init.sh my-app -w node,python@3.12
  init.sh -n svc -w go@1.22 -d ./svc

NOTE / LUU Y:
  EN: This script only PINS versions (writes .nvmrc/.python-version/.tool-versions
      and manifests). It does NOT download runtimes. Use nvm/mise/asdf to install.
  VI: Script CHI GHIM phien ban (tao .nvmrc/.python-version/.tool-versions va
      manifest). KHONG tai runtime ve. Dung nvm/mise/asdf de cai dat.
USAGE
}

# ---- Runtime list: -w node,python@3.12 / Danh sach runtime -------------------
# EN: "name" alone uses the default version below; "name@ver" pins that version.
# VI: Chi "ten" thi dung ban mac dinh ben duoi; "ten@ban" thi ghim dung ban do.
parse_with() {
  local item name ver
  local IFS=','
  for item in $1; do
    [ -z "$item" ] && continue
    name="${item%%@*}"
    ver=""
    case "$item" in *@*) ver="${item#*@}" ;; esac
    case "$name" in
      node|nodejs|js|ts) NODE_VER="${ver:-latest}" ;;
      python|py)         PY_VER="${ver:-3.12}" ;;
      go|golang)         GO_VER="${ver:-1.22}" ;;
      java|jvm|kotlin)   JAVA_VER="${ver:-21}" ;;
      *) warn "Unknown runtime / Runtime la: $name"; usage; exit 1 ;;
    esac
  done
}

# ---- Parse args / Doc doi so ------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--name)   NAME="${2:-}"; shift 2 ;;
    -d|--dir)    DIR="${2:-}"; shift 2 ;;
    -w|--with)   parse_with "${2:-}"; shift 2 ;;
    --node)      NODE_VER="${2:-}"; shift 2 ;;
    --python)    PY_VER="${2:-}"; shift 2 ;;
    --go)        GO_VER="${2:-}"; shift 2 ;;
    --java)      JAVA_VER="${2:-}"; shift 2 ;;
    -f|--force)  FORCE=1; shift ;;
    --no-git)    DO_GIT=0; shift ;;
    --version)   echo "init-ai-sdlc $VERSION"; exit 0 ;;
    -h|--help)   usage; exit 0 ;;
    -*) warn "Unknown option / Tuy chon la: $1"; usage; exit 1 ;;
    *) if [ -z "$NAME" ]; then NAME="$1"; shift
       else warn "Unexpected argument / Doi so la: $1"; usage; exit 1; fi ;;
  esac
done

mkdir -p "$DIR"
cd "$DIR"
[ -z "$NAME" ] && NAME="$(basename "$(pwd)")"

info "init-ai-sdlc $VERSION"
info "Project / Du an: $NAME"
info "Target  / Thu muc: $(pwd)"
[ -n "$NODE_VER" ] && info "Node:   $NODE_VER"
[ -n "$PY_VER" ]   && info "Python: $PY_VER"
[ -n "$GO_VER" ]   && info "Go:     $GO_VER"
[ -n "$JAVA_VER" ] && info "Java:   $JAVA_VER"

# ---- File writer: skips existing unless --force / Ham ghi file ---------------
# Usage: wf path/to/file <<'EOF' ... EOF
wf() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  if [ -e "$path" ] && [ "$FORCE" -ne 1 ]; then
    skip "$path"
    cat >/dev/null   # consume heredoc
    return 0
  fi
  cat >"$path"
  ok "$path"
}
mkd() { mkdir -p "$1"; [ -e "$1/.gitkeep" ] || : >"$1/.gitkeep"; }

# =============================================================================
# 1) Directories / Thu muc
# =============================================================================
for d in intent specs plans docs/adr docs/runbooks docs/incidents \
         evals monitoring src tests scripts \
         .claude/agents .claude/skills .claude/hooks .github/workflows; do
  mkdir -p "$d"
done
mkd src; mkd tests; mkd scripts

# =============================================================================
# 2) Root files / File goc
# =============================================================================
wf README.md <<EOF
# $NAME

> AI-Native SDLC project (Anthropic 6-stage playbook).
> Du an theo AI-Native SDLC cua Anthropic (6 giai doan).

## The loop / Vong lap
Plan -> Design -> Build -> Test -> Deploy -> Maintain, and back.
Each stage commits one version-controlled artifact that the next stage reads:
Moi giai doan commit mot artifact vao git de giai doan sau doc:

| Stage | Artifact | Folder |
|-------|----------|--------|
| Plan | \`intent.md\` | \`intent/\` |
| Design | \`spec.md\` | \`specs/\` |
| Build | \`plan.md\` + code | \`plans/\`, \`src/\` |
| Test | tests + evals | \`tests/\`, \`evals/\` |
| Deploy | PR + review findings | \`REVIEW.md\`, \`.github/\` |
| Maintain | incident record | \`docs/incidents/\`, \`monitoring/\` |

## Quick start / Bat dau nhanh
1. \`claude\` in this repo. It reads \`CLAUDE.md\` automatically.
2. Capture an idea:  \`/intent <your idea>\`  -> writes \`intent/*.md\`.
3. Turn it into a spec: \`/spec intent/<file>.md\` -> writes \`specs/*.md\`.
4. Build it end-to-end: \`/feature specs/<file>.md\` (plan -> code -> test -> review).

## Human gates / Cong duyet cua nguoi
- GATE 1: approve the plan / duyet plan.
- GATE 2: approve the commit / duyet commit. Nothing is pushed automatically.

See \`docs/AI-SDLC.md\` for the full guide. Xem huong dan day du o \`docs/AI-SDLC.md\`.
EOF

wf .gitignore <<'EOF'
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
EOF

wf .env.example <<'EOF'
# EN: Copy to .env and fill in. Never commit the real .env.
# VI: Copy thanh .env va dien. Khong bao gio commit .env that.
APP_ENV=development
# ANTHROPIC_API_KEY=   # only needed for CI evals / chi can cho CI evals
EOF

wf .editorconfig <<'EOF'
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
EOF

# ---- REVIEW.md (Deploy stage policy) ----------------------------------------
wf REVIEW.md <<'EOF'
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
EOF

# ---- CLAUDE.md (Build stage: agent day-one context) -------------------------
wf CLAUDE.md <<EOF
# $NAME

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
EOF

# =============================================================================
# 3) Stage artifacts: templates + examples
# =============================================================================
wf intent/_TEMPLATE.md <<'EOF'
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
EOF

wf intent/EXAMPLE-claims-status.md <<'EOF'
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
EOF

wf specs/_TEMPLATE.md <<'EOF'
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
EOF

wf plans/_TEMPLATE.md <<'EOF'
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
EOF

# ---- docs / guide + ADR + runbook + incident --------------------------------
wf docs/AI-SDLC.md <<'EOF'
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
EOF

wf docs/adr/0001-record-architecture-decisions.md <<'EOF'
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
EOF

wf docs/runbooks/rollback-deploy.md <<'EOF'
# Runbook: rollback a deploy / Hoan tac trien khai

> EN: Rollback must be the most rehearsed path. Practise it in staging.
> VI: Rollback phai la duong duoc dien tap nhieu nhat. Tap o staging.

## Trigger / Khi nao
Post-deploy error rate breaches the band in monitoring/bands.yaml.

## Steps / Cac buoc
1. <single command to roll back / mot lenh de hoan tac>
2. Verify metric back to baseline / kiem tra metric ve muc nen.
3. Record in docs/incidents/ / ghi vao docs/incidents/.
EOF

wf docs/incidents/_TEMPLATE.md <<'EOF'
# Incident: <title>
Date: <YYYY-MM-DD>. Severity: <sev>. Owner: <name>.

## What happened / Chuyen gi xay ra
## Detection / Phat hien the nao (which band / alert)
## Impact / Anh huong
## Fix / Cach xu ly
## Follow-up / Viec tiep theo
- [ ] Add an eval for this incident class (evals/) / Them eval cho lop su co nay.
- [ ] Update CLAUDE.md if a recurring mistake / Cap nhat CLAUDE.md neu loi lap lai.
EOF

# =============================================================================
# 4) Test stage: evals
# =============================================================================
wf evals/example.json <<'EOF'
{
  "name": "example-endpoint-returns-200",
  "prompt": "Ensure GET /health returns 200 and the tests in tests/ pass.",
  "checks": ["tests pass", "lint clean"]
}
EOF

wf evals/check.sh <<'EOF'
#!/usr/bin/env bash
# EN: Grade one eval result. Replace with real assertions for your stack.
# VI: Cham 1 ket qua eval. Thay bang assertion that theo stack cua ban.
set -euo pipefail
eval_file="${1:?usage: check.sh <eval.json> <result.json>}"
result_file="${2:?usage: check.sh <eval.json> <result.json>}"
echo "Checking $(basename "$eval_file") against $(basename "$result_file")"
# TODO: parse result_file and assert the checks in eval_file.
exit 0
EOF
chmod +x evals/check.sh 2>/dev/null || true

# =============================================================================
# 5) Maintain stage: monitoring bands
# =============================================================================
wf monitoring/bands.yaml <<'EOF'
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
EOF

# =============================================================================
# 6) .claude/ - agents, skills, hooks, settings
# =============================================================================

# ---- Agents ----
wf .claude/agents/planner.md <<'EOF'
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
EOF

wf .claude/agents/coder.md <<'EOF'
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
EOF

wf .claude/agents/tester.md <<'EOF'
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
EOF

wf .claude/agents/reviewer.md <<'EOF'
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
EOF

wf .claude/agents/verifier.md <<'EOF'
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
EOF

# ---- Skills ----
wf .claude/skills/feature/SKILL.md <<'EOF'
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
EOF

wf .claude/skills/intent/SKILL.md <<'EOF'
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
EOF

wf .claude/skills/spec/SKILL.md <<'EOF'
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
EOF

wf .claude/skills/secure-api-review/SKILL.md <<'EOF'
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
EOF

# ---- Hooks ----
wf .claude/hooks/guard-bash.sh <<'EOF'
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
EOF
chmod +x .claude/hooks/guard-bash.sh 2>/dev/null || true

wf .claude/hooks/format.sh <<'EOF'
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
EOF
chmod +x .claude/hooks/format.sh 2>/dev/null || true

wf .claude/hooks/protect-tests.sh <<'EOF'
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
EOF
chmod +x .claude/hooks/protect-tests.sh 2>/dev/null || true

wf .claude/hooks/production-gate.sh <<'EOF'
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
EOF
chmod +x .claude/hooks/production-gate.sh 2>/dev/null || true

# ---- settings.json ----
wf .claude/settings.json <<'EOF'
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
EOF

# =============================================================================
# 7) CI workflows / Luong CI
# =============================================================================
wf .github/workflows/agent-evals.yml <<'EOF'
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
EOF

wf .github/workflows/claude-review.yml <<'EOF'
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
EOF

# =============================================================================
# 8) Version pinning / Ghim phien ban  (writes version files + manifests only)
# =============================================================================
tool_versions=""
add_tv(){ tool_versions="${tool_versions}$1\n"; }

if [ -n "$NODE_VER" ]; then
  if [ "$NODE_VER" = "latest" ]; then echo "node" > .nvmrc; else echo "$NODE_VER" > .nvmrc; fi
  ok ".nvmrc"
  if [ ! -e package.json ] || [ "$FORCE" -eq 1 ]; then
    node_engine="$NODE_VER"; [ "$NODE_VER" = "latest" ] && node_engine=">=20"
    cat > package.json <<PKG
{
  "name": "$NAME",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": { "node": "$node_engine" },
  "scripts": {
    "build": "echo \"TODO build\"",
    "test": "echo \"TODO test\" && exit 0",
    "lint": "echo \"TODO lint\""
  }
}
PKG
    ok "package.json (node $NODE_VER)"
  else skip "package.json"; fi
  add_tv "nodejs $NODE_VER"
fi

if [ -n "$PY_VER" ]; then
  echo "$PY_VER" > .python-version; ok ".python-version"
  if [ ! -e pyproject.toml ] || [ "$FORCE" -eq 1 ]; then
    req="$PY_VER"; case "$PY_VER" in latest) req=">=3.11";; *) req=">=$PY_VER";; esac
    cat > pyproject.toml <<PY
[project]
name = "$NAME"
version = "0.1.0"
requires-python = "$req"

[tool.ruff]
line-length = 100
PY
    ok "pyproject.toml (python $PY_VER)"
  else skip "pyproject.toml"; fi
  add_tv "python $PY_VER"
fi

if [ -n "$GO_VER" ]; then
  if [ ! -e go.mod ] || [ "$FORCE" -eq 1 ]; then
    gv="$GO_VER"; [ "$GO_VER" = "latest" ] && gv="1.22"
    cat > go.mod <<GO
module $NAME

go $gv
GO
    ok "go.mod (go $gv)"
  else skip "go.mod"; fi
  add_tv "golang $GO_VER"
fi

[ -n "$JAVA_VER" ] && add_tv "java $JAVA_VER"

if [ -n "$tool_versions" ]; then
  if [ ! -e .tool-versions ] || [ "$FORCE" -eq 1 ]; then
    printf "%b" "$tool_versions" > .tool-versions
    ok ".tool-versions (mise/asdf)"
  else skip ".tool-versions"; fi
fi

# =============================================================================
# 9) git init / Khoi tao git
# =============================================================================
if [ "$DO_GIT" -eq 1 ]; then
  if [ ! -d .git ]; then
    if command -v git >/dev/null 2>&1; then
      git init -q && ok "git init"
    else warn "git not found - skipping / khong co git - bo qua"; fi
  else skip "git (already a repo / da la repo)"; fi
fi

# =============================================================================
# Done / Xong
# =============================================================================
echo
ok "AI-Native SDLC scaffold ready in $(pwd)"
ok "Khung AI-Native SDLC da san sang trong $(pwd)"
echo
info "Next / Tiep theo:"
msg  "  1. Edit CLAUDE.md - fill in Commands/Conventions. / Sua CLAUDE.md."
[ -n "$tool_versions" ] && msg "  2. Install runtimes: 'mise install' or use nvm/asdf. / Cai runtime: 'mise install' hoac nvm/asdf."
msg  "  3. Open Claude Code here, then run: /intent <your idea>"
msg  "  4. Read docs/AI-SDLC.md for the full loop. / Doc docs/AI-SDLC.md."
