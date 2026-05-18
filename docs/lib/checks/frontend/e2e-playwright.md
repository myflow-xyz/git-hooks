# `lib/checks/frontend/e2e-playwright.sh`

## Scope

React/Vite Playwright E2E check for `pre-push`.

## Behavior

- Intended for the opt-in `react-vite` profile, not the common baseline.
- Uses `pnpm` project dependencies through `pnpm exec`.
- Skips before requiring Playwright when the repo has no Playwright config and
  no tracked conventional E2E test files under `e2e/`, `tests/e2e/`, or
  `playwright/`.
- When E2E exists, requires the repo-local `node_modules/.bin/playwright`;
  global installs are not treated as valid for this hook.
- Runs `pnpm exec playwright test --pass-with-no-tests`, using Playwright's
  documented no-tests option instead of parsing command output.
- Captures output and keeps successful test runs silent unless
  `GIT_HOOK_VERBOSE=1`.
- Clears git-hooks runtime variables and Git local repository variables before
  invoking Playwright so project tests see a normal local-test environment.

## Failure Modes

- Skips with an install hint when `pnpm` is unavailable.
- Skips with visible info when repo-local `node_modules/.bin/playwright` is
  unavailable.
- Lets Playwright exit successfully when no tests are found via
  `--pass-with-no-tests`.
- Returns the Playwright exit code when tests fail and prints capped failure
  output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/frontend/e2e-playwright_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips when no E2E signal exists |
| Existing | `git-hooks` | skips when package config is missing |
| Existing | `git-hooks` | skips with an install hint when `pnpm` is missing |
| Existing | `git-hooks` | skips with repo-local bin info and install hint |
| Existing | `git-hooks` | suppresses noisy successful Playwright output |
| Existing | `git-hooks` | passes Playwright no-test handling through the official option |
| Existing | `git-hooks` | prints successful Playwright output in verbose mode |
| Existing | `git-hooks` | returns status and prints output when tests fail |
