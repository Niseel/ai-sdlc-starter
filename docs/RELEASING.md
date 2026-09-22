# Releasing

npm has no upload button: a package is always published by `npm publish`, either
from a terminal or from CI. This repo publishes from CI. Once trusted publishing is
set up (part A), a GitHub release is all it takes (part B) — no token, no OTP.

VI: npmjs.com không có nút upload. Gói luôn được publish bằng `npm publish`, từ
terminal hoặc từ CI. Bật trusted publishing một lần (phần A), sau đó chỉ cần tạo
release trên GitHub (phần B) — không token, không OTP.

## A. One time, on npmjs.com — trusted publishing

1. Open <https://www.npmjs.com/package/ai-sdlc-starter/access> (the package's **Settings** tab).
2. Under **Trusted Publisher**, click **GitHub Actions**.
3. Fill in exactly:

   | Field | Value |
   |---|---|
   | Organization or user | `Niseel` |
   | Repository | `ai-sdlc-starter` |
   | Workflow filename | `publish-npm.yml` |
   | Environment name | *(leave empty)* |

4. Click **Set up connection**.
5. After the first automatic release works, on the same page under **Publishing
   access** choose **Require two-factor authentication and disallow tokens**, then
   **Update Package Settings**. CI still publishes; a leaked token no longer can.

## B. Every release

Before this, the version must already be bumped and merged to `main`: `VERSION`,
`VERSION=` in `init.sh`, `$SCRIPT_VERSION` in `init.ps1`.

1. Open <https://github.com/Niseel/ai-sdlc-starter/releases/new>.
2. **Choose a tag** → type `v` + the contents of `VERSION` (for example `v0.3.1`) →
   **Create new tag on publish**. Target: `main`.
3. **Release title**: the same tag. Paste the notes.
4. Tick **Set as the latest release** → **Publish release**.
5. Open the **Actions** tab → **publish npm**. Green after about a minute.
6. Check <https://www.npmjs.com/package/ai-sdlc-starter> shows the new version.

The same thing from a terminal: `gh release create v0.3.1 --latest --title v0.3.1 --notes "..."`.

## When the workflow is red, or green without a new version

| What you see | Why | Fix |
|---|---|---|
| Green, log says `already published - nothing to do` | `VERSION` was not bumped | Bump the version, merge, release again with the new tag |
| `ENEEDAUTH`, `E401` or `E404` on publish | Part A missing, or a field typo | Re-check the four fields in part A |
| `E403 ... cannot publish over the previously published versions` | Same version twice | Bump the version |
| Smoke test step fails | The scaffolder is broken on `main` | Fix it on a branch first; CI on the PR should have caught it |
