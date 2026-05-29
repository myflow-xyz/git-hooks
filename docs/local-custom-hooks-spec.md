# Repo-Local Custom Hooks Spec

Status: draft.

## Goal

Allow a target repository to run repo-owned custom hook scripts without adding
one-off checks to the shared `git-hooks` runtime.

The motivating case is a repo that wants:

```text
$REPO/.githooks/hooks/dir/xhook.sh
$REPO/.githooks/hooks/yhook.sh
```

and wants to attach those scripts to a Git hook phase through repo-local hook
policy.

## Current Architecture

- Target repos use `core.hooksPath=.githooks`.
- Repo-local `.githooks/{pre-commit,pre-push,commit-msg}` wrappers stay tiny
  and call the shared dispatcher.
- The dispatcher loads shared runtime helpers, repo-local
  `.githooks/hooks.env`, then repo-local `.githooks/project.conf`.
- `GIT_HOOK_PROFILES` selects built-in shared profiles under
  `$GIT_HOOKS_HOME/profiles/<profile>/<phase>.list`.
- Profile lists and extra-check variables contain builtin check IDs, not script
  paths.
- Check IDs currently resolve to shared scripts under
  `$GIT_HOOKS_HOME/lib/checks/<id>.sh`, unless the value is an absolute path.
- `GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS`, `GIT_HOOK_PRE_PUSH_EXTRA_CHECKS`, and
  `GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS` already append phase-specific checks after
  selected profiles.
- There is no first-class repo-local hook ID space under `.githooks/hooks`.

That model is good for shared reusable checks, but it leaves repo-specific
hooks with poor options:

- Put one-off logic in the shared runtime, which widens maintenance scope.
- Use an absolute path in an extra-check variable, which is not portable across
  clones or users.
- Try a relative `.githooks/hooks/...` path, which currently resolves under the
  shared `lib/checks` tree instead of the repo.

## Requirement

Support repo-local custom hook scripts as first-class local extra hooks.

The feature should let a repo declare:

```sh
GIT_HOOK_PROFILES="common"
GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS="dir/xhook yhook"
```

and have the dispatcher execute:

```text
$REPO/.githooks/hooks/dir/xhook.sh
$REPO/.githooks/hooks/yhook.sh
```

for `pre-commit`, after the selected profile checks and before the dispatcher
exits successfully.

The caller remains unchanged:

```text
.githooks/<phase> wrapper
  -> $GIT_HOOKS_HOME/lib/dispatcher/run-hook.sh <phase> "$@"
  -> profile checks
  -> builtin extra hooks
  -> local extra hooks
```

Wrapper templates do not change. Local hook selection is dispatcher behavior
driven by `.githooks/project.conf`.

## Proposed Contract

Use `.githooks/hooks` as the repo-local hook root. Local hook IDs are relative
paths under that root, without a `.sh` suffix.

Mapping:

| Local hook ID | Script path |
| --- | --- |
| `yhook` | `$REPO/.githooks/hooks/yhook.sh` |
| `dir/xhook` | `$REPO/.githooks/hooks/dir/xhook.sh` |

## Extra Hook Sources

Extra hooks have an explicit source:

| Source | Config | Resolver |
| --- | --- | --- |
| `BUILTIN` | `GIT_HOOK_*_EXTRA_CHECKS` | `$GIT_HOOKS_HOME/lib/checks/<id>.sh` |
| `LOCAL` | `GIT_HOOK_*_EXTRA_LOCAL_HOOKS` | `$REPO/.githooks/hooks/<id>.sh` |

`GIT_HOOK_*_EXTRA_CHECKS` keeps its existing name for compatibility, but in the
selection model it means builtin extra hooks. Local extra hooks use separate
phase-specific env defaults:

```sh
GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS=${GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS:-}
GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS=${GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS:-}
GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS=${GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS:-}
```

Profiles remain builtin-only. A profile phase list can select builtin shared
checks, but it cannot select local repo scripts directly.

Rules:

- Register local custom hooks through phase-specific local hook variables in
  `.githooks/project.conf`.
- Keep `GIT_HOOK_PROFILES` limited to built-in shared profiles.
- Keep `GIT_HOOK_*_EXTRA_CHECKS` limited to shared runtime check IDs and
  absolute compatibility paths.
- Do not introduce repo-local profiles in this slice.
- Do not use a `local/` prefix. `dir/xhook` means
  `.githooks/hooks/dir/xhook.sh`.
- Require local hook scripts to be regular executable files.
- Run local hooks with the same dispatcher behavior as shared checks: same
  working directory, same Git hook arguments, same stop-on-first-failure rule.
- Keep the current shared-check execution order, then append local hooks:
  selected profiles first, shared phase-specific extras second, local hooks
  third.
- Continue to accept blank and comment lines in shared profile lists;
  extra-check and local-hook variables remain shell word lists.
- Keep duplicate check IDs runnable. The dispatcher should not de-duplicate
  local or shared checks.
- Warn and skip missing local hook files so stale local references do not block
  the hook chain.
- Treat existing non-file or non-executable local hook paths as failures because
  the repo policy points at a script that cannot run.
- Do not let local hooks shadow shared checks. The dispatcher should resolve
  shared check lists and local hook lists through separate path functions.
- Wrap local hook execution in the dispatcher. Capture output, replay bounded
  output on failure, and print a consistent failure line with the local hook ID
  and exit status.

Recommended repo layout:

```text
.githooks/
  pre-commit
  pre-push
  commit-msg
  project.conf
  hooks/
    dir/
      xhook.sh
    yhook.sh
```

Recommended config:

```sh
GIT_HOOK_PROFILES="common"
GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS="dir/xhook yhook"
```

## Local Hook Script Contract

Local hooks are executed as scripts, not sourced into the dispatcher shell.
They run from the repository root and receive the same Git hook arguments as
builtin checks for the active phase.

Must:

- Live under `.githooks/hooks` and be selected by suffixless local hook ID.
- Be a regular executable script with a valid interpreter line.
- Exit `0` when the local hook passes.
- Exit non-zero when the local hook fails.
- Preserve signal-like child statuses when possible. If a child exits `130`,
  the local hook should exit `130` instead of continuing to later work.
- Avoid interactive prompts because Git hooks may run from terminals, IDEs,
  and agents.
- Keep successful output quiet or very small. Failure output should name the
  failed local hook, reason, affected path when known, and next action.

Optional:

- Source shared `env.sh` to use `git_hooks_log_*` helpers and repo discovery.
- Honor `GIT_HOOK_VERBOSE=1` for progress output. Silent local hooks do not
  need explicit verbose handling.
- Use `git_hooks_env_run_project_command` for project-owned tools unless the
  local hook intentionally needs hook Git state such as staged content.
- Use repo-local `.githooks/hooks.env` for machine-local command paths or
  tunables.

Dispatcher protection:

- Missing selected local hook files warn and skip.
- Existing non-file or non-executable local hook paths fail before execution.
- Successful local hook output is suppressed unless verbose mode is enabled.
- Failed local hook output is replayed with a bounded line cap, followed by a
  dispatcher error line.

Minimum script:

```sh
#!/usr/bin/env sh
set -u

printf '%s\n' 'custom check failed' >&2
exit 1
```

If a local hook wants shared logging, path, Git, or project-command helpers, it
should source the shared env helper the same way shared checks do:

```sh
#!/usr/bin/env sh
set -u

git_hooks_common_dir=${GIT_HOOKS_COMMON_DIR:-${GIT_HOOKS_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/git-hooks}/lib/common}
. "$git_hooks_common_dir/env.sh" || exit $?
git_hooks_env_bootstrap_check || exit $?

git_hooks_log_info 'running dir/xhook'
```

Local hooks that invoke project-owned tools should use
`git_hooks_env_run_project_command` unless they intentionally inspect hook Git
state such as staged content or the hook index.

## Validation And Safety

The local hook resolver should reject path escapes and ambiguous IDs.

Reject:

- empty IDs
- `/xhook`
- `../xhook`
- `dir/../xhook`
- `dir/./xhook`
- `dir//xhook`
- `dir/xhook/`
- `dir/xhook.sh`

Local hook IDs are intentionally suffixless. The resolver appends `.sh` after
validation so `dir/xhook` has exactly one canonical script path.

This feature is repo-local, not machine-private. If `.githooks/project.conf` is
tracked and references `dir/xhook`, the matching script should also be
available to contributors. Private per-machine hooks need a separate design
because tracked project policy that references untracked local files will fail
for other users.

## Non-Goals

- Do not add repo-local profile directories under `.githooks/profiles`.
- Do not let local hooks override shared check IDs.
- Do not search arbitrary repo paths for hook scripts.
- Do not add local hooks to built-in shared profile lists.
- Do not make `setup-repo-hooks.sh` create local hook scripts.
- Do not change wrapper templates beyond what is needed for dispatcher support.

## Implementation Plan

1. Add a repo-local hook path helper that maps `<id>` to
   `$GIT_HOOK_PROJECT_DIR/hooks/<id>.sh`.
2. Add validation for local IDs before joining paths.
3. Add phase-specific env defaults for
   `GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS`,
   `GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS`, and
   `GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS`.
4. Teach the dispatcher to select the local hook list for the active phase and
   run it after shared phase-specific extra checks.
5. Keep shared check resolution unchanged for profiles and
   `GIT_HOOK_*_EXTRA_CHECKS`.
6. Update dispatcher, path, setup, and README docs with one concise example.
7. Add ShellSpec coverage for local hook resolution and runtime dispatch.

## Test Plan

Path helper tests:

- Resolves `yhook` to `.githooks/hooks/yhook.sh`.
- Resolves nested `dir/xhook` to `.githooks/hooks/dir/xhook.sh`.
- Rejects path escapes and empty local IDs.
- Leaves shared IDs such as `common/whitespace` resolving under shared
  `lib/checks`.
- Leaves absolute path behavior unchanged.

Dispatcher tests:

- Runs `dir/xhook` from `GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS` after profile
  checks.
- Passes Git hook arguments through to a local `commit-msg` extra check.
- Warns and skips when the local hook is missing.
- Fails when the local hook exists but is not executable.
- Fails when the local hook path exists but is not a regular file.
- Replays failed local hook output with a dispatcher failure line.
- Stops before later extras when a local hook fails.
- Does not let `.githooks/hooks/common/whitespace.sh` shadow
  `GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS="common/whitespace"`.

Documentation checks:

- `markdownlint-cli2 --no-globs docs/local-custom-hooks-spec.md`

Runtime checks after implementation:

- `shellspec test/common/path_spec.sh`
- `shellspec test/dispatcher/run-hook_spec.sh`

## Open Questions

- Should `setup-repo-hooks.sh --check` eventually validate local extra hooks, or
  should runtime dispatch remain the only enforcement point?
- Should there be a machine-private hook mechanism later, separate from tracked
  `.githooks/project.conf` policy?
- Should local hook scripts be required to live under a tracked
  `.githooks/hooks/` directory, or is executable presence enough?
