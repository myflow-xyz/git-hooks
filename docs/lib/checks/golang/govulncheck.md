# `lib/checks/golang/govulncheck.sh`

## Scope

Go vulnerability advisory check for `pre-push`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `govulncheck` from `PATH`.
- Skips silently when neither `go.mod` nor `go.work` exists.
- Skips silently when the repo has no tracked or untracked, non-ignored Go
  source files.
- Prepares Go runtime directories before invoking `govulncheck`: unset
  `GOCACHE` defaults to `$REPO/.cache/go-build`, and unset `GOTMPDIR`
  defaults to `$REPO/.tmp/go`.
- Runs `govulncheck ./...`.
- Runs after `go mod tidy -diff` in the `golang` profile so advisory analysis
  sees current `go.mod` and `go.sum` state.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment. It prints the command, streams native `govulncheck` output, and
  reports the returned exit status on failure.

## Failure Modes

- Skips with an install hint when `govulncheck` is unavailable:
  `go install golang.org/x/vuln/cmd/govulncheck@latest`.
- Returns the `govulncheck` exit code and capped diagnostics on failure.

## Related Checks

- `go-mod-tidy.sh` runs first in the `golang` `pre-push` profile.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/govulncheck_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips modules with no Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | streams native output in verbose mode |
| Existing | `git-hooks` | reports failure output and tool exit code |
