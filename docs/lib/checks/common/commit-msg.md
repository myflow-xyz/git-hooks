# `lib/checks/common/commit-msg.sh`

## Scope

Commit message subject validation for `commit-msg`.

## Behavior

- Reads the commit message file passed by Git as the first hook argument.
- Validates only the first line as the commit subject.
- Requires conventional commit format with a mandatory scope:
  `<type>(scope): brief description`
- Allows optional body and footer lines after the subject.
- Supports breaking-change marker before the colon:
  `<type>(scope)!: brief description`

Allowed types:

- `feat`
- `fix`
- `docs`
- `style`
- `refactor`
- `perf`
- `test`
- `build`
- `ci`
- `chore`
- `revert`

## Failure Modes

- Returns `2` when the commit message file argument is missing.
- Returns `1` when the commit message file does not exist.
- Returns `1` when the subject type, scope, colon separator, or brief
  description is invalid.
- Invalid subject output uses a `commit-msg` phase prefix, one cause-bearing
  error line, and one expected-format info line.

## Future Tracking

Issue or ticket IDs may become required later. Prefer adding this as a
project-configurable option, for example `GIT_HOOK_COMMIT_MSG_REQUIRE_ISSUE=1`,
instead of hardcoding it into every project.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/commit-msg_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | passes conventional commit subject with mandatory scope |
| Existing | `git-hooks` | fails when scope is missing |
| Existing | `git-hooks` | fails when type is unknown |
| Existing | `git-hooks` | fails when brief description is empty |
| Existing | `git-hooks` | rejects missing commit message file argument |
| Recommended | `git-hooks` | Cover optional issue or ticket ID enforcement when the config option exists. |
