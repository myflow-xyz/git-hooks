# `lib/common/path.sh`

## Scope

Filesystem layout and path resolution helpers.

## Responsibilities

- Resolve default `$XDG_CONFIG_HOME/git-hooks`.
- Join path segments without relying on trailing slashes.
- Resolve repo-local `.githooks` paths.
- Resolve repo-local custom hook IDs under `.githooks/hooks`.
- Resolve profile list paths and check IDs.
- Keep wrappers, dispatcher, and checks aligned on layout.

## Public Functions

- `git_hooks_paths_home`
- `git_hooks_paths_join <base> [path...]`
- `git_hooks_paths_repo_hooks_dir <repo-root>`
- `git_hooks_paths_project_env <repo-root>`
- `git_hooks_paths_project_conf <repo-root>`
- `git_hooks_paths_local_hook <repo-hooks-dir> <hook-id>`
- `git_hooks_paths_profile_list <hooks-home> <profile> <phase>`
- `git_hooks_paths_check <hooks-home> <check-id>`

Local hook IDs are suffixless paths relative to `.githooks/hooks`, for example
`dir/xhook` resolves to `.githooks/hooks/dir/xhook.sh`. IDs with absolute paths,
`..`, `.`, duplicate separators, trailing slashes, or `.sh` suffixes are
invalid.

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
| Existing | `git-hooks` | resolves direct local hook IDs under repo githooks |
| Existing | `git-hooks` | resolves nested local hook IDs under repo githooks |
| Existing | `git-hooks` | rejects invalid local hook IDs |
| Recommended | `git-hooks` | Cover env, config, and profile-list paths. |
