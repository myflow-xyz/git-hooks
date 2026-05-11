# `lib/checks/common/whitespace.sh`

## Scope

Fast staged whitespace check for `pre-commit`.

## Behavior

- Skips silently when there are no staged files.
- Runs `git diff --cached --check`.
- Relies on Git diff behavior so binary files are not treated as text
  whitespace failures.

## Failure Modes

- Returns Git's non-zero status when whitespace errors are found.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/whitespace_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | passes when staged files have no whitespace errors |
| Existing | `git-hooks` | fails on staged whitespace errors |
| Existing | `git-hooks` | passes with staged binary files |
| Recommended | `git-hooks` | Cover skip behavior when there are no staged files. |
| Recommended | `git-hooks` | Cover whitespace checks use staged content rather than unstaged working tree changes. |
