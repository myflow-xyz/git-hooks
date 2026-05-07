# `lib/common/env.sh`

## Scope

Runtime environment bootstrap for dispatcher and check scripts.

## Responsibilities

- Resolve `GIT_HOOKS_HOME`, `GIT_HOOK_REPO_ROOT`, and `GIT_HOOK_PROJECT_DIR`.
- Load optional `.githooks/hooks.env` before optional `.githooks/project.conf`.
- Export values from `hooks.env` so child checks can use them when the file
  exists.
- Load `.githooks/hooks.env` and `.githooks/project.conf` for direct check
  execution too, so debugging a check script uses the same repo policy as
  dispatcher execution.
- Apply defaults such as `GIT_HOOK_PROFILES=common`.
- Default missing extra-check variables to empty; repo config should omit empty
  variables and set only values that change hook policy.
- Provide shared cleanup-and-abort trap helpers so checks do not swallow
  `SIGHUP`, `SIGINT`, or `SIGTERM`.
- Keep runtime bootstrap portable for `sh`, `bash`, and `zsh`.

## Priority

Environment values are applied from lowest to highest priority:

1. Built-in defaults.
2. Parent process environment from the shell, Git, IDE, or agent.
3. Repo-local `.githooks/hooks.env`.
4. Repo-local `.githooks/project.conf`.

Repo-local files intentionally win over shell variables because they represent
the repository's hook policy. For example, if your shell exports
`GIT_HOOK_VERBOSE=1` but `.githooks/hooks.env` sets `GIT_HOOK_VERBOSE=0`, the
repo-local value wins.

For AI agents, prefer setting `GIT_HOOK_VERBOSE=0` in the agent runtime
environment so inherited developer shell verbosity does not increase tool
output. Codex can inject it through `shell_environment_policy.set`; Claude Code
can inject it through `settings.json` `env`. A repo can still override that
agent default by explicitly setting `GIT_HOOK_VERBOSE` in `.githooks/hooks.env`.

## Public Functions

- `git_hooks_env_bootstrap <phase>`
- `git_hooks_env_bootstrap_check`
- `git_hooks_env_install_abort_traps [cleanup-command]`
- `git_hooks_env_load_file <path>`
- `git_hooks_env_load_export_file <path>`

## Boundary

Do not add check-specific defaults here. Use profile lists and project config for
policy.

## Test Cases

Run only this script's tests:

- `shellspec test/common/env_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | bootstraps dispatcher env and local config |
| Existing | `git-hooks` | defaults missing extra-check variables to empty |
| Existing | `git-hooks` | bootstraps direct check env and loads repo policy |
| Existing | `git-hooks` | rejects unknown phases |
| Existing | `git-hooks` | abort traps clean temporary files and exit on interrupt |
| Recommended | `git-hooks` | Cover nested worktree check bootstrap. |
| Recommended | `git-hooks` | Cover invalid local env/config syntax. |
