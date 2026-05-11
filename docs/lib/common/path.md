# `lib/common/path.sh`

## Scope

Filesystem layout and path resolution helpers.

## Responsibilities

- Resolve default `$XDG_CONFIG_HOME/git-hooks`.
- Join path segments without relying on trailing slashes.
- Resolve repo-local `.githooks` paths.
- Resolve profile list paths and check IDs.
- Keep wrappers, dispatcher, and checks aligned on layout.

## Public Functions

- `git_hooks_paths_home`
- `git_hooks_paths_join <base> [path...]`
- `git_hooks_paths_repo_hooks_dir <repo-root>`
- `git_hooks_paths_project_env <repo-root>`
- `git_hooks_paths_project_conf <repo-root>`
- `git_hooks_paths_profile_list <hooks-home> <profile> <phase>`
- `git_hooks_paths_check <hooks-home> <check-id>`

## Boundary

Do not add Git queries here. Use `lib/common/git.sh` for repository state.

## Test Cases

Run only this script's tests:

- `shellspec test/common/path_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | resolves Git hooks home from `XDG_CONFIG_HOME` |
| Existing | `git-hooks` | joins paths without duplicate slashes |
| Existing | `git-hooks` | resolves check IDs under `lib/checks` |
| Existing | `git-hooks` | passes absolute check paths through |
| Recommended | `git-hooks` | Cover repo-local hooks, project env, project config, and profile-list paths. |
