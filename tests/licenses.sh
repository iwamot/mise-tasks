#!/bin/bash
# Exercise the shared task with real aube metadata and installed local packages.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'if [[ $? != 0 && -f "$tmp/output" ]]; then cat "$tmp/output" >&2; fi; rm -rf "$tmp"' EXIT
repo="$tmp/repo"
mkdir -p "$repo/deps"
printf '[task_config]\nincludes = ["%s/.mise/tasks"]\n' "$PWD" >"$repo/mise.toml"
# The temporary caller provides the test tools, just as a real caller does.
aube_bin=$(mise which aube)
node_bin=$(mise which node)
printf '\n[env]\n_.path = ["%s", "%s"]\n' "$(dirname "$aube_bin")" "$(dirname "$node_bin")" >>"$repo/mise.toml"

# Reject installed GPL and unapproved expressions, accept MIT and explicit
# exceptions, and omit an optional package absent from disk. Failures must name
# the package, its version, and the exact license that needs a decision.
node - "$repo" <<'JS'
const { mkdirSync, writeFileSync } = require("node:fs");
const { join } = require("node:path");
const root = process.argv[2];
const dependencies = {};
const optionalDependencies = {};
for (const [name, license, os] of [
  ["allowed", "MIT"],
  ["copyleft", "GPL-3.0-only"],
  ["expression", "(MIT OR GPL-3.0-only)"],
  ["other-platform", "GPL-3.0-only", ["!" + process.platform]],
]) {
  const path = join(root, "deps", name);
  mkdirSync(path);
  writeFileSync(join(path, "package.json"), JSON.stringify({ name, version: "1.0.0", license, ...(os ? { os } : {}) }));
  (os ? optionalDependencies : dependencies)[name] = os ? "file:./other-platform.tgz" : "file:./deps/" + name;
}
writeFileSync(join(root, "package.json"), JSON.stringify({ name: "license-task-test", version: "1.0.0", private: true, dependencies, optionalDependencies }));
JS

# A packed optional dependency has its own installed directory rather than a
# symlink to the fixture sources.
mkdir -p "$tmp/optional/package"
cp "$repo/deps/other-platform/package.json" "$tmp/optional/package/"
tar -czf "$repo/other-platform.tgz" -C "$tmp/optional" package
(cd "$repo" && "$aube_bin" install --offline --ignore-scripts)

# An optional package may have a lock entry without an installed directory.
(cd "$repo" && "$aube_bin" licenses --json --long) >"$tmp/packages.json"
node - "$repo" "$tmp/packages.json" <<'JS'
const { readFileSync, rmSync } = require("node:fs");
const packages = JSON.parse(readFileSync(process.argv[3], "utf8"));
const optional = packages.find((pkg) => pkg.name === "other-platform");
if (!optional.path.startsWith(process.argv[2] + "/")) throw new Error("Fixture package must be inside the temporary project");
rmSync(optional.path, { recursive: true });
JS

run_task() {
  mise -C "$repo" run licenses node "$@" >"$tmp/output" 2>&1
}

if run_task; then
  echo 'licenses accepted an installed GPL dependency' >&2
  exit 1
fi
grep -Fxq 'copyleft@1.0.0: GPL-3.0-only' "$tmp/output"
grep -Fxq 'expression@1.0.0: (MIT OR GPL-3.0-only)' "$tmp/output"
if grep -Fq 'other-platform@' "$tmp/output"; then
  echo 'licenses checked an uninstalled optional dependency' >&2
  exit 1
fi

# An exception for one string must not approve a different SPDX expression.
if run_task "GPL-3.0-only"; then
  echo 'licenses accepted an unapproved expression' >&2
  exit 1
fi
grep -Fxq 'expression@1.0.0: (MIT OR GPL-3.0-only)' "$tmp/output"
if grep -Fq 'copyleft@' "$tmp/output"; then
  echo 'licenses ignored an explicit exception' >&2
  exit 1
fi

run_task "GPL-3.0-only" "(MIT OR GPL-3.0-only)"

# A listing error must fail rather than become an empty successful inspection.
printf '{broken' >"$repo/package.json"
if run_task "GPL-3.0-only" "(MIT OR GPL-3.0-only)"; then
  echo 'licenses accepted a failed dependency listing' >&2
  exit 1
fi
