#!/usr/bin/env sh

# Shared Go runtime helpers for checks that invoke Go tooling.

git_hooks_golang_prepare_runtime_dir() {
  if [ "$#" -ne 2 ]; then
    git_hooks_log_error 'Usage: git_hooks_golang_prepare_runtime_dir <env-name> <path>'
    return 2
  fi

  git_hooks_golang_runtime_dir_name=$1
  git_hooks_golang_runtime_dir_path=$2

  [ -n "$git_hooks_golang_runtime_dir_path" ] || return 0

  if [ -d "$git_hooks_golang_runtime_dir_path" ]; then
    return 0
  fi

  if [ -e "$git_hooks_golang_runtime_dir_path" ]; then
    git_hooks_log_error "$git_hooks_golang_runtime_dir_name is not a directory: $git_hooks_golang_runtime_dir_path"
    return 1
  fi

  if command mkdir -p "$git_hooks_golang_runtime_dir_path"; then
    git_hooks_log_info "created $git_hooks_golang_runtime_dir_name: $git_hooks_golang_runtime_dir_path"
    return 0
  fi

  git_hooks_log_error "failed to create $git_hooks_golang_runtime_dir_name: $git_hooks_golang_runtime_dir_path"
  return 1
}

git_hooks_golang_ensure_repo_root() {
  if [ -z "${GIT_HOOK_REPO_ROOT:-}" ]; then
    GIT_HOOK_REPO_ROOT=$(git_hooks_git_repo_root) || {
      git_hooks_log_error 'not inside a git repository'
      return 1
    }
    export GIT_HOOK_REPO_ROOT
  fi
}

git_hooks_golang_default_runtime_dirs() {
  if [ "${GOCACHE+x}" != x ] || [ "${GOTMPDIR+x}" != x ]; then
    git_hooks_golang_ensure_repo_root || return $?
  fi

  if [ "${GOCACHE+x}" != x ]; then
    GOCACHE=$GIT_HOOK_REPO_ROOT/.cache/go-build
  fi

  if [ "${GOTMPDIR+x}" != x ]; then
    GOTMPDIR=$GIT_HOOK_REPO_ROOT/.tmp/go
  fi

  export GOCACHE
  export GOTMPDIR
}

git_hooks_golang_default_lint_runtime_dirs() {
  if [ "${GOLANGCI_LINT_CACHE+x}" != x ]; then
    git_hooks_golang_ensure_repo_root || return $?
  fi

  if [ "${GOLANGCI_LINT_CACHE+x}" != x ]; then
    GOLANGCI_LINT_CACHE=$GIT_HOOK_REPO_ROOT/.cache/golangci-lint
  fi

  export GOLANGCI_LINT_CACHE
}

git_hooks_golang_prepare_runtime_dirs() {
  git_hooks_golang_default_runtime_dirs || return $?
  git_hooks_golang_prepare_runtime_dir GOCACHE "${GOCACHE:-}" || return $?
  git_hooks_golang_prepare_runtime_dir GOTMPDIR "${GOTMPDIR:-}" || return $?
}

git_hooks_golang_prepare_lint_runtime_dirs() {
  git_hooks_golang_prepare_runtime_dirs || return $?
  git_hooks_golang_default_lint_runtime_dirs || return $?
  git_hooks_golang_prepare_runtime_dir GOLANGCI_LINT_CACHE "${GOLANGCI_LINT_CACHE:-}" || return $?
}

git_hooks_golang_has_go_files() {
  if [ -n "$(command git ls-files -- '*.go' 2>/dev/null)" ]; then
    return 0
  fi

  [ -n "$(command git ls-files --others --exclude-standard -- '*.go' 2>/dev/null)" ]
}
