#!/usr/bin/env node
"use strict";

// EN: Thin wrapper. It picks the right scaffolder for the platform, hands over
//     the arguments, and exits with the script's own exit code. All the work
//     lives in init.sh / init.ps1, so npm and curl users get the same output.
// VI: Lop vo mong. Chon dung script theo he dieu hanh, chuyen doi so, tra ve
//     dung ma thoat. Moi viec nam trong init.sh / init.ps1.

const { spawnSync } = require("node:child_process");
const { existsSync } = require("node:fs");
const path = require("node:path");

// Published package: the scripts sit next to this file. Repo checkout: two levels up.
function findScript(name) {
  const candidates = [path.join(__dirname, name), path.join(__dirname, "..", "..", name)];
  return candidates.find(existsSync) || null;
}

// bash flag -> PowerShell parameter
const WINDOWS_FLAGS = new Map([
  ["-w", "-With"], ["--with", "-With"],
  ["-n", "-Name"], ["--name", "-Name"],
  ["-d", "-Dir"], ["--dir", "-Dir"],
  ["-f", "-Force"], ["--force", "-Force"],
  ["--no-git", "-NoGit"],
  ["-h", "-Help"], ["--help", "-Help"],
  ["--node", "-Node"], ["--python", "-Python"], ["--go", "-Go"], ["--java", "-Java"],
]);

function toWindowsArgs(args) {
  return args.map((arg) => WINDOWS_FLAGS.get(arg) || arg);
}

function main() {
  const args = process.argv.slice(2);
  const windows = process.platform === "win32";
  const scriptName = windows ? "init.ps1" : "init.sh";
  const script = findScript(scriptName);

  if (!script) {
    console.error(`ai-sdlc-starter: ${scriptName} not found next to ${__filename}`);
    console.error("Reinstall the package, or run the script straight from the web:");
    console.error("  https://niseel.github.io/ai-sdlc-starter/");
    process.exit(1);
  }

  const command = windows ? "powershell" : "bash";
  const argv = windows
    ? ["-ExecutionPolicy", "Bypass", "-File", script, ...toWindowsArgs(args)]
    : [script, ...args];

  const result = spawnSync(command, argv, { stdio: "inherit" });

  if (result.error) {
    console.error(`ai-sdlc-starter: could not run ${command}: ${result.error.message}`);
    process.exit(1);
  }
  process.exit(result.status === null ? 1 : result.status);
}

main();
