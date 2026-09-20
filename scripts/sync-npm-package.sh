#!/usr/bin/env bash
# EN: Copy the scaffolders into the npm package and align its version with VERSION.
#     Run this before `npm publish` so the package can never drift from the repo.
# VI: Copy script vao goi npm va dong bo version voi file VERSION. Chay truoc khi
#     publish de goi khong bao gio lech voi repo.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pkg="$root/packages/create-ai-sdlc"
version="$(tr -d '[:space:]' < "$root/VERSION")"

cp "$root/init.sh" "$root/init.ps1" "$root/LICENSE" "$pkg/"
chmod +x "$pkg/init.sh"

node -e '
  const fs = require("fs");
  const file = process.argv[1];
  const version = process.argv[2];
  const pkg = JSON.parse(fs.readFileSync(file, "utf8"));
  pkg.version = version;
  fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
' "$pkg/package.json" "$version"

echo "synced create-ai-sdlc@$version"
