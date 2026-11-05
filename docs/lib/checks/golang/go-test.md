# `lib/checks/golang/go-test.sh`

## Scope

Go test check for `pre-push`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `go` from `PATH`.
- Uses shared module selection; skips when no selected Go module exists.
- Skips silently when the repo has no tracked or untracked, non-ignored Go
  source files.
- Prepares Go runtime directories before invoking `go`: when neither the
  environment nor `go env -w` sets them, `GOCACHE` defaults to
  `$REPO/.cache/go-build` and `GOTMPDIR` defaults to `$REPO/.tmp/go`.
- Runs `go test -count=1 ./...` in each selected module. Test results are not
  reused; Go's build cache remains available.
- `GIT_HOOK_GO_TEST_SHORT=1` selects `go test -short -count=1 ./...`.
  The default is `0` (full tests). Other values fail with a configuration error.
- Keeps integration and E2E setup in project-owned hooks. Short mode only
  changes tests that honor `testing.Short()`.
- Stops on the first failing module and retains the original command status.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `go` is unavailable.
- Returns the `go test` exit code, capped diagnostics, and the location of the
  complete retained failure log. Successful runs remove their logs.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/go-test_spec.sh`
- Shared behavior regressions: `shellspec test/checks/golang/quality-gates_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips modules with no Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | does not leak Git local repository environment into go test |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports test failure output |
| Existing | `git-hooks` | always disables test-result caching and validates short mode |
| Existing | `git-hooks` | runs selected nested modules and stops on failure |
| Existing | `git-hooks` | retains diagnostics beyond the console output limit |
