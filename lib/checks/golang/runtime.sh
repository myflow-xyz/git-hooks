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

git_hooks_golang_prepare_runtime_dirs() {
  git_hooks_golang_prepare_runtime_dir GOCACHE "${GOCACHE:-}" || return $?
  git_hooks_golang_prepare_runtime_dir GOTMPDIR "${GOTMPDIR:-}" || return $?
}
