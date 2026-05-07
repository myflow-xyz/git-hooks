# `lib/checks/golang/go-mod-tidy.sh`

## Scope

Go module hygiene check for `pre-push`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `go` from `PATH`.
- Skips silently when repo root has no `go.mod`.
- Prepares configured Go runtime directories such as `GOCACHE` and `GOTMPDIR`
  before invoking `go`.
- Runs `go mod tidy -diff` so the hook reports required `go.mod` or `go.sum`
  changes without modifying files.
- Does not run from `go.work` alone because `go mod tidy` is module-scoped.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `go` is unavailable.
- Returns the `go mod tidy -diff` exit code and capped diagnostics on failure.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/go-mod-tidy_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports tidy diff failure output |
