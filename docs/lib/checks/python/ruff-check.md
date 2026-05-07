# `lib/checks/python/ruff-check.sh`

## Scope

Python lint check for `pre-commit`.

## Behavior

- Intended for the opt-in `python` profile, not the common baseline.
- Uses the shared Python runner. `auto` mode prefers `uv run` when `uv.lock`
  exists and otherwise uses the active environment or `PATH`.
- Skips silently when no staged text Python files exist.
- Runs `ruff check --no-cache <file>` for each staged Python file so Ruff does
  not create `.ruff_cache` in the repository root.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `ruff` is unavailable in the selected runner.
- Returns the first non-zero `ruff` exit code and prints capped output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/python/ruff-check_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged Python files |
| Existing | `git-hooks` | skips staged binary Python files |
| Existing | `git-hooks` | skips with an install hint when `ruff` is missing |
| Existing | `git-hooks` | suppresses noisy successful output |
| Existing | `git-hooks` | returns status and prints output when lint fails |
| Existing | `git-hooks` | disables Ruff repo-root cache writes |
