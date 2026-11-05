# `lib/checks/golang/go-vet.sh`

## Scope

Go vet check for `pre-push`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `go` from `PATH`.
- Uses shared module selection; skips when no selected Go module exists.
- Skips silently when the repo has no tracked or untracked, non-ignored Go
  source files.
- Prepares Go runtime directories before invoking `go`: when neither the
  environment nor `go env -w` sets them, `GOCACHE` defaults to
  `$REPO/.cache/go-build` and `GOTMPDIR` defaults to `$REPO/.tmp/go`.
- Runs `go vet ./...` in each selected module, with the default analyzer set.
- Native analyzers have documented limits and intentional exemptions. Vet does
  not replace tests on a project's minimum supported Go version.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `go` is unavailable.
- Returns the `go vet` exit code and capped diagnostics on failure. The complete captured log is
  retained and its path is printed.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/go-vet_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips modules with no Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports vet failure output |
