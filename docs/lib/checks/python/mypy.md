# `lib/checks/python/mypy.sh`

## Scope

Python type check for `pre-push`.

## Behavior

- Intended for the opt-in `python` profile, not the common baseline.
- Uses the shared Python runner. `auto` mode prefers `uv run` when `uv.lock`
  exists and otherwise uses the active environment or `PATH`.
- Skips silently when Python project files are missing.
- Runs `mypy --cache-dir <tmpdir> .` across the repository.
- Uses a temporary mypy cache directory so the hook does not create
  `.mypy_cache` in the repository root.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Lifecycle Decision

Mypy does not have a stable generic fast mode that is correct across projects.
Running it against only staged files can miss package-level errors, so the
default profile keeps mypy in `pre-push`.

## Failure Modes

- Skips with an install hint when `mypy` is unavailable in the selected runner.
- Returns the `mypy` exit code and prints capped output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/python/mypy_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Python projects |
| Existing | `git-hooks` | skips with an install hint when `mypy` is missing |
| Existing | `git-hooks` | suppresses noisy successful output |
| Existing | `git-hooks` | returns status and prints output when mypy fails |
| Existing | `git-hooks` | redirects mypy cache outside the repository |
