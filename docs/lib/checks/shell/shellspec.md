# `lib/checks/shell/shellspec.sh`

## Scope

ShellSpec test check for `pre-push`.

## Behavior

- Intended for the opt-in `shell` profile, not the common baseline.
- Uses user-level `shellspec` from `PATH`.
- Discovers tracked `.shellspec` files anywhere in the repository.
- Runs `shellspec` once from each tracked `.shellspec` directory.
- Supports multiple ShellSpec project roots in one repository.
- Stops immediately when a ShellSpec run is interrupted instead of continuing to
  later ShellSpec roots.
- Unsets Git hook runtime variables before invoking project ShellSpec suites so
  nested hook tests do not inherit parent hook policy.
- Unsets Git local repository environment variables before invoking project
  ShellSpec suites so nested Git commands can discover their own test repos.
- Does not guess test roots from `*_spec.sh`; `.shellspec` is the explicit
  project marker.
- Skips silently when no tracked `.shellspec` files exist.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `shellspec` is unavailable.
- Returns the signal-style exit code when a ShellSpec child process is
  interrupted.
- Returns the first non-zero `shellspec` exit code.
- Reports the failed ShellSpec directory and capped diagnostics.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/shell/shellspec_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without tracked `.shellspec` files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | runs once per tracked ShellSpec directory |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports failed directory and capped output |
| Existing | `git-hooks` | does not leak hook runtime environment into suites |
| Existing | `git-hooks` | does not leak Git local repository environment into suites |
| Existing | `git-hooks` | stops after an interrupted ShellSpec root |
