# `lib/checks/python/pip-audit.sh`

## Scope

Python dependency vulnerability audit for explicit extra checks.

## Behavior

- Not included in the default `python` profile.
- Uses the shared Python runner. `auto` mode prefers `uv run` when `uv.lock`
  exists and otherwise uses the active environment or `PATH`.
- Audits `pyproject.toml` projects with `pip-audit .`.
- Falls back to `pip-audit -r requirements.txt` when only `requirements.txt`
  exists.
- Disables the progress spinner for concise hook output.
- Captures output and keeps successful runs silent unless `GIT_HOOK_VERBOSE=1`.

## Lifecycle Decision

`pip-audit` can perform Python dependency resolution and overlaps the default
cross-ecosystem OSV scan. It remains explicit-only for projects that want both
checks.

## Failure Modes

- Skips when dependency manifests are missing.
- Skips with an install hint when `pip-audit` is unavailable in the selected
  runner.
- Returns the `pip-audit` exit code and prints capped output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/python/pip-audit_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips when dependency manifests are missing |
| Existing | `git-hooks` | skips when `pip-audit` is missing |
| Existing | `git-hooks` | audits `pyproject.toml` project path |
| Existing | `git-hooks` | audits `requirements.txt` with `-r` |
| Existing | `git-hooks` | returns status and prints output when audit fails |
