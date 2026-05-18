# `lib/checks/golang/go-test.sh`

## Scope

Go test check for `pre-push`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `go` from `PATH`.
- Skips silently when neither `go.mod` nor `go.work` exists.
- Skips silently when the repo has no tracked or untracked, non-ignored Go
  source files.
- Prepares Go runtime directories before invoking `go`: unset `GOCACHE`
  defaults to `$REPO/.cache/go-build`, and unset `GOTMPDIR` defaults to
  `$REPO/.tmp/go`.
- Runs `go test ./...`.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `go` is unavailable.
- Returns the `go test` exit code and capped diagnostics on failure.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/go-test_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips modules with no Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports test failure output |
