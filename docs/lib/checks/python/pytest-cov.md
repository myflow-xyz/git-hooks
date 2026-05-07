# `lib/checks/python/pytest-cov.sh`

## Scope

Python coverage check for explicit `pre-push` extra checks.

## Behavior

- Not included in the default `python` profile.
- Uses the shared Python runner. `auto` mode prefers `uv run` when `uv.lock`
  exists and otherwise uses the active environment or `PATH`.
- Requires `pytest` plus the `pytest-cov` plugin in the selected runner.
- Skips silently when no test files are detected.
- Runs `pytest -o cache_dir=<tmpdir> --cov=. --cov-report=term-missing:skip-covered`.
- Uses a temporary `COVERAGE_FILE` when one is not already set, avoiding a
  default `.coverage` file side effect in the repo root.
- Uses a temporary pytest cache directory so the hook does not create
  `.pytest_cache` in the repository root.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Lifecycle Decision

Coverage is intentionally extra, not default. Running both `pytest` and
`pytest-cov` would duplicate test execution, while replacing `pytest` with
coverage would make a missing coverage plugin skip the default test gate.

## Failure Modes

- Skips with an install hint when `pytest` or `pytest-cov` is unavailable in
  the selected runner.
- Returns the `pytest` exit code and prints capped output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/python/pytest-cov_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips when tests are missing |
| Existing | `git-hooks` | skips with an install hint when `pytest` is missing |
| Existing | `git-hooks` | skips when `pytest-cov` is missing |
| Existing | `git-hooks` | suppresses noisy successful output |
| Existing | `git-hooks` | prints output when coverage fails |
| Existing | `git-hooks` | redirects pytest cache outside the repository |
