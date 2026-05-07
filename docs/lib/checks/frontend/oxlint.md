# `lib/checks/frontend/oxlint.sh`

## Scope

React/Vite frontend lint check for `pre-commit`.

## Behavior

- Intended for the opt-in `react-vite` profile, not the common baseline.
- Uses `pnpm` project dependencies through `pnpm exec`.
- Requires the repo-local `node_modules/.bin/oxlint`; global installs are not
  treated as valid for this hook.
- Skips silently when no staged text frontend source files exist.
- Skips binary staged frontend paths before deciding whether lint is needed.
- Runs `oxlint` with type-aware linting, unused-disable checks, and zero
  warnings for each staged text frontend source file.
- Captures output and keeps successful lint runs silent unless
  `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `pnpm` is unavailable.
- Skips when repo-local `node_modules/.bin/oxlint` is unavailable.
- Returns the `oxlint` exit code when lint fails and prints capped output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/frontend/oxlint_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged frontend source files |
| Existing | `git-hooks` | skips staged binary frontend source files |
| Existing | `git-hooks` | skips with an install hint when `pnpm` is missing |
| Existing | `git-hooks` | skips with repo-local bin install hint |
| Existing | `git-hooks` | suppresses noisy successful `oxlint` output |
| Existing | `git-hooks` | returns status and prints output when lint fails |
| Existing | `git-hooks` | lints only staged frontend files |
