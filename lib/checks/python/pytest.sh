#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_pytest_has_tests() {
  [ -d tests ] || git_hooks_git_tracked_files | command grep -E '(^|/)(test_[^/]*|[^/]*_test)\.py$' >/dev/null 2>&1
}

if ! git_hooks_pytest_has_tests; then
  git_hooks_log_skip 'pytest; test files missing'
  exit 0
fi

git_hooks_python_require_tool pytest pytest 'uv add --dev pytest'
git_hooks_pytest_require_status=$?
if [ "$git_hooks_pytest_require_status" -eq 1 ]; then
  exit 0
elif [ "$git_hooks_pytest_require_status" -ne 0 ]; then
  exit "$git_hooks_pytest_require_status"
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_pytest_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-pytest.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for pytest output'
  exit 2
}
git_hooks_pytest_cache=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest-cache.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary directory for pytest cache'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -rf "$git_hooks_pytest_output" "$git_hooks_pytest_cache"' || exit $?

if git_hooks_log_is_verbose; then
  git_hooks_python_run pytest -o "cache_dir=$git_hooks_pytest_cache"
  exit $?
fi

git_hooks_python_run pytest -o "cache_dir=$git_hooks_pytest_cache" >"$git_hooks_pytest_output" 2>&1
git_hooks_pytest_status=$?

if [ "$git_hooks_pytest_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "pytest failed; exit=$git_hooks_pytest_status"

if [ -s "$git_hooks_pytest_output" ]; then
  command sed -n '1,120p' "$git_hooks_pytest_output" >&2
  git_hooks_pytest_lines=$(command wc -l <"$git_hooks_pytest_output" | command tr -d ' ')
  if [ "$git_hooks_pytest_lines" -gt 120 ]; then
    git_hooks_log_warn "pytest output truncated; lines=$git_hooks_pytest_lines shown=120"
  fi
fi

exit "$git_hooks_pytest_status"
