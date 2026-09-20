# AI-Native SDLC Starter

> EN: A one-command scaffolder for the **Anthropic AI-Native SDLC** (Plan → Design →
> Build → Test → Deploy → Maintain). Works on macOS, Linux and Windows. Pin the
> runtime versions you want; run it whenever you have internet.
>
> VI: Bộ tạo khung **một lệnh** theo **AI-Native SDLC của Anthropic** (Plan → Design →
> Build → Test → Deploy → Maintain). Chạy trên macOS, Linux và Windows. Ghim phiên
> bản runtime bạn muốn; dùng khi cần miễn là có internet.

Based on Anthropic's *The AI-Native SDLC Playbook* (Aug 21, 2026):
<https://claude.com/blog/the-ai-native-sdlc-playbook>

---

## 1. What it creates / Nó tạo ra gì

Every stage of the playbook commits one version-controlled artifact that the next
stage reads. The scaffold gives each artifact a home plus the Claude Code kit
(agents, skills, hooks) that operates the loop.

Mỗi giai đoạn commit một artifact vào git để giai đoạn sau đọc. Khung tạo sẵn chỗ
cho từng artifact, kèm bộ Claude Code (agents, skills, hooks) vận hành vòng lặp.

```
your-project/
├── intent/           # Stage 1 Plan     → intent.md  (what & why)
├── specs/            # Stage 2 Design    → spec.md    (requirements + design)
├── plans/            # Stage 3 Build     → plan.md    (plan before code)
├── src/  tests/      #                     code + tests
├── evals/            # Stage 4 Test      → agent regression evals
├── REVIEW.md         # Stage 5 Deploy    → review policy (passes, severity)
├── monitoring/       # Stage 6 Maintain  → bands.yaml (deterministic triggers)
├── docs/             #   AI-SDLC.md guide, ADRs, runbooks, incident records
├── Makefile          #   make check = lint + test, the gate for humans and agents
├── AGENTS.md         #   the same contract, for Codex / Cursor / Copilot / Gemini
├── .github/workflows/#   CI (make check) + agent-evals + claude-review
└── .claude/
    ├── agents/       # planner, coder, tester, reviewer, verifier
    ├── skills/       # /intent, /spec, /feature (the orchestrator), secure-api-review
    ├── hooks/        # guard-bash, format, protect-tests, production-gate
    └── settings.json # permission allow/deny + hook wiring
```

**The loop / Vòng lặp:** `/intent` → `/spec` → `/feature` (plan → code → test → review),
with two human gates: approve the plan, approve the commit. Nothing is pushed
automatically. / Hai cổng duyệt của người: duyệt plan, duyệt commit. Không tự push.

---

## 2. Run it / Cách chạy

### macOS / Linux (bash)
```bash
# Shortest form: latest release, project name first, runtimes after -w
curl -fsSL https://niseel.github.io/ai-sdlc-starter/init.sh | bash -s -- my-app -w node,python@3.12

# Pinned to a release tag (immutable, reproducible for teams and CI)
curl -fsSL https://raw.githubusercontent.com/Niseel/ai-sdlc-starter/v0.1.0/init.sh | bash -s -- my-app -w node

# From a local copy / Tu ban copy ve may
bash init.sh my-app -w node,python@3.12
```

### Windows (PowerShell)
```powershell
irm https://niseel.github.io/ai-sdlc-starter/init.ps1 -OutFile init.ps1
powershell -ExecutionPolicy Bypass -File .\init.ps1 my-app -With node,python@3.12
```

Both scripts produce **byte-for-byte identical** output. / Hai script cho output **giống hệt từng byte**.

### Options / Tùy chọn
| bash | PowerShell | EN | VI |
|------|-----------|----|----|
| `NAME` (first arg) | `NAME` (first arg) | project name | tên dự án |
| `-w`, `--with` | `-w`, `-With` | runtimes: `node,python@3.12,go@1.22,java@21` | runtime, cách nhau dấu phẩy |
| `-n`, `--name` | `-n`, `-Name` | project name | tên dự án |
| `-d`, `--dir` | `-d`, `-Dir` | target directory (default `.`) | thư mục đích |
| `--node/--python/--go/--java` | `-Node/-Python/-Go/-Java` | pin one runtime | ghim từng runtime |
| `-f`, `--force` | `-Force` | overwrite existing files | ghi đè file đã có |
| `--no-git` | `-NoGit` | skip `git init` | bỏ `git init` |
| `-h`, `--help` | `-Help` | show help | hiện trợ giúp |

`-w node` uses the default version for that runtime (`node` = latest, `python` = 3.12,
`go` = 1.22, `java` = 21). `-w python@3.11` pins an exact one.
/ `-w node` dùng bản mặc định; `-w python@3.11` ghim đúng bản đó.

> **Version pinning only / Chỉ ghim phiên bản.** The script writes `.nvmrc`,
> `.python-version`, `.tool-versions`, and the matching manifest (`package.json`,
> `pyproject.toml`, `go.mod`). It does **not** download runtimes — install them with
> [mise](https://mise.jdx.dev), `nvm`, or `asdf` (e.g. `mise install`).
> Script **không** tải runtime — dùng mise/nvm/asdf để cài.

Re-running is safe: existing files are skipped unless `--force`.
Chạy lại an toàn: file đã có sẽ được bỏ qua trừ khi `--force`.

---

## 3. After scaffolding / Sau khi tạo khung

1. Fill in `CLAUDE.md` → the **Commands** section (build/test/lint) is what lets the
   agents verify their own work. / Điền `CLAUDE.md`, nhất là mục **Commands**.
2. Install runtimes: `mise install` (or nvm/asdf). / Cài runtime.
3. Open Claude Code in the folder and start the loop:
   ```
   /intent Thêm chức năng reset mật khẩu qua email
   /spec intent/reset-password.md
   /feature specs/reset-password.md
   ```
4. Read `docs/AI-SDLC.md` for the full flow. / Đọc `docs/AI-SDLC.md`.

The four hooks are guardrails that run for the main session **and every subagent**:
destructive commands are blocked, edited files auto-formatted, test files protected
during fixes, and production deploys gated on a named approval.

---

## 4. Distribution strategy / Chiến lược phân phối

The goal: run it anytime, anywhere, pinned to a chosen version — like an installer.
Mục tiêu: chạy mọi lúc, mọi nơi, cố định theo version — như một trình cài đặt.

**A. Versioned on GitHub (recommended first step) / Gắn version trên GitHub (nên làm trước)**
- The scripts live at <https://github.com/Niseel/ai-sdlc-starter>. Tag releases: `v0.1.0`, `v0.2.0`, …
- Users pull a **specific version** via the raw URL with the tag in the path (the
  `curl … | bash` / `irm … | iex` one-liners in §2). A tag is immutable, so a given
  version always produces the same scaffold — reproducible for teams and CI.
- Mỗi version là một git tag; raw URL chứa tag nên bất biến và tái lập được.

**B. `npx`-style wrapper (later) / Bọc kiểu `npx` (về sau)**
- Publish a tiny npm package `create-ai-sdlc` whose `bin` just runs the right script
  for the OS. Then: `npx create-ai-sdlc@latest --node latest`.
- A Homebrew formula / `pipx` app can wrap the same scripts for non-Node users.

**C. Landing page + community (product stage) / Trang giới thiệu + cộng đồng (giai đoạn sản phẩm)**
- A one-page site: what it is, the copy-paste install command, a diagram of the loop,
  a link to the playbook, and a "report an issue / suggest a stage" button → GitHub Issues.
- Trang một-page: giới thiệu, lệnh cài copy-paste, sơ đồ vòng lặp, nút góp ý → Issues.

> Keep the scripts dependency-free (only `bash`/`pwsh` + `git`, and `jq` at *runtime*
> for the hooks). That is what makes the one-liner install reliable across machines.
> Giữ script không phụ thuộc gì ngoài bash/pwsh + git (và `jq` lúc chạy hook).

---

## 5. Versioning / Đánh version
- Script version is printed at the top of every run (`init-ai-sdlc 0.1.0`) and via
  `--version`. Bump it when the scaffold changes. / In version mỗi lần chạy và qua `--version`.

## 6. Landing page / Trang giới thiệu

`index.html` + `assets/` is a static, bilingual (EN/VI) page served by GitHub Pages
from the repo root: install-command builder, the six-stage loop, the kit, the workflow, FAQ.
/ Trang tĩnh song ngữ, GitHub Pages phục vụ thẳng từ thư mục gốc.

Publish / Đưa lên mạng:
1. Push to GitHub, tag the release: `git tag v0.1.0 && git push --tags`.
2. Repo **Settings → Pages → Build and deployment → Deploy from a branch → `main` / `/ (root)`**.
3. The page appears at `https://niseel.github.io/ai-sdlc-starter/`. It reads the owner
   and repo from that URL and the version from `VERSION`, so every link and install
   command points at your repo. To force a value, set `<meta name="repo" content="owner/repo">`.
   / Trang tự lấy owner/repo từ URL và version từ `VERSION`.

Preview locally: open `index.html` in a browser. / Xem thử: mở `index.html` bằng trình duyệt.

## 7. Design system for UI work / Design system cho mọi UI

All UI in this repo follows `design-system/` ("Midnight Glass", design language
measured from orchid.security): `DESIGN.md` (rules), `tokens.css`, `components.css`.
/ Mọi UI trong repo tuân theo `design-system/`.

Two Claude Code skills in `.claude/skills/`:
- `design-system` — loaded before any UI change; enforces tokens and recipes.
  `/design-system <url>` rebuilds the system from another reference site.
- `extract-design` — vendored from [designlang](https://github.com/Manavarya09/design-extract)
  (MIT), pinned to `designlang@12.21.0` after an audit (see `UPSTREAM.md`).
  Needs Node 20+ and Chrome or Playwright Chromium. / Cần Node 20+ và Chrome.

## License
MIT - see [LICENSE](LICENSE).
