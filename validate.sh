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

# Exercise optional action lockfile checks with real lint tools and dependencies.
bash tests/gha-lint.sh

# Exercise license decisions with real installed local dependencies.
bash tests/licenses.sh

# Check for uncommitted changes
git diff --exit-code
