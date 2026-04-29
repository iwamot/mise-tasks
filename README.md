# mise-tasks

iwamot's shared mise tasks.

## Tasks

| Task | Purpose |
|------|---------|
| `gha-lint` | Run a GitHub Actions lint suite (actionlint, ghalint, pinact, zizmor). Fixers run before checkers. |
| `docker-lint` | Lint Dockerfiles with hadolint. Pass file paths as arguments, or omit to default to `Dockerfile`. |
| `shell-lint` | Lint shell scripts with shfmt (formatter, runs first) and shellcheck. Detects files via `shfmt -f` (covers extensionless shebang scripts) intersected with `git ls-files`, so vendored scripts under `.venv`, `node_modules`, etc. are skipped automatically. |
| `enable-git-hooks` | Register a pre-commit hook (`./validate.sh`) and a commit-msg hook (DCO `Signed-off-by` check) via Git config-based hooks. Requires Git 2.54+. |
| `disable-git-hooks` | Remove the hooks registered by `enable-git-hooks`. |

## Usage

In your repository's `mise.toml`:

```toml
[task_config]
includes = ["git::https://github.com/iwamot/mise-tasks.git//.mise/tasks?ref=v0.9.0"]
```

Then run a task locally or in CI:

```bash
mise run gha-lint
mise run docker-lint
```

Each task declares its own `tools.*`, so the required binaries are installed on demand. You don't need to add them to your repo's `mise.toml`.

Each repository can pick whichever tasks fit its setup (e.g. `gha-lint` only when there's no Dockerfile).

## Validation

```bash
./validate.sh
```
