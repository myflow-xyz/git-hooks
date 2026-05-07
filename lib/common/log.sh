#!/usr/bin/env sh

# Terminal output helpers. Keep normal success/skip output quiet by default.

git_hooks_log_is_verbose() {
  case "${GIT_HOOK_VERBOSE:-0}" in
    1|[Tt][Rr][Uu][Ee])
      return 0
      ;;
    0|[Ff][Aa][Ll][Ss][Ee]|'')
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

git_hooks_log_info() {
  git_hooks_log_is_verbose || return 0
  printf 'git-hooks: %s\n' "$*"
}

git_hooks_log_skip() {
  git_hooks_log_is_verbose || return 0
  printf 'git-hooks: skip: %s\n' "$*"
}

git_hooks_log_error() {
  printf 'git-hooks: error: %s\n' "$*" >&2
}

git_hooks_log_warn() {
  printf 'git-hooks: warn: %s\n' "$*" >&2
}

git_hooks_log_skip_missing_tool() {
  if [ "$#" -lt 3 ]; then
    git_hooks_log_error 'Usage: git_hooks_log_skip_missing_tool <check> <tool> <install-hint>'
    return 2
  fi

  git_hooks_log_warn "skip $1; missing tool: $2; install: $3"
}

git_hooks_log_check_start() {
  git_hooks_log_info "run: $1"
}
