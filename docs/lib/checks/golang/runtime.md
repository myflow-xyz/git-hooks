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
- Use absolute cache and temporary-directory paths so module changes use the
  same locations.
- Detects tracked and untracked, non-ignored `*.go` files for package-wide Go
  checks.
- Keeps successful directory preparation silent unless `GIT_HOOK_VERBOSE` is
  enabled.
- Selects tracked and untracked, non-ignored module manifests, excluding
  `vendor`, `testdata`, `.cache`, and `.tmp` directories. Removed working-tree
  manifests are ignored. A repository-root manifest need not be tracked yet.
- `GIT_HOOK_GO_MODULES` overrides discovery with root-relative module
  directories, one per line. Spaces are supported; newlines delimit entries.
  Absolute paths, parent traversal, and missing manifests are errors.
- Runs package checks separately in each selected module. Workspace-only roots
  are supported through their in-repository modules. External workspace members
  are not automatically added to the check scope.
- Skips package checks in modules without Go source, without skipping populated
  nested modules. Tidy still checks manifests in modules without Go source.
- Explicit module selection can include fixture directories. Repeated module
  paths do not repeat checks; paths that escape the source root are rejected.
- Go workspace and build settings remain project-owned. Package checks preserve
  ambient `GOFLAGS`, `GOWORK`, and `GOTOOLCHAIN`; verbose output identifies the
  selected module. Projects must supply settings that match their intended
  coverage. Hooks do not install quality tools.
- Uses NUL-delimited module and staged-file lists. Child failures stop iteration
  and retain their original status, including interrupt statuses.
- Captures quiet-mode output, displays up to 120 lines on failure, and retains
  the complete log in the system temporary directory. Success removes logs;
  other temporary state is always cleaned up.
- Pre-commit formatting reads index blobs. Fast lint uses the original checkout
  and a staged patch, after checking for unstaged and non-ignored untracked
  files. It does not relocate the workspace or its dependencies.

## Failure Modes

- Fails when a configured runtime path exists but is not a directory.
- Fails when `mkdir -p` cannot create a missing configured runtime path.

## Test Cases

Run only this helper's tests:

- `shellspec test/checks/golang/runtime_spec.sh`
- Shared behavior regressions: `shellspec test/checks/golang/quality-gates_spec.sh`

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
| Existing | `git-hooks` | discovers nested modules and excludes fixture/vendor modules |
| Existing | `git-hooks` | validates explicit module selection and handles spaces |
| Existing | `git-hooks` | preserves command failures across module iteration |
