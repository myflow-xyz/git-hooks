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
  git_hooks_log_skip 'goimports; no staged Go files'
  exit 0
fi

if ! command -v goimports >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'goimports' 'goimports' 'go install golang.org/x/tools/cmd/goimports@latest'
  exit 0
fi

git_hooks_golang_prepare_runtime_dirs || exit $?
git_hooks_golang_capture goimports \
  git_hooks_golang_each "$GIT_HOOK_GO_STATE_DIR/staged" git_hooks_golang_import_file
exit "$?"
