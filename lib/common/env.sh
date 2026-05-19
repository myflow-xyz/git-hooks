#!/usr/bin/env sh

# Runtime bootstrap helpers for shared Git hooks.

git_hooks_env_common_dir=${GIT_HOOKS_COMMON_DIR:-${GIT_HOOKS_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/git-hooks}/lib/common}

. "$git_hooks_env_common_dir/path.sh" || return $?
. "$git_hooks_env_common_dir/log.sh" || return $?
. "$git_hooks_env_common_dir/git.sh" || return $?

git_hooks_env_cleanup_command=

git_hooks_env_run_cleanup() {
  [ -n "${git_hooks_env_cleanup_command:-}" ] || return 0
  eval "$git_hooks_env_cleanup_command"
}

git_hooks_env_abort() {
  git_hooks_env_abort_status=${1:-130}
  git_hooks_env_run_cleanup
  trap - EXIT HUP INT TERM
  exit "$git_hooks_env_abort_status"
}

git_hooks_env_install_abort_traps() {
  if [ "$#" -gt 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_env_install_abort_traps [cleanup-command]'
    return 2
  fi

  git_hooks_env_cleanup_command=${1:-}
  trap 'git_hooks_env_run_cleanup' EXIT
  trap 'git_hooks_env_abort 129' HUP
  trap 'git_hooks_env_abort 130' INT
  trap 'git_hooks_env_abort 143' TERM
}

git_hooks_env_unset_git_local_vars() {
  git_hooks_env_git_local_vars=$(command git rev-parse --local-env-vars 2>/dev/null) ||
    git_hooks_env_git_local_vars='
GIT_ALTERNATE_OBJECT_DIRECTORIES
GIT_CONFIG
GIT_CONFIG_PARAMETERS
GIT_CONFIG_COUNT
GIT_OBJECT_DIRECTORY
GIT_DIR
GIT_WORK_TREE
GIT_IMPLICIT_WORK_TREE
GIT_GRAFT_FILE
GIT_INDEX_FILE
GIT_NO_REPLACE_OBJECTS
GIT_REPLACE_REF_BASE
GIT_PREFIX
GIT_SHALLOW_FILE
GIT_COMMON_DIR
'

  for git_hooks_env_git_local_var in $git_hooks_env_git_local_vars; do
    unset "$git_hooks_env_git_local_var"
  done
}

git_hooks_env_unset_hook_runtime_vars() {
  unset GIT_HOOK_PHASE
  unset GIT_HOOKS_HOME
  unset GIT_HOOKS_COMMON_DIR
  unset GIT_HOOK_REPO_ROOT
  unset GIT_HOOK_PROJECT_DIR
  unset GIT_HOOK_PROJECT_ENV
  unset GIT_HOOK_PROJECT_CONF
  unset GIT_HOOK_PROFILES
  unset GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS
  unset GIT_HOOK_PRE_PUSH_EXTRA_CHECKS
  unset GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS
  unset GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS
  unset GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS
  unset GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS
  unset GIT_HOOK_EXTRA_CHECKS
  unset GIT_HOOK_EXTRA_LOCAL_HOOKS
  unset GIT_HOOK_VERBOSE
  unset GIT_HOOK_PYTHON_RUNNER
  unset GIT_HOOK_PYTHON_UV_ARGS
}

git_hooks_env_run_project_command() {
  if [ "$#" -lt 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_env_run_project_command <command> [args...]'
    return 2
  fi

  (
    git_hooks_env_unset_git_local_vars
    git_hooks_env_unset_hook_runtime_vars
    command "$@"
  )
}

git_hooks_env_load_file() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_env_load_file <path>'
    return 2
  fi

  [ -f "$1" ] || return 0
  # shellcheck source=/dev/null
  . "$1" || {
    git_hooks_log_error "failed to load: $1"
    return 1
  }
}

git_hooks_env_load_export_file() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_env_load_export_file <path>'
    return 2
  fi

  [ -f "$1" ] || return 0

  set -a
  # shellcheck source=/dev/null
  . "$1" || {
    set +a
    git_hooks_log_error "failed to load: $1"
    return 1
  }
  set +a
}

git_hooks_env_bootstrap() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_env_bootstrap <phase>'
    return 2
  fi

  GIT_HOOK_PHASE=$1

  case "$GIT_HOOK_PHASE" in
  pre-commit | pre-push | commit-msg)
    ;;
  *)
    git_hooks_log_error "unknown hook phase: $GIT_HOOK_PHASE"
    return 2
    ;;
  esac

  GIT_HOOKS_HOME=$(git_hooks_paths_home)
  GIT_HOOK_REPO_ROOT=${GIT_HOOK_REPO_ROOT:-$(git_hooks_git_repo_root)} || {
    git_hooks_log_error 'not inside a git repository'
    return 1
  }
  GIT_HOOK_PROJECT_DIR=$(git_hooks_paths_repo_hooks_dir "$GIT_HOOK_REPO_ROOT")
  GIT_HOOK_PROJECT_ENV=$(git_hooks_paths_project_env "$GIT_HOOK_REPO_ROOT")
  GIT_HOOK_PROJECT_CONF=$(git_hooks_paths_project_conf "$GIT_HOOK_REPO_ROOT")

  export GIT_HOOK_PHASE
  export GIT_HOOKS_HOME
  export GIT_HOOK_REPO_ROOT
  export GIT_HOOK_PROJECT_DIR

  cd "$GIT_HOOK_REPO_ROOT" || {
    git_hooks_log_error "failed to enter repo: $GIT_HOOK_REPO_ROOT"
    return 1
  }

  git_hooks_env_load_export_file "$GIT_HOOK_PROJECT_ENV" || return $?
  git_hooks_env_load_file "$GIT_HOOK_PROJECT_CONF" || return $?

  GIT_HOOK_PROFILES=${GIT_HOOK_PROFILES:-common}
  GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS=${GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS:-}
  GIT_HOOK_PRE_PUSH_EXTRA_CHECKS=${GIT_HOOK_PRE_PUSH_EXTRA_CHECKS:-}
  GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS=${GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS:-}
  GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS=${GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS:-}
  GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS=${GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS:-}
  GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS=${GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS:-}

  export GIT_HOOK_PROFILES
  export GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS
  export GIT_HOOK_PRE_PUSH_EXTRA_CHECKS
  export GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS
  export GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS
  export GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS
  export GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS
}

git_hooks_env_bootstrap_check() {
  GIT_HOOKS_HOME=$(git_hooks_paths_home)
  GIT_HOOK_REPO_ROOT=${GIT_HOOK_REPO_ROOT:-$(git_hooks_git_repo_root)} || {
    git_hooks_log_error 'not inside a git repository'
    return 1
  }
  GIT_HOOK_PROJECT_DIR=$(git_hooks_paths_repo_hooks_dir "$GIT_HOOK_REPO_ROOT")
  GIT_HOOK_PROJECT_ENV=$(git_hooks_paths_project_env "$GIT_HOOK_REPO_ROOT")
  GIT_HOOK_PROJECT_CONF=$(git_hooks_paths_project_conf "$GIT_HOOK_REPO_ROOT")

  export GIT_HOOKS_HOME
  export GIT_HOOK_REPO_ROOT
  export GIT_HOOK_PROJECT_DIR

  cd "$GIT_HOOK_REPO_ROOT" || {
    git_hooks_log_error "failed to enter repo: $GIT_HOOK_REPO_ROOT"
    return 1
  }

  git_hooks_env_load_export_file "$GIT_HOOK_PROJECT_ENV" || return $?
  git_hooks_env_load_file "$GIT_HOOK_PROJECT_CONF" || return $?
}
