#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
GIT_HOOKS_GOLANG_DIR=${GIT_HOOKS_GOLANG_DIR:-$(CDPATH='' cd -- "$(dirname "$0")" && pwd)}
. "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

if [ ! -f go.mod ] && [ ! -f go.work ]; then
  git_hooks_log_skip 'go-vet; go.mod or go.work missing'
  exit 0
fi

if ! command -v go >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'go-vet' 'go' 'install Go from https://go.dev/dl/'
  exit 0
fi

git_hooks_golang_prepare_runtime_dirs || exit $?

git_hooks_log_info 'go vet ./...'

if git_hooks_log_is_verbose; then
  command go vet ./...
  exit $?
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_go_vet_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-go-vet.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for go vet output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_go_vet_output"' || exit $?

command go vet ./... >"$git_hooks_go_vet_output" 2>&1
git_hooks_go_vet_status=$?

if [ "$git_hooks_go_vet_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "go vet failed; exit=$git_hooks_go_vet_status"

if [ -s "$git_hooks_go_vet_output" ]; then
  command sed -n '1,120p' "$git_hooks_go_vet_output" >&2
  git_hooks_go_vet_lines=$(command wc -l <"$git_hooks_go_vet_output" | command tr -d ' ')
  if [ "$git_hooks_go_vet_lines" -gt 120 ]; then
    git_hooks_log_warn "go vet output truncated; lines=$git_hooks_go_vet_lines shown=120"
  fi
fi

exit "$git_hooks_go_vet_status"
