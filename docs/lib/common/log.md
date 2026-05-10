# `lib/common/log.sh`

## Scope

Consistent terminal output for Git hooks.

## Responsibilities

- Keep successful checks quiet by default.
- Print skip/progress messages only when `GIT_HOOK_VERBOSE` is `1` or `true`.
- Prefix runtime output with `GIT_HOOK_PHASE` when set, otherwise `git-hooks`.
- Treat `GIT_HOOK_VERBOSE=0`, `false`, unset, and unknown values as quiet mode.
- Parse `true` and `false` case-insensitively for portable hook env usage.
- Print short actionable errors with the failing check/path and reason.
- Keep output dense enough for humans and LLM agents to identify next action.
- Enforce quiet-by-default, failure-oriented, bounded-output behavior for check
  scripts.

## Public Functions

- `git_hooks_log_is_verbose`
- `git_hooks_log_prefix`
- `git_hooks_log_info <message>`
- `git_hooks_log_skip <message>`
- `git_hooks_log_error <message>`
- `git_hooks_log_warn <message>`
- `git_hooks_log_skip_missing_tool <check> <tool> <install-hint>`
- `git_hooks_log_check_start <check>`

## Boundary

Do not print large command output here. Checks that call noisy external tools
should capture tool output, suppress it on success, and replay only bounded
failure diagnostics.

## Test Cases

Run only this script's tests:

- `shellspec test/common/log_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | keeps info output silent by default |
| Existing | `git-hooks` | prints info output when verbose |
| Existing | `git-hooks` | uses the hook phase as the runtime log prefix |
| Existing | `git-hooks` | parses verbose env values robustly |
| Existing | `git-hooks` | prints skipped missing-tool warnings to stderr |
| Recommended | `git-hooks` | Cover skip output in quiet and verbose modes. |
| Recommended | `git-hooks` | Cover check-start quiet and verbose output. |
