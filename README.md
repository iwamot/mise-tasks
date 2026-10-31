# mise-tasks

iwamot's shared mise tasks.

## Tasks

| Task | Purpose |
|------|---------|
| `gha-lint` | Run a GitHub Actions lint suite ([jactionlint](https://github.com/jdx/jactionlint), ghalint, pinact, zizmor) over workflows and composite actions (`action.yml` anywhere in the repo). Fixers run before checkers. Verify action dependency lockfiles with gh-actions-lock when present. |
| `docker-lint` | Lint Dockerfiles with hadolint. Pass file paths as arguments, or omit to default to `Dockerfile`. |
| `licenses` | Check dependency licenses for `go`, `python`, or `node` against a shared allowlist of permissive licenses and MPL-2.0. Additional arguments allow exact license names for the caller. |
| `shell-lint` | Lint shell scripts with shfmt (formatter, runs first) and shellcheck. Detects files via `shfmt -f` (covers extensionless shebang scripts) intersected with `git ls-files`, so vendored scripts under `.venv`, `node_modules`, etc. are skipped automatically. |
| `gitignore-prune` | Prune entries from tracked `.gitignore` files that no longer match anything in the working tree (runs `gitignore-prune --fix`). Comments, blank lines, and entry order are preserved; submodules are skipped. Best run manually — the verdict depends on the current working tree, so the same check returns different results in CI than in a developer checkout. |
| `enable-git-hooks` | Register a pre-commit hook (`./validate.sh`) and commit-msg hooks (DCO `Signed-off-by` check, and a Conventional Commits subject check that allows `feat`, `fix`, `chore`, `docs`, `article`) via Git config-based hooks. Requires Git 2.54+. |
| `disable-git-hooks` | Remove the hooks registered by `enable-git-hooks`. |
| `release-notes-preview` | Preview the next release's auto-generated notes via the GitHub API (no tag/release is created). Reuses `.github/release.yml` categorization. Pass the next tag name as an argument (e.g. `mise run release-notes-preview v1.2.3`); defaults to `vNEXT`. Requires `gh` to be authenticated. |

## Usage

In your repository's `mise.toml`:

```toml
[settings]
experimental = true

[task_config]
includes = ["git::https://github.com/iwamot/mise-tasks.git//.mise/tasks?ref=vX.X.X"]
```

Then run a task locally or in CI:

```bash
mise run gha-lint
mise run docker-lint
```

The lint tasks declare their own `tools.*`, so their binaries are installed on demand. The `licenses` task uses the caller's dependency environment, as described below.

Each repository can pick whichever tasks fit its setup (e.g. `gha-lint` only when there's no Dockerfile).

When `.github/workflows/actions.lock` exists, `gha-lint` verifies its direct and transitive action pins against GitHub. It uses `GITHUB_TOKEN` from CI or the local `gh` login. An outdated or invalid lockfile fails the task; regenerate it with `gh-actions-lock` when changing action references.

### Dependency licenses

Run after installing the project's dependencies, from `validate.sh` or locally:

```bash
mise run licenses go
mise run licenses python
mise run licenses node
```

The caller provides `go-licenses` and Go for `go`, `uv` and the project's `pip-licenses` dependency for `python`, or `aube` and Node.js for `node`. The task uses the caller's versions and installed environment.

Add repository-specific license names as positional arguments. Names and SPDX expressions must match exactly:

```bash
mise run licenses python "3-Clause BSD License"
mise run licenses node "(Apache-2.0 WITH LLVM-exception)"
```

For a Python package whose metadata needs a separate check, exclude it from the shared check and check it explicitly:

```bash
mise run licenses python --ignore-package tiktoken
# tiktoken's License field contains the full MIT text.
uv run pip-licenses --packages tiktoken --partial-match --allow-only="MIT License"
```

For Node.js, dependencies absent from disk (such as optional packages for other platforms) are left out. An installed package with an unapproved license fails the task and prints its name, version, and license. A failed license listing also fails the task.

## Validation

```bash
./validate.sh
```
