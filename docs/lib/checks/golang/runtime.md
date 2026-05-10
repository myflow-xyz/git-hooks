# `lib/checks/golang/runtime.sh`

## Scope

Shared Go runtime helper for Golang checks that invoke the Go toolchain.

## Behavior

- Intended for internal use by Golang checks, not as a standalone check ID.
- Creates `GOCACHE` when it is set and missing.
- Creates `GOTMPDIR` when it is set and missing.
- Does not invent Go runtime locations when those variables are unset.
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
| Existing | `git-hooks` | creates missing `GOCACHE` and `GOTMPDIR` |
| Existing | `git-hooks` | stays silent after successful creation in quiet mode |
| Existing | `git-hooks` | reports created paths in verbose mode |
| Existing | `git-hooks` | fails when a configured path is not a directory |
| Existing | `git-hooks` | detects tracked Go source files |
| Existing | `git-hooks` | detects untracked, non-ignored Go source files |
| Existing | `git-hooks` | ignores repos without Go source files |
