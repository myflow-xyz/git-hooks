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
- Report staged, unstaged, and non-ignored untracked changes for the push guard.

## Public Functions

- `git_hooks_git_repo_root`
- `git_hooks_git_current_branch`
- `git_hooks_git_staged_files`
- `git_hooks_git_staged_files_z [extension...]`
- `git_hooks_git_has_staged_files`
- `git_hooks_git_staged_files_by_extension <extension...>`
- `git_hooks_git_staged_text_files_by_extension <extension...>`
- `git_hooks_git_is_staged_binary <path>`
- `git_hooks_git_show_staged_file <path>`
- `git_hooks_git_tracked_files`
- `git_hooks_git_changed_paths [diff-args...]`
- `git_hooks_git_worktree_status`

## Boundary

Checks should call these helpers instead of embedding raw `git diff`, `git show`,
or `git ls-files` queries.

The NUL-delimited helper preserves unusual filenames. Do not capture its output
in a shell variable. Existing newline-delimited helpers remain for callers that
use their original interface. Discovery and index-read errors must remain
nonzero; they are not empty change sets. Single-path queries use literal Git
pathspecs.

The worktree-status helper emits Git porcelain v1 status for the whole repository,
including all non-ignored untracked files and dirty submodules. Empty successful
output means clean. Git errors remain nonzero. Optional index refresh writes are
disabled, and Git quotes unusual filenames for safe diagnostic display.

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
| Existing | `git-hooks` | preserves discovery errors through extension filtering |
| Existing | `git-hooks` | preserves whitespace, Unicode, and special characters in NUL output |
| Recommended | `git-hooks` | Cover branch, tracked file, and diff queries. |
