# `lib/checks/common/eol-lf.sh`

## Scope

Staged text-file LF end-of-line check for `pre-commit`.

## Behavior

- Skips silently when there are no staged files.
- Applies to staged added, copied, modified, and renamed files that Git
  classifies as text.
- Reads file content from the Git index, not the working tree.
- Ignores binary staged files, staged deletions, unstaged files, and untracked
  files.
- Fails when staged text content contains a carriage return byte (`\r`), which
  catches CRLF and CR-only line endings.
- Complements `.gitattributes`; `.gitattributes` controls checkout behavior,
  while this hook prevents non-LF staged text from entering the repo.

## Failure Modes

- Returns `1` when at least one staged text file contains CR bytes.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/eol-lf_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | passes when staged text files use LF |
| Existing | `git-hooks` | fails when a staged text file uses CRLF |
| Existing | `git-hooks` | fails when a staged text file uses CR-only endings |
| Existing | `git-hooks` | uses staged content when the working tree differs |
| Existing | `git-hooks` | skips staged binary files with CR bytes |
| Recommended | `git-hooks` | Cover staged deletions are ignored. |
