#!/usr/bin/env sh

set -u

git_hooks_dispatcher_usage() {
  printf '%s\n' 'Usage: run-hook.sh <pre-commit|pre-push|commit-msg> [git-hook-args...]'
}

git_hooks_dispatcher_trim() {
  printf '%s\n' "$1" | command sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

git_hooks_dispatcher_run_check() {
  git_hooks_dispatcher_check=$(git_hooks_dispatcher_trim "$1")
  shift

  case "$git_hooks_dispatcher_check" in
  '' | \#*)
    return 0
    ;;
  esac

  git_hooks_dispatcher_check_path=$(git_hooks_paths_check "$GIT_HOOKS_HOME" "$git_hooks_dispatcher_check") || return $?

  if [ ! -x "$git_hooks_dispatcher_check_path" ]; then
    git_hooks_log_error "check is not executable: $git_hooks_dispatcher_check_path"
    return 1
  fi

  git_hooks_log_check_start "$git_hooks_dispatcher_check"
  "$git_hooks_dispatcher_check_path" "$@"
}

git_hooks_dispatcher_run_list() {
  git_hooks_dispatcher_list_file=$1
  shift

  [ -f "$git_hooks_dispatcher_list_file" ] || return 0

  while IFS= read -r git_hooks_dispatcher_check || [ -n "$git_hooks_dispatcher_check" ]; do
    git_hooks_dispatcher_run_check "$git_hooks_dispatcher_check" "$@" || return $?
  done <"$git_hooks_dispatcher_list_file"
}

git_hooks_dispatcher_profile_seen=

git_hooks_dispatcher_profile_was_seen() {
  case " $git_hooks_dispatcher_profile_seen " in
  *" $1 "*)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

git_hooks_dispatcher_mark_profile_seen() {
  git_hooks_dispatcher_profile_seen="$git_hooks_dispatcher_profile_seen $1"
}

git_hooks_dispatcher_profile_exists() {
  [ -d "$(git_hooks_paths_join "$GIT_HOOKS_HOME" profiles "$1")" ]
}

if [ "$#" -lt 1 ]; then
  git_hooks_dispatcher_usage >&2
  exit 2
fi

GIT_HOOK_PHASE=$1
shift

case "$GIT_HOOK_PHASE" in
pre-commit | pre-push | commit-msg)
  ;;
*)
  git_hooks_dispatcher_usage >&2
  exit 2
  ;;
esac

GIT_HOOKS_HOME=${GIT_HOOKS_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/git-hooks}
GIT_HOOKS_COMMON_DIR=$GIT_HOOKS_HOME/lib/common

. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_install_abort_traps || exit $?
git_hooks_env_bootstrap "$GIT_HOOK_PHASE" || exit $?

for git_hooks_dispatcher_profile in $GIT_HOOK_PROFILES; do
  if git_hooks_dispatcher_profile_was_seen "$git_hooks_dispatcher_profile"; then
    git_hooks_log_warn "skip duplicate profile: $git_hooks_dispatcher_profile"
    continue
  fi

  if ! git_hooks_dispatcher_profile_exists "$git_hooks_dispatcher_profile"; then
    git_hooks_log_error "unknown profile: $git_hooks_dispatcher_profile"
    exit 2
  fi

  git_hooks_dispatcher_mark_profile_seen "$git_hooks_dispatcher_profile"

  git_hooks_dispatcher_run_list \
    "$(git_hooks_paths_profile_list "$GIT_HOOKS_HOME" "$git_hooks_dispatcher_profile" "$GIT_HOOK_PHASE")" "$@" || exit $?
done

case "$GIT_HOOK_PHASE" in
pre-commit)
  GIT_HOOK_EXTRA_CHECKS=${GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS:-}
  ;;
pre-push)
  GIT_HOOK_EXTRA_CHECKS=${GIT_HOOK_PRE_PUSH_EXTRA_CHECKS:-}
  ;;
commit-msg)
  GIT_HOOK_EXTRA_CHECKS=${GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS:-}
  ;;
esac

for git_hooks_dispatcher_check in $GIT_HOOK_EXTRA_CHECKS; do
  git_hooks_dispatcher_run_check "$git_hooks_dispatcher_check" "$@" || exit $?
done
