# `lib/checks/python/_env.sh`

## Scope

Private Python runner helper sourced by Python hook entrypoints.

## Behavior

- Supports `GIT_HOOK_PYTHON_RUNNER=auto`, `uv`, or `path`.
- Defaults to `auto`.
- `auto` uses `uv` only when `uv.lock` exists and `uv` is available.
- `auto` falls back to the active environment or `PATH` otherwise.
- `uv` runs tools through `uv run`.
- `path` runs tools directly from the active environment or `PATH`.
- `GIT_HOOK_PYTHON_UV_ARGS` defaults to `--frozen`.
- Missing tool checks use `uv run <tool> --version` in uv mode.
- Invalid runner values fail fast because they indicate hook policy mistakes.

## Public Functions

- `git_hooks_python_runner`
- `git_hooks_python_uv_args`
- `git_hooks_python_require_tool <check> <tool> <install-hint>`
- `git_hooks_python_run <tool> [args...]`

## Boundary

This file is private to Python checks and should be sourced directly. It is not
a dispatcher check ID and should not be added to a profile list.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/python/env_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | defaults to path runner without `uv.lock` |
| Existing | `git-hooks` | auto-selects uv when `uv.lock` and uv exist |
| Existing | `git-hooks` | rejects invalid runner value |
| Existing | `git-hooks` | reports missing tool in path mode |
| Existing | `git-hooks` | runs commands through uv with configured args |
