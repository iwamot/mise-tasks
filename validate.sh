#!/bin/bash
set -e

# mise
eval "$(mise activate bash)"
mise fmt
mise install

# Run shared lint tasks
mise run gha-lint
mise run docker-lint Dockerfile.selftest
mise run renovate-lint

# Check for uncommitted changes
git diff --exit-code
