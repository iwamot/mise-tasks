#!/bin/bash
# Exercise lockfile verification with the real lint tools and GitHub actions.
set -euo pipefail
cd "$(dirname "$0")/.."

task="$PWD/.mise/tasks/gha-lint"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
git init --quiet "$repo"
git -C "$repo" remote add origin https://github.com/iwamot/mise-tasks.git
mkdir -p "$repo/.github/workflows"

write_workflow() {
  local version="$1" sha="$2"
  cat >"$repo/.github/workflows/check.yml" <<WORKFLOW
name: Check
on: [pull_request]
concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true
permissions: {}
jobs:
  check:
    name: Check
    runs-on: ubuntu-26.04
    timeout-minutes: 5
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: jdx/mise-action@${sha} # v${version}
WORKFLOW
}

run_task() {
  if ! MISE_PROJECT_ROOT="$repo" bash "$task" >"$tmp/output" 2>&1; then
    cat "$tmp/output" >&2
    return 1
  fi
}

# Repositories without a lockfile retain the existing lint behavior.
write_workflow 5.2.3 82a612c5ab8bcda7cc5db6b7e81a8e7584c3dc6e
run_task

# An onboarded workflow with matching pins passes online verification.
(
  cd "$repo"
  gh-actions-lock --no-interactive --no-narrow
)
run_task
grep -Fq 'All 1 workflow valid' "$tmp/output"

# A real dependency update must fail until the lockfile is regenerated.
write_workflow 5.2.4 6be3c7ed4c21d4f76b208d351d95aac273ebb76d
if MISE_PROJECT_ROOT="$repo" bash "$task" >"$tmp/output" 2>&1; then
  echo "gha-lint unexpectedly accepted an outdated action lockfile" >&2
  cat "$tmp/output" >&2
  exit 1
fi
if ! grep -Fq '[actions-lock]' "$tmp/output"; then
  cat "$tmp/output" >&2
  exit 1
fi
