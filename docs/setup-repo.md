# `setup-repo.sh`

## Scope

Bootstrap repo-local Git hook wrappers and policy for a project.

## Usage

```sh
setup-repo.sh [--check] [--repo <path>] [--hooks <hooks>] [--profiles <profiles>]
```

## Behavior

- Resolves the target repository from `--repo` or the current Git repository.
- Creates selected repo-local wrappers from the shared templates.
- Infers default wrappers from selected profiles when `--hooks` is omitted.
- Defaults to `pre-commit pre-push commit-msg` for the `common` profile.
- Adds `pre-push` by default when any selected profile has `pre-push` checks.
- Defaults to `--profiles common`, which requires no repo-local config file.
- Use `--profiles "common react-vite"` for pnpm-based React/Vite projects.
- The `react-vite` profile requires repo-local dev dependencies. Install them
  with `pnpm add -D oxlint oxfmt vitest`; global installs are intentionally
  ignored.
- Use `--profiles "common golang"` for Go projects.
- The `golang` profile runs `goimports` and fast `golangci-lint` during
  `pre-commit`, then `go mod tidy -diff`, full `golangci-lint`, `go vet`, and
  `go test` during `pre-push`.
- Use `--profiles "common python"` for Python projects.
- The `python` profile runs Ruff format, import sorting, and lint checks during
  `pre-commit`, then mypy and pytest during `pre-push`.
- Python checks support `GIT_HOOK_PYTHON_RUNNER=auto|uv|path`.
- Python runner `auto` prefers `uv run` when `uv.lock` exists and falls back to
  the active environment or `PATH` otherwise.
- `GIT_HOOK_PYTHON_UV_ARGS` defaults to `--frozen`.
- Add `python/pytest-cov` as a `pre-push` extra check when local coverage is
  required.
- Add `python/pip-audit` as a `pre-push` extra check when dependency audit is
  required.
- Use `--profiles "common pmem"` for repositories managed by Project Memory.
- The `pmem` profile requires `.pmem/env` with `PMEM_PROJECT_KEY=<key>` and
  enforces a `Ref` footer during `commit-msg`.
- Use `--profiles "common shell"` for repositories with shell scripts.
- The `shell` profile runs `shfmt`, `shellcheck`, and executable-bit
  consistency checks during `pre-commit`, then ShellSpec during `pre-push`.
- Shell checks discover staged `.sh`, `.bash`, and `.zsh` files wherever they
  live in the repository. `shfmt` and `shellcheck` skip `.zsh` files.
- ShellSpec discovery uses tracked `.shellspec` files as project roots and runs
  once from each matching directory.
- Does not create `.githooks/hooks.env` by default.
- Writes `.githooks/project.conf` only when a non-default profile selection is
  requested.
- Sets repo-local `core.hooksPath=.githooks`.
- `--check` verifies selected wrappers, required profile config, and
  `core.hooksPath`.

## Selection Model

- `--hooks` selects Git wrapper phases, not individual checks.
- When `--hooks` is omitted, setup infers wrappers from selected profiles.
- Default `common` hooks are `pre-commit pre-push commit-msg`.
- Profiles with `pre-push.list` add `pre-push` to inferred wrappers.
- Passing `--hooks` replaces inferred hook selection for that run.
- Existing repo wrappers are not deleted when a later run selects fewer hooks.
- `--profiles` selects built-in profile check lists.
- Default profile is `common`.
- `GIT_HOOK_PROFILES` may be omitted when the default `common` profile is enough.
- Multiple profiles are additive and run in declared order.
- Unknown profiles are invalid during setup/check and runtime dispatch.
- Duplicate profiles are invalid in `setup-repo.sh` install/check mode.
- Phase-specific `GIT_HOOK_*_EXTRA_CHECKS` append after profile checks.
- Missing extra-check variables default to empty.
- Omit empty variables from `.githooks/project.conf`.
- Extra checks do not override profile checks.
- Duplicate check IDs are not de-duplicated.

## Hook Policy

- Keep `pre-commit` fast and lightweight.
- Prefer staged-area checks in `pre-commit`.
- Keep full repo tests, coverage, audits, builds, and integration checks in
  `pre-push`.
- Use tools that are widely adopted and actively maintained in the target
  language or stack community.
- Resolve runtime and package-manager policy from repo state and hook env where
  needed, for example Python `GIT_HOOK_PYTHON_RUNNER=auto|uv|path`.
- When a tool supports config files, prefer repo config first, user XDG config
  second, bundled git-hooks config third, then tool defaults.
- If a hook requires bundled config or a specific runtime, its own design doc
  must say so explicitly.
- Missing commands should skip with an install hint instead of failing with raw
  shell errors.
- Hook behavior should be portable across `sh`, `bash`, and `zsh` unless the
  hook documents a narrower shell requirement.
- Every hook needs ShellSpec coverage and a matching test case table in its
  design doc.
- Add regression tests when fixing bugs or non-obvious edge cases.
- Commit hook work in reviewable order: docs first, then each hook, then profile
  updates.

Default common example:

```sh
setup-repo.sh
```

Profile example:

```sh
setup-repo.sh \
  --profiles "common shell"
```

Explicit hook override example:

```sh
setup-repo.sh \
  --hooks "pre-commit commit-msg" \
  --profiles "common shell"
```

Custom extra checks example:

```sh
GIT_HOOK_PROFILES="common"
GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS="frontend/oxfmt frontend/oxlint"
GIT_HOOK_PRE_PUSH_EXTRA_CHECKS="frontend/vitest"
```

Python coverage and audit extra checks:

```sh
GIT_HOOK_PROFILES="common python"
GIT_HOOK_PRE_PUSH_EXTRA_CHECKS="python/pytest-cov python/pip-audit"
```

Project Memory (`pmem`) managed repo:

```sh
setup-repo.sh \
  --profiles "common pmem"
```

Force uv for Python hooks:

```sh
GIT_HOOK_PROFILES="common python"
GIT_HOOK_PYTHON_RUNNER=uv
GIT_HOOK_PYTHON_UV_ARGS="--frozen"
```

## Output Policy

Output is short and machine-readable enough for humans or LLM agents:

- Success: `git-hooks: installed; repo=<path>; hooks=<hooks>; profiles=<profiles>`
- Check success: `git-hooks: check ok; repo=<path>; hooks=<hooks>; profiles=<profiles>`
- Failure: `git-hooks: error: <reason>`

## Test Cases

Run only this script's tests:

- `shellspec test/setup-repo_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | bootstraps default common hooks |
| Existing | `git-hooks` | supports optional hook selection |
| Existing | `git-hooks` | supports project profile config |
| Existing | `git-hooks` | infers `pre-push` from selected profiles |
| Existing | `git-hooks` | lets explicit hooks override inference |
| Existing | `git-hooks` | writes only non-empty project policy variables |
| Existing | `git-hooks` | accepts project config with only extra checks |
| Existing | `git-hooks` | checks an existing bootstrap |
| Existing | `git-hooks` | fails check when `core.hooksPath` is missing |
| Existing | `git-hooks` | supports `--repo <path>` outside target repo |
| Existing | `git-hooks` | preserves existing `hooks.env` |
| Existing | `git-hooks` | fails check when non-default config is missing |
| Existing | `git-hooks` | fails check when profiles do not match |
| Existing | `git-hooks` | rejects unknown hook names |
| Existing | `git-hooks` | rejects empty hook selection |
| Existing | `git-hooks` | rejects empty profile selection |
| Existing | `git-hooks` | rejects whitespace-only profile selection |
| Existing | `git-hooks` | rejects unknown profiles |
| Existing | `git-hooks` | rejects unknown profiles during check |
| Existing | `git-hooks` | rejects duplicate profiles |
