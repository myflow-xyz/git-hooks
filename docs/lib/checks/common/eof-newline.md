# `lib/checks/common/eof-newline.sh`

## Scope

Staged text-file trailing newline check for `pre-commit`.

## Behavior

- Skips silently when there are no staged files.
- Applies to staged added, copied, modified, and renamed files that Git classifies
  as text.
- Is not extension-limited. JSON files are included because a final newline is
  valid trailing JSON whitespace; it is not required for JSON parsing, but the
  common profile treats it as repository text-file hygiene.
- Ignores binary staged files, empty staged files, staged deletions, unstaged
  files, and untracked files.
- Reads file content from the Git index, not the working tree.
- Reports each staged text file that does not end with `\n`.

## Failure Modes

- Returns `1` when at least one staged text file is missing a trailing newline.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/eof-newline_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | passes when staged text files end with newline |
| Existing | `git-hooks` | fails when a staged text file misses trailing newline |
| Existing | `git-hooks` | fails when a staged JSON file misses trailing newline |
| Existing | `git-hooks` | skips staged binary files |
| Existing | `git-hooks` | skips empty staged files |
| Existing | `git-hooks` | skips staged deletions |
| Recommended | `git-hooks` | Cover unstaged and untracked files are ignored. |
| Recommended | `git-hooks` | Cover staged content is used even when the working tree differs. |
