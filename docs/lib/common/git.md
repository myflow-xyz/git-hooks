# `lib/common/git.sh`

## Scope

Centralized Git query helpers for dispatcher and checks.

## Responsibilities

- Resolve repository root and current branch.
- List staged files using one consistent diff filter.
- Filter staged files by extension.
- Identify binary staged files.
- Filter staged text files by extension for checks that must skip binary paths.
- Read staged file content from the index.
- Inspect tracked files and changed paths.

## Public Functions

- `git_hooks_git_repo_root`
- `git_hooks_git_current_branch`
- `git_hooks_git_staged_files`
- `git_hooks_git_has_staged_files`
- `git_hooks_git_staged_files_by_extension <extension...>`
- `git_hooks_git_staged_text_files_by_extension <extension...>`
- `git_hooks_git_is_staged_binary <path>`
- `git_hooks_git_show_staged_file <path>`
- `git_hooks_git_tracked_files`
- `git_hooks_git_changed_paths [diff-args...]`

## Boundary

Checks should call these helpers instead of embedding raw `git diff`, `git show`,
or `git ls-files` queries.

## Test Cases

Run only this script's tests:

- `shellspec test/common/git_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | filters staged files by extension |
| Existing | `git-hooks` | skips binary staged files |
| Existing | `git-hooks` | detects when staged files exist |
| Existing | `git-hooks` | reads staged content from the index |
| Existing | `git-hooks` | detects binary staged files. |
| Recommended | `git-hooks` | Cover branch, tracked file, and diff queries. |
