# `lib/checks/golang/go-vet.sh`

## Scope

Go vet check for `pre-push`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `go` from `PATH`.
- Skips silently when neither `go.mod` nor `go.work` exists.
- Prepares configured Go runtime directories such as `GOCACHE` and `GOTMPDIR`
  before invoking `go`.
- Runs `go vet ./...`.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `go` is unavailable.
- Returns the `go vet` exit code and capped diagnostics on failure.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/go-vet_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports vet failure output |
