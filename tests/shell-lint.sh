#!/bin/bash
# Exercise file discovery with the real Git, shfmt, and shellcheck commands.
set -euo pipefail
cd "$(dirname "$0")/.."

task="$PWD/.mise/tasks/shell-lint"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
git init --quiet "$repo"

run_task() {
  MISE_PROJECT_ROOT="$repo" bash "$task" >"$tmp/output" 2>&1
}

expect_failure() {
  if run_task; then
    echo "shell-lint unexpectedly succeeded: $1" >&2
    cat "$tmp/output" >&2
    exit 1
  fi
  grep -Fq "$1" "$tmp/output"
}

# An empty repository and a repository with only untracked scripts need no lint.
run_task
cat >"$repo/untracked.sh" <<'SCRIPT'
#!/bin/bash
echo $missing
SCRIPT
run_task

# Tracked non-shell files do not make an untracked shell script eligible.
printf 'plain text\n' >"$repo/readme.txt"
git -C "$repo" add readme.txt
run_task

# Extensionless scripts and paths containing spaces are both linted.
cat >"$repo/a script" <<'SCRIPT'
#!/bin/bash
printf 'hello\n'
SCRIPT
git -C "$repo" add 'a script'
run_task
cat >"$repo/a script" <<'SCRIPT'
#!/bin/bash
echo $missing
SCRIPT
expect_failure SC2086

# A failed Git listing must not turn into an empty successful inspection.
printf 'broken' >"$repo/.git/index"
expect_failure 'index file smaller than expected'
