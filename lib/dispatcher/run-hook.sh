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

git_hooks_dispatcher_run_local_hook() {
  git_hooks_dispatcher_local_hook=$(git_hooks_dispatcher_trim "$1")
  shift

  case "$git_hooks_dispatcher_local_hook" in
  '' | \#*)
    return 0
    ;;
  esac

  git_hooks_dispatcher_local_hook_path=$(git_hooks_paths_local_hook "$GIT_HOOK_PROJECT_DIR" "$git_hooks_dispatcher_local_hook") || return $?

  if [ ! -f "$git_hooks_dispatcher_local_hook_path" ] || [ ! -x "$git_hooks_dispatcher_local_hook_path" ]; then
    git_hooks_log_error "local hook is not executable: $git_hooks_dispatcher_local_hook_path"
    return 1
  fi

  git_hooks_log_check_start "local/$git_hooks_dispatcher_local_hook"
  "$git_hooks_dispatcher_local_hook_path" "$@"
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

git_hooks_dispatcher_index_guard_active=0
git_hooks_dispatcher_index_guard_restore=0
git_hooks_dispatcher_index_guard_had_index=0
git_hooks_dispatcher_index_guard_index_path=
git_hooks_dispatcher_index_guard_snapshot=

git_hooks_dispatcher_index_guard_path() {
  if [ -n "${GIT_INDEX_FILE:-}" ]; then
    printf '%s\n' "$GIT_INDEX_FILE"
    return 0
  fi

  command git -C "$GIT_HOOK_REPO_ROOT" rev-parse --git-path index
}

git_hooks_dispatcher_index_guard_restore_snapshot() {
  [ "$git_hooks_dispatcher_index_guard_active" -eq 1 ] || return 0

  if [ "$git_hooks_dispatcher_index_guard_had_index" -eq 1 ]; then
    command cp "$git_hooks_dispatcher_index_guard_snapshot" "$git_hooks_dispatcher_index_guard_index_path"
    return $?
  fi

  command rm -f "$git_hooks_dispatcher_index_guard_index_path"
}

git_hooks_dispatcher_index_guard_cleanup() {
  if [ "$git_hooks_dispatcher_index_guard_restore" -eq 1 ]; then
    if git_hooks_dispatcher_index_guard_restore_snapshot; then
      git_hooks_log_info 'restored pre-commit index snapshot'
    else
      git_hooks_log_warn 'failed to restore pre-commit index snapshot'
    fi
  fi

  if [ -n "$git_hooks_dispatcher_index_guard_snapshot" ]; then
    command rm -f "$git_hooks_dispatcher_index_guard_snapshot"
  fi

  return 0
}

git_hooks_dispatcher_index_guard_start() {
  [ "$GIT_HOOK_PHASE" = pre-commit ] || return 0

  if ! command -v mktemp >/dev/null 2>&1; then
    git_hooks_log_error 'required command not found: mktemp'
    return 127
  fi

  git_hooks_dispatcher_index_guard_index_path=$(git_hooks_dispatcher_index_guard_path) || return $?
  git_hooks_dispatcher_index_guard_snapshot=$(mktemp "${TMPDIR:-/tmp}/git-hooks-index.XXXXXX") || {
    git_hooks_log_error 'failed to create temporary file for pre-commit index snapshot'
    return 2
  }
  git_hooks_dispatcher_index_guard_active=1
  git_hooks_env_install_abort_traps git_hooks_dispatcher_index_guard_cleanup

  if [ -f "$git_hooks_dispatcher_index_guard_index_path" ]; then
    command cp "$git_hooks_dispatcher_index_guard_index_path" "$git_hooks_dispatcher_index_guard_snapshot" || return $?
    git_hooks_dispatcher_index_guard_had_index=1
  fi

  git_hooks_dispatcher_index_guard_restore=1
}

git_hooks_dispatcher_index_guard_disarm() {
  git_hooks_dispatcher_index_guard_restore=0
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

# shellcheck source=lib/common/env.sh
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_install_abort_traps || exit $?
git_hooks_env_bootstrap "$GIT_HOOK_PHASE" || exit $?
git_hooks_dispatcher_index_guard_start || exit $?

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
  GIT_HOOK_EXTRA_LOCAL_HOOKS=${GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS:-}
  ;;
pre-push)
  GIT_HOOK_EXTRA_CHECKS=${GIT_HOOK_PRE_PUSH_EXTRA_CHECKS:-}
  GIT_HOOK_EXTRA_LOCAL_HOOKS=${GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS:-}
  ;;
commit-msg)
  GIT_HOOK_EXTRA_CHECKS=${GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS:-}
  GIT_HOOK_EXTRA_LOCAL_HOOKS=${GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS:-}
  ;;
esac

for git_hooks_dispatcher_check in $GIT_HOOK_EXTRA_CHECKS; do
  git_hooks_dispatcher_run_check "$git_hooks_dispatcher_check" "$@" || exit $?
done

for git_hooks_dispatcher_local_hook in $GIT_HOOK_EXTRA_LOCAL_HOOKS; do
  git_hooks_dispatcher_run_local_hook "$git_hooks_dispatcher_local_hook" "$@" || exit $?
done

git_hooks_dispatcher_index_guard_disarm
