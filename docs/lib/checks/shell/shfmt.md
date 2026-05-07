# `lib/checks/shell/shfmt.sh`

## Scope

Staged shell formatting check for `pre-commit`.

## Behavior

- Intended for the opt-in `shell` profile, not the common baseline.
- Uses user-level `shfmt` from `PATH`.
- Checks staged text `.sh` and `.bash` files only.
- Skips `.zsh` files because this profile keeps zsh handling conservative.
- Skips ShellSpec `*_spec.sh` files because `shfmt` damages ShellSpec DSL
  readability; `shell/shellspec` validates those files instead.
- Skips silently when no staged `.sh` or `.bash` files exist.
- Runs `shfmt -l <file>` for each staged file.
- Treats listed files as formatting failures.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `shfmt` is unavailable.
- Fails when `shfmt -l` reports files that need formatting.
- Returns the `shfmt` exit code when the tool itself fails.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/shell/shfmt_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged `.sh` or `.bash` files |
| Existing | `git-hooks` | skips staged `.zsh` files |
| Existing | `git-hooks` | skips staged ShellSpec files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | fails when files need formatting |
| Existing | `git-hooks` | skips staged binary shell files |
