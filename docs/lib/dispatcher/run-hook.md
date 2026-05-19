# `lib/dispatcher/run-hook.sh`

## Scope

Phase dispatcher for repo-local Git hook wrappers.

## Responsibilities

- Validate the hook phase: `pre-commit`, `pre-push`, or `commit-msg`.
- Bootstrap runtime environment through `lib/common/env.sh`.
- Export `GIT_HOOK_PHASE` so runtime logs identify the selected hook phase.
- Load profile phase lists such as `profiles/common/pre-commit.list`.
- Resolve check IDs through `lib/common/path.sh`.
- Run check entrypoints in order and stop on the first failure.
- Stop the whole hook chain immediately on `SIGHUP`, `SIGINT`, or `SIGTERM`.
- Snapshot the index at `pre-commit` entry and restore that snapshot when the
  hook fails or is interrupted.
- Pass Git hook arguments through to each check entrypoint.
- Run phase-specific extra checks from project config.
- Run phase-specific local extra hooks from project config after builtin extra
  checks.
- Warn and skip missing local extra hook files.
- Capture local extra hook output, replay bounded output on failure, and print a
  consistent local hook failure line.
- Ignore blank and comment lines in profile lists.
- Reject unknown profiles from project config.
- Skip duplicate profiles with a warning so existing repo configs do not run the
  same profile twice.

## Non-Goals

- It should not contain Git query logic.
- It should not contain check-specific behavior.
- It should not print noisy success output unless verbose logging is enabled.
- It cannot restore the index state that existed before Git itself changed the
  index. For example, `git commit -a` and `git commit --all` stage modified and
  deleted tracked files before `pre-commit` starts, so the guard preserves only
  the hook-entry state.

## Index Safety

`pre-commit` records the exact index file at dispatcher entry. If a check
fails, exits with interrupt status, or the hook receives `SIGHUP`, `SIGINT`, or
`SIGTERM`, the dispatcher restores that snapshot before exiting.

This protects the user's staged selection from hook-side index changes. It does
not make `git commit -a` safe for partial staging because Git has already staged
modified and deleted tracked files before invoking `pre-commit`.

## Typical Usage

```sh
$XDG_CONFIG_HOME/git-hooks/lib/dispatcher/run-hook.sh pre-commit "$@"
```

## Test Cases

Run only this script's tests:

- `shellspec test/dispatcher/run-hook_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | runs profile checks through the dispatcher |
| Existing | `git-hooks` | reports unresolved check IDs |
| Existing | `git-hooks` | passes Git hook arguments to checks |
| Existing | `git-hooks` | uses default common profile without project config |
| Existing | `git-hooks` | ignores blank and comment lines in profile lists |
| Existing | `git-hooks` | runs multiple profiles in declared order |
| Existing | `git-hooks` | skips duplicate profiles with a warning |
| Existing | `git-hooks` | rejects unknown profiles from project config |
| Existing | `git-hooks` | runs python profile checks |
| Existing | `git-hooks` | runs pmem reference footer profile checks |
| Existing | `git-hooks` | runs extra checks after profile checks |
| Existing | `git-hooks` | runs direct local extra hooks |
| Existing | `git-hooks` | runs nested local extra hooks with hook args |
| Existing | `git-hooks` | warns and skips missing local extra hooks |
| Existing | `git-hooks` | fails when local extra hooks are not executable |
| Existing | `git-hooks` | replays failed local hook output and stops |
| Existing | `git-hooks` | stops on the first failing check |
| Existing | `git-hooks` | restores pre-commit index after check failure |
| Existing | `git-hooks` | restores pre-commit index after interrupt status |
| Existing | `git-hooks` | stops immediately when interrupted |
| Existing | `git-hooks` | passes when the selected phase list is missing |
| Existing | `git-hooks` | fails when a check exists but is not executable |
| Existing | `git-hooks` | rejects unknown phases before loading runtime files |
