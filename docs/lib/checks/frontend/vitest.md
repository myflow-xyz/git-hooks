# `lib/checks/frontend/vitest.sh`

## Scope

React/Vite frontend test check for `pre-push`.

## Behavior

- Intended for the opt-in `react-vite` profile, not the common baseline.
- Uses `pnpm` project dependencies through `pnpm exec`.
- Requires the repo-local `node_modules/.bin/vitest`; global installs are not
  treated as valid for this hook.
- Runs `pnpm exec vitest run` so Git hooks never enter Vitest watch mode.
- Skips when Vitest reports no test files.
- Clears git-hooks runtime variables and Git local repository variables before
  invoking Vitest so project tests see a normal local-test environment.
- Captures output and keeps successful test runs silent unless
  `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `pnpm` is unavailable.
- Skips when repo-local `node_modules/.bin/vitest` is unavailable.
- Skips when Vitest exits `1` because no test files were found.
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
| Existing | `git-hooks` | skips when Vitest reports no test files |
| Existing | `git-hooks` | skips verbosely when Vitest reports no test files |
| Existing | `git-hooks` | does not leak Git local repository environment into Vitest |
| Existing | `git-hooks` | returns status and prints output when tests fail |
