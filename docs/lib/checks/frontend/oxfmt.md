# `lib/checks/frontend/oxfmt.sh`

## Scope

React/Vite frontend format check for `pre-commit`.

## Behavior

- Intended for the opt-in `react-vite` profile, not the common baseline.
- Uses `pnpm` project dependencies through `pnpm exec`.
- Requires the repo-local `node_modules/.bin/oxfmt`; global installs are not
  treated as valid for this hook.
- Skips silently when no staged text frontend source files exist.
- Skips binary staged frontend paths before deciding whether format is needed.
- Runs `pnpm exec oxfmt --check <staged-file>` for each staged text frontend
  source file, regardless of the file's directory.
- Captures output and keeps successful format checks silent unless
  `GIT_HOOK_VERBOSE=1`.

## Failure Modes

- Skips with an install hint when `pnpm` is unavailable.
- Skips when repo-local `node_modules/.bin/oxfmt` is unavailable.
- Returns the `oxfmt` exit code when format check fails and prints capped output.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/frontend/oxfmt_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged frontend source files |
| Existing | `git-hooks` | skips staged binary frontend source files |
| Existing | `git-hooks` | skips with an install hint when `pnpm` is missing |
| Existing | `git-hooks` | skips with repo-local bin install hint |
| Existing | `git-hooks` | suppresses noisy successful `oxfmt` output |
| Existing | `git-hooks` | reports format check failure output |
| Existing | `git-hooks` | formats staged files outside `src` |
