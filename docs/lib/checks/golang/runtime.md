# `lib/checks/golang/runtime.sh`

## Scope

Shared Go runtime helper for Golang checks that invoke the Go toolchain.

## Behavior

- Intended for internal use by Golang checks, not as a standalone check ID.
- Resolves `GOCACHE` and `GOTMPDIR` from the first source that sets them:
  `.githooks/hooks.env` or the parent environment, such as shell exports, then
  Go's own config file written by `go env -w`, then the repo-local defaults
  `$REPO/.cache/go-build` and `$REPO/.tmp/go`.
- Detects `go env -w` values with `go env -changed -json`, which needs Go 1.23
  or later. With older Go, or without `go` in `PATH`, the repo-local defaults
  apply.
- Leaves `go env -w` values to Go: the hook does not export or create them.
- Creates `GOCACHE` and `GOTMPDIR` when missing if they come from the hook
  environment or the repo-local defaults.
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
| Existing | `git-hooks` | leaves runtime directories set with `go env -w` to Go |
| Existing | `git-hooks` | keeps repo defaults when `go` cannot report changed settings |
| Existing | `git-hooks` | creates missing `GOCACHE` and `GOTMPDIR` |
| Existing | `git-hooks` | stays silent after successful creation in quiet mode |
| Existing | `git-hooks` | reports created paths in verbose mode |
| Existing | `git-hooks` | fails when a configured path is not a directory |
| Existing | `git-hooks` | detects tracked Go source files |
| Existing | `git-hooks` | detects untracked, non-ignored Go source files |
| Existing | `git-hooks` | ignores repos without Go source files |
