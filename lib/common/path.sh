#!/usr/bin/env sh

# Path and layout helpers for shared Git hooks.

git_hooks_paths_home() {
  printf '%s\n' "${GIT_HOOKS_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/git-hooks}"
}

git_hooks_paths_join() {
  if [ "$#" -lt 1 ]; then
    printf '%s\n' 'Usage: git_hooks_paths_join <base> [path...]' >&2
    return 2
  fi

  git_hooks_paths_join_result=${1%/}
  shift

  while [ "$#" -gt 0 ]; do
    git_hooks_paths_join_part=${1#/}
    git_hooks_paths_join_result=$git_hooks_paths_join_result/$git_hooks_paths_join_part
    shift
  done

  printf '%s\n' "$git_hooks_paths_join_result"
}

git_hooks_paths_repo_hooks_dir() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: git_hooks_paths_repo_hooks_dir <repo-root>' >&2
    return 2
  fi

  git_hooks_paths_join "$1" '.githooks'
}

git_hooks_paths_project_env() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: git_hooks_paths_project_env <repo-root>' >&2
    return 2
  fi

  git_hooks_paths_join "$(git_hooks_paths_repo_hooks_dir "$1")" 'hooks.env'
}

git_hooks_paths_project_conf() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: git_hooks_paths_project_conf <repo-root>' >&2
    return 2
  fi

  git_hooks_paths_join "$(git_hooks_paths_repo_hooks_dir "$1")" 'project.conf'
}

git_hooks_paths_profile_list() {
  if [ "$#" -ne 3 ]; then
    printf '%s\n' 'Usage: git_hooks_paths_profile_list <hooks-home> <profile> <phase>' >&2
    return 2
  fi

  git_hooks_paths_join "$1" 'profiles' "$2" "$3.list"
}

git_hooks_paths_check() {
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'Usage: git_hooks_paths_check <hooks-home> <check-id>' >&2
    return 2
  fi

  case "$2" in
    /*) printf '%s\n' "$2" ;;
    *) git_hooks_paths_join "$1" 'lib/checks' "${2%.sh}.sh" ;;
  esac
}
