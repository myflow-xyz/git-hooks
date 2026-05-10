#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
GIT_HOOKS_GOLANG_DIR=${GIT_HOOKS_GOLANG_DIR:-$(CDPATH='' cd -- "$(dirname "$0")" && pwd)}
. "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_golangci_has_go_context() {
  [ -f go.mod ] || [ -f go.work ]
}

git_hooks_golangci_select_config() {
  git_hooks_golangci_xdg_config_home=${XDG_CONFIG_HOME:-$HOME/.config}

  for git_hooks_golangci_config_candidate in \
    "$GIT_HOOK_REPO_ROOT/.golangci.yml" \
    "$GIT_HOOK_REPO_ROOT/.golangci.yaml" \
    "$GIT_HOOK_REPO_ROOT/.golangci.toml" \
    "$GIT_HOOK_REPO_ROOT/.golangci.json" \
    "$git_hooks_golangci_xdg_config_home/golangci-lint/config.yaml" \
    "$git_hooks_golangci_xdg_config_home/golangci-lint/config.yml" \
    "$GIT_HOOKS_HOME/config/golangci-lint/config.yaml"; do
    if [ -f "$git_hooks_golangci_config_candidate" ]; then
      printf '%s\n' "$git_hooks_golangci_config_candidate"
      return 0
    fi
  done

  return 1
}

git_hooks_golangci_run_linter() {
  if [ -n "$git_hooks_golangci_config" ]; then
    command golangci-lint run --config "$git_hooks_golangci_config"
    return $?
  fi

  command golangci-lint run
}

if ! git_hooks_golangci_has_go_context; then
  git_hooks_log_skip 'golangci-lint; go.mod or go.work missing'
  exit 0
fi

if ! git_hooks_golang_has_go_files; then
  git_hooks_log_skip 'golangci-lint; no Go files'
  exit 0
fi

if ! command -v golangci-lint >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'golangci-lint' 'golangci-lint' 'install upstream binary from golangci-lint releases; avoid Homebrew Go runtime shims'
  exit 0
fi

git_hooks_golangci_config=$(git_hooks_golangci_select_config) || git_hooks_golangci_config=

if [ -n "$git_hooks_golangci_config" ]; then
  git_hooks_log_info "golangci-lint config: $git_hooks_golangci_config"
else
  git_hooks_log_info 'golangci-lint config: tool defaults'
fi

git_hooks_golang_prepare_runtime_dirs || exit $?

if git_hooks_log_is_verbose; then
  git_hooks_golangci_run_linter
  exit $?
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_golangci_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-golangci-lint.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for golangci-lint output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_golangci_output"' || exit $?

git_hooks_golangci_run_linter >"$git_hooks_golangci_output" 2>&1
git_hooks_golangci_status=$?

if [ "$git_hooks_golangci_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "golangci-lint failed; exit=$git_hooks_golangci_status"

if [ -s "$git_hooks_golangci_output" ]; then
  command sed -n '1,120p' "$git_hooks_golangci_output" >&2
  git_hooks_golangci_lines=$(command wc -l <"$git_hooks_golangci_output" | command tr -d ' ')
  if [ "$git_hooks_golangci_lines" -gt 120 ]; then
    git_hooks_log_warn "golangci-lint output truncated; lines=$git_hooks_golangci_lines shown=120"
  fi
fi

exit "$git_hooks_golangci_status"
