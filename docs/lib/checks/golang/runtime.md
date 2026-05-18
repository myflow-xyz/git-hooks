# `lib/checks/golang/runtime.sh`

## Scope

Shared Go runtime helper for Golang checks that invoke the Go toolchain.

## Behavior

- Intended for internal use by Golang checks, not as a standalone check ID.
- Defaults unset `GOCACHE` to `$REPO/.cache/go-build`.
- Defaults unset `GOTMPDIR` to `$REPO/.tmp/go`.
- Creates `GOCACHE` and `GOTMPDIR` when missing.
- Preserves values loaded from `.githooks/hooks.env` or the parent environment.
- Defaults unset `GOLANGCI_LINT_CACHE` to `$REPO/.cache/golangci-lint` only when
  a golangci-lint check calls lint runtime preparation.
- Creates `GOLANGCI_LINT_CACHE` only for golangci-lint checks.
- Detects tracked and untracked, non-ignored `*.go` files for package-wide Go
  checks.
- Keeps successful directory preparation silent unless `GIT_HOOK_VERBOSE` is
  enabled.

## Failure Modes

- Fails when a configured runtime path exists but is not a directory.
- Fails when `mkdir -p` cannot create a missing configured runtime path.

## Test Cases

Run only this helper's tests:

- `shellspec test/checks/golang/runtime_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | defaults unset Go runtime directories under the repo root |
| Existing | `git-hooks` | defaults unset golangci-lint cache only through lint runtime preparation |
| Existing | `git-hooks` | creates missing `GOCACHE` and `GOTMPDIR` |
| Existing | `git-hooks` | stays silent after successful creation in quiet mode |
| Existing | `git-hooks` | reports created paths in verbose mode |
| Existing | `git-hooks` | fails when a configured path is not a directory |
| Existing | `git-hooks` | detects tracked Go source files |
| Existing | `git-hooks` | detects untracked, non-ignored Go source files |
| Existing | `git-hooks` | ignores repos without Go source files |
