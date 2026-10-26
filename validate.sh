#!/bin/bash
set -e

# mise
eval "$(mise activate bash)"
mise fmt
mise install

# Run shared lint tasks
mise run gha-lint
mise run shell-lint
mise run docker-lint Dockerfile.selftest

# Exercise shared shell-file discovery against real temporary repositories.
bash tests/shell-lint.sh

# Check for uncommitted changes
git diff --exit-code
