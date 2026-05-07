# `lib/checks/python/pytest.sh`

## Scope

Python test check for `pre-push`.

## Behavior

- Intended for the opt-in `python` profile, not the common baseline.
- Uses the shared Python runner. `auto` mode prefers `uv run` when `uv.lock`
  exists and otherwise uses the active environment or `PATH`.
- Skips silently when no test files are detected.
- Runs `pytest -o cache_dir=<tmpdir>`.
- Uses a temporary pytest cache directory so the hook does not create
  `.pytest_cache` in the repository root.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `pytest` is unavailable in the selected runner.
- Returns the `pytest` exit code and prints capped output.

## Related Checks

- `pytest-cov.sh` runs pytest with coverage and is available as an explicit
  extra pre-push check when a project wants local coverage gating.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/python/pytest_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips when tests are missing |
| Existing | `git-hooks` | skips with an install hint when `pytest` is missing |
| Existing | `git-hooks` | suppresses noisy successful output |
| Existing | `git-hooks` | returns status and prints output when tests fail |
| Existing | `git-hooks` | redirects pytest cache outside the repository |
