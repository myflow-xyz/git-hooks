# `lib/checks/frontend/vitest.sh`

## Scope

React/Vite frontend test check for `pre-push`.

## Behavior

- Intended for the opt-in `react-vite` profile, not the common baseline.
- Uses `pnpm` project dependencies through `pnpm exec`.
- Requires the repo-local `node_modules/.bin/vitest`; global installs are not
  treated as valid for this hook.
- Runs `pnpm exec vitest run` so Git hooks never enter Vitest watch mode.
- Captures output and keeps successful test runs silent unless
  `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `pnpm` is unavailable.
- Skips when repo-local `node_modules/.bin/vitest` is unavailable.
- Returns the `vitest` exit code when tests fail and prints capped failure output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/frontend/vitest_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips when `package.json` is missing |
| Existing | `git-hooks` | skips with an install hint when `pnpm` is missing |
| Existing | `git-hooks` | skips with repo-local bin install hint |
| Existing | `git-hooks` | suppresses noisy successful `vitest run` output |
| Existing | `git-hooks` | returns status and prints output when tests fail |
