#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
GIT_HOOKS_GOLANG_DIR=${GIT_HOOKS_GOLANG_DIR:-$(CDPATH='' cd -- "$(dirname "$0")" && pwd)}
. "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?
git_hooks_golang_begin || exit $?
git_hooks_golang_collect_staged || exit $?

if [ ! -s "$GIT_HOOK_GO_STATE_DIR/staged" ]; then
  git_hooks_log_skip 'golangci-lint-fast; no staged Go files'
  exit 0
fi

if ! command -v golangci-lint >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'golangci-lint-fast' 'golangci-lint' 'install upstream binary from golangci-lint releases; avoid Homebrew Go runtime shims'
  exit 0
fi

GIT_HOOK_GO_LINT_CONFIG=$GIT_HOOKS_HOME/config/golangci-lint/fast.yaml
if [ ! -f "$GIT_HOOK_GO_LINT_CONFIG" ]; then
  git_hooks_log_warn "skip golangci-lint-fast; missing bundled config: $GIT_HOOK_GO_LINT_CONFIG"
  exit 0
fi

# Package context comes from the index. Nothing is checked out into the user's
# working tree, and no temporary Git index replaces the commit's index.
GIT_HOOK_GO_SOURCE_ROOT=$GIT_HOOK_GO_STATE_DIR/index
command mkdir -p "$GIT_HOOK_GO_SOURCE_ROOT" || exit $?
command git checkout-index --all --prefix="$GIT_HOOK_GO_SOURCE_ROOT/" || exit $?
git_hooks_golang_collect_modules >"$GIT_HOOK_GO_STATE_DIR/modules" || exit $?
if [ ! -s "$GIT_HOOK_GO_STATE_DIR/modules" ]; then
  git_hooks_log_skip 'golangci-lint-fast; no staged Go modules'
  exit 0
fi

git_hooks_golang_each "$GIT_HOOK_GO_STATE_DIR/staged" git_hooks_golang_mark_affected_module || exit $?
git_hooks_golang_prepare_lint_runtime_dirs || exit $?
GIT_HOOK_GO_CHECK=golangci-lint-fast
export GIT_HOOK_GO_CHECK GIT_HOOK_GO_LINT_CONFIG GIT_HOOK_GO_SOURCE_ROOT
git_hooks_log_info "golangci-lint-fast config: $GIT_HOOK_GO_LINT_CONFIG"
git_hooks_golang_capture golangci-lint-fast \
  git_hooks_golang_each "$GIT_HOOK_GO_STATE_DIR/modules" git_hooks_golang_module_command
exit "$?"
