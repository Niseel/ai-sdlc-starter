#!/usr/bin/env bash
# EN: End-to-end test of --adopt. Builds a fake existing project, runs the
#     scaffolder in dry-run, then twice for real, and asserts that nothing the
#     user owned was lost or rewritten.
# VI: Test --adopt tu dau den cuoi tren mot project gia lap co san.
#
# Usage: scripts/test-adopt.sh sh|ps <workdir>
set -euo pipefail

kind="${1:?usage: test-adopt.sh sh|ps <workdir>}"
work="${2:?usage: test-adopt.sh sh|ps <workdir>}"
root="$(cd "$(dirname "$0")/.." && pwd)"
logs="$(mktemp -d)"

run() {
  if [ "$kind" = "ps" ]; then
    local args=()
    for a in "$@"; do
      case "$a" in --adopt) args+=("-Adopt") ;; --dry-run) args+=("-DryRun") ;; *) args+=("$a") ;; esac
    done
    pwsh -NoProfile -File "$root/init.ps1" "${args[@]}"
  else
    bash "$root/init.sh" "$@"
  fi
}
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok   - $*"; }
snapshot() { find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while read -r f; do cksum "$f"; done; }

# ---- the "existing project" ----------------------------------------------------
rm -rf "$work"; mkdir -p "$work"; cd "$work"
mkdir -p .claude/agents src
cat > package.json <<'EOF'
{
  "name": "legacy-app",
  "scripts": {
    "test": "vitest run",
    "lint": "eslint ."
  },
  "dependencies": { "build": "1.0.0" }
}
EOF
: > pnpm-lock.yaml
printf 'test:\n\tpnpm test\n' > Makefile
printf '# Legacy app\n\nOur own readme.\n' > README.md
printf '# House rules\n\n- Use tabs.\n- Money is BigDecimal.\n' > CLAUDE.md
printf 'node_modules/\ndist/\n' > .gitignore
printf 'export const x = 1;\n' > src/index.js
printf -- '---\nname: reviewer\ndescription: our reviewer\n---\nOur own review rules.\n' > .claude/agents/reviewer.md
cat > .claude/settings.json <<'EOF'
{
  "model": "opus",
  "permissions": {
    "allow": ["Bash(pnpm test)", "Bash(git status)"]
  },
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [ { "type": "command", "command": "./scripts/our-lint.sh" } ] }
    ]
  }
}
EOF
for f in CLAUDE.md README.md Makefile package.json .gitignore src/index.js .claude/agents/reviewer.md .claude/settings.json; do
  mkdir -p "$logs/orig/$(dirname "$f")"; cp "$f" "$logs/orig/$f"
done
git init -q
git add -A
git -c user.name=test -c user.email=test@example.com commit -qm "existing project"

# ---- 1. a fresh scaffold refuses to run here ----------------------------------
if run demo -w node > "$logs/guard.log" 2>&1; then fail "fresh scaffold ran on an existing project"; fi
grep -q -- "--adopt" "$logs/guard.log" || fail "guard did not suggest --adopt"
pass "fresh scaffold refuses an existing project and suggests --adopt"

# ---- 2. dry run writes nothing -------------------------------------------------
before="$(snapshot)"
run --adopt --dry-run > "$logs/dry.log" 2>&1 || { cat "$logs/dry.log"; fail "dry run exited non-zero"; }
[ "$before" = "$(snapshot)" ] || fail "dry run changed files"
grep -q "would" "$logs/dry.log" || fail "dry run printed no plan"
pass "--dry-run writes nothing"

# ---- 3. adopt for real ---------------------------------------------------------
echo "work in progress" >> src/index.js     # dirty tree -> expect a warning
run --adopt > "$logs/adopt1.log" 2>&1 || { cat "$logs/adopt1.log"; fail "adopt exited non-zero"; }
grep -qi "uncommitted" "$logs/adopt1.log" || fail "no warning about the dirty tree"
pass "warns about uncommitted changes"

for f in README.md Makefile package.json .claude/agents/reviewer.md; do
  cmp -s "$f" "$logs/orig/$f" || fail "$f was modified"
done
pass "README, Makefile, package.json and the user's reviewer agent are untouched"

orig_claude="$(cat "$logs/orig/CLAUDE.md")"
[ "$(head -c ${#orig_claude} CLAUDE.md)" = "$orig_claude" ] || fail "CLAUDE.md lost its original content"
[ "$(grep -c 'ai-sdlc:start' CLAUDE.md)" = "1" ] || fail "CLAUDE.md block missing or duplicated"
grep -q -- "- make test" CLAUDE.md || fail "Makefile target not detected"
grep -q -- "- pnpm run test" CLAUDE.md || fail "package.json test script not detected"
grep -q -- "- pnpm run lint" CLAUDE.md || fail "package.json lint script not detected"
if grep -q -- "run build" CLAUDE.md; then fail "a dependency named build was taken for a script"; fi
pass "CLAUDE.md keeps its content and gains one block with the detected commands"

head -c "$(wc -c < "$logs/orig/.gitignore")" .gitignore | cmp -s - "$logs/orig/.gitignore" || fail ".gitignore lost content"
grep -q "settings.local.json" .gitignore || fail ".gitignore block missing"
grep -q "ai-sdlc:start" AGENTS.md || fail "AGENTS.md block missing"
pass ".gitignore extended, AGENTS.md created"

s=.claude/settings.json
jq -e '.model == "opus"' $s >/dev/null || fail "settings lost the user's model"
jq -e '.permissions.allow | index("Bash(pnpm test)")' $s >/dev/null || fail "settings lost the user's allow rule"
jq -e '.permissions.allow | index("Bash(git diff *)")' $s >/dev/null || fail "starter allow rules not merged"
jq -e '.permissions.deny | index("Bash(git push *)")' $s >/dev/null || fail "starter deny rules not merged"
jq -e '[.hooks.PostToolUse[] | select(.matcher == "Edit|Write") | .hooks[].command] | (index("./scripts/our-lint.sh") != null) and (map(test("format.sh")) | any)' $s >/dev/null \
  || fail "PostToolUse hooks not merged into the user's Edit|Write group"
jq -e '[.hooks.PreToolUse[] | .hooks[].command] | map(test("guard-bash.sh")) | any' $s >/dev/null || fail "guard-bash hook missing"
[ "$(jq '[.hooks.PostToolUse[] | select(.matcher == "Edit|Write")] | length' $s)" = "1" ] || fail "Edit|Write group duplicated"
cmp -s "$s.bak" "$logs/orig/.claude/settings.json" || fail "settings.json.bak is not the original"
pass "settings.json merged: user's model, rules and hooks kept, guardrails added, backup kept"

for p in src/.gitkeep tests scripts .github/workflows/ci.yml .github/workflows/claude-review.yml .nvmrc; do
  [ -e "$p" ] && fail "$p should not be created by --adopt"
done
for p in intent/_TEMPLATE.md specs/_TEMPLATE.md plans/_TEMPLATE.md docs/AI-SDLC.md REVIEW.md \
         .claude/agents/planner.md .claude/skills/feature/SKILL.md .claude/hooks/guard-bash.sh; do
  [ -e "$p" ] || fail "$p missing"
done
grep -q "reviewer.md" "$logs/adopt1.log" || fail "report did not flag the kept reviewer agent"
pass "adds the SDLC kit, skips runtime files and CI, reports the agent collision"

# ---- 4. running again changes nothing ------------------------------------------
first="$(snapshot)"
run --adopt > "$logs/adopt2.log" 2>&1 || { cat "$logs/adopt2.log"; fail "second adopt exited non-zero"; }
[ "$first" = "$(snapshot)" ] || fail "second run changed files"
pass "a second --adopt is a no-op"

echo "all adopt checks passed ($kind)"
