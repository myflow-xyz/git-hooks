# `lib/checks/shell/shellcheck.sh`

## Scope

Staged shell static analysis check for `pre-commit`.

## Behavior

- Intended for the opt-in `shell` profile, not the common baseline.
- Uses user-level `shellcheck` from `PATH`.
- Checks staged text `.sh` and `.bash` files only.
- Skips `.zsh` files because ShellCheck does not support zsh syntax reliably.
- Skips `.sh` files with zsh shebangs for the same reason.
- Skips ShellSpec `*_spec.sh` files because ShellSpec DSL commands are not
  normal shell commands; `shell/shellspec` validates those files instead.
- Uses the staged shebang dialect when present.
- Falls back to `sh` for `.sh` and `bash` for `.bash` when no shebang exists.
- Runs with `--severity=warning` so informational source-following messages do
  not fail commits.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `shellcheck` is unavailable.
- Returns the `shellcheck` exit code and capped diagnostics on failure.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/shell/shellcheck_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged `.sh` or `.bash` files |
| Existing | `git-hooks` | skips staged `.zsh` files |
| Existing | `git-hooks` | skips `.sh` files with zsh shebangs |
| Existing | `git-hooks` | skips staged ShellSpec files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | uses `sh` for `.sh` files without shebang |
| Existing | `git-hooks` | uses `bash` for `.bash` files and bash shebangs |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | returns status and prints output on failure |
| Existing | `git-hooks` | skips staged binary shell files |
