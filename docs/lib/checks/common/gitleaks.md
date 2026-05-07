# `lib/checks/common/gitleaks.sh`

## Scope

Fast staged secret scan for `pre-commit`.

## Behavior

- Skips silently when there are no staged files.
- Skips with an install hint when `gitleaks` is unavailable.
- Runs `gitleaks protect --staged --redact`.
- Captures `gitleaks` output and keeps successful scans silent.
- Prints captured output only when `gitleaks` exits non-zero, capped at 120
  lines.
- When `GIT_HOOK_VERBOSE=1`, runs `gitleaks protect --staged --redact --verbose`
  directly and keeps native tool output.

## Failure Modes

- Returns the `gitleaks` exit code when secrets are detected or the tool fails.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/gitleaks_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged files |
| Existing | `git-hooks` | skips with missing-tool install hint |
| Existing | `git-hooks` | suppresses noisy successful `gitleaks` output |
| Existing | `git-hooks` | keeps `gitleaks` output in verbose mode |
| Existing | `git-hooks` | returns status and prints output on leaks |
