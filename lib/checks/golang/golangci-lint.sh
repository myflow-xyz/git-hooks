#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
GIT_HOOKS_GOLANG_DIR=${GIT_HOOKS_GOLANG_DIR:-$(CDPATH='' cd -- "$(dirname "$0")" && pwd)}
. "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

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

GIT_HOOK_GO_LINT_CONFIG=$(git_hooks_golangci_select_config) || GIT_HOOK_GO_LINT_CONFIG=
export GIT_HOOK_GO_LINT_CONFIG

git_hooks_log_info "golangci-lint config: ${GIT_HOOK_GO_LINT_CONFIG:-tool defaults}"
git_hooks_golang_run_check golangci-lint golangci-lint \
  'install upstream binary from golangci-lint releases; avoid Homebrew Go runtime shims'
exit "$?"
