#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
GIT_HOOKS_GOLANG_DIR=${GIT_HOOKS_GOLANG_DIR:-$(CDPATH='' cd -- "$(dirname "$0")" && pwd)}
. "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_govulncheck_run() {
  git_hooks_env_run_project_command govulncheck ./...
}

if [ ! -f go.mod ] && [ ! -f go.work ]; then
  git_hooks_log_skip 'govulncheck; go.mod or go.work missing'
  exit 0
fi

if ! git_hooks_golang_has_go_files; then
  git_hooks_log_skip 'govulncheck; no Go files'
  exit 0
fi

if ! command -v govulncheck >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'govulncheck' 'govulncheck' 'go install golang.org/x/vuln/cmd/govulncheck@latest'
  exit 0
fi

git_hooks_golang_prepare_runtime_dirs || exit $?

git_hooks_log_info 'govulncheck ./...'

if git_hooks_log_is_verbose; then
  git_hooks_govulncheck_run
  git_hooks_govulncheck_status=$?
  if [ "$git_hooks_govulncheck_status" -ne 0 ]; then
    git_hooks_log_error "govulncheck failed; exit=$git_hooks_govulncheck_status"
  fi
  exit "$git_hooks_govulncheck_status"
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_govulncheck_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for govulncheck output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_govulncheck_output"' || exit $?

git_hooks_govulncheck_run >"$git_hooks_govulncheck_output" 2>&1
git_hooks_govulncheck_status=$?

if [ "$git_hooks_govulncheck_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "govulncheck failed; exit=$git_hooks_govulncheck_status"

if [ -s "$git_hooks_govulncheck_output" ]; then
  command sed -n '1,120p' "$git_hooks_govulncheck_output" >&2
  git_hooks_govulncheck_lines=$(command wc -l <"$git_hooks_govulncheck_output" | command tr -d ' ')
  if [ "$git_hooks_govulncheck_lines" -gt 120 ]; then
    git_hooks_log_warn "govulncheck output truncated; lines=$git_hooks_govulncheck_lines shown=120"
  fi
fi

exit "$git_hooks_govulncheck_status"
