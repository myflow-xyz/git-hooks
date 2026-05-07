# `lib/dispatcher/run-hook.sh`

## Scope

Phase dispatcher for repo-local Git hook wrappers.

## Responsibilities

- Validate the hook phase: `pre-commit`, `pre-push`, or `commit-msg`.
- Bootstrap runtime environment through `lib/common/env.sh`.
- Load profile phase lists such as `profiles/common/pre-commit.list`.
- Resolve check IDs through `lib/common/path.sh`.
- Run check entrypoints in order and stop on the first failure.
- Stop the whole hook chain immediately on `SIGHUP`, `SIGINT`, or `SIGTERM`.
- Pass Git hook arguments through to each check entrypoint.
- Run phase-specific extra checks from project config.
- Ignore blank and comment lines in profile lists.
- Reject unknown profiles from project config.
- Skip duplicate profiles with a warning so existing repo configs do not run the
  same profile twice.

## Non-Goals

- It should not contain Git query logic.
- It should not contain check-specific behavior.
- It should not print noisy success output unless verbose logging is enabled.

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
| Existing | `git-hooks` | runs extra checks after profile checks |
| Existing | `git-hooks` | stops on the first failing check |
| Existing | `git-hooks` | stops immediately when interrupted |
| Existing | `git-hooks` | passes when the selected phase list is missing |
| Existing | `git-hooks` | fails when a check exists but is not executable |
| Existing | `git-hooks` | rejects unknown phases before loading runtime files |
