# `lib/checks/golang/goimports.sh`

## Scope

Staged Go import formatting check for `pre-commit`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `goimports` from `PATH`.
- Skips silently when no staged text `.go` files exist.
- Skips binary staged Go paths before deciding whether formatting is needed.
- Prepares Go runtime directories before invoking `goimports`: unset `GOCACHE`
  defaults to `$REPO/.cache/go-build`, and unset `GOTMPDIR` defaults to
  `$REPO/.tmp/go`.
- Runs `goimports -l` against staged Go file paths.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `goimports` is unavailable.
- Fails when `goimports -l` reports files that need formatting.
- Returns the `goimports` exit code when the tool itself fails.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/goimports_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | fails when files need import formatting |
| Existing | `git-hooks` | skips staged binary Go files |
