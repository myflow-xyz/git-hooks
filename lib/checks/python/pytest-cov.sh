#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_pytest_cov_has_tests() {
  [ -d tests ] || git_hooks_git_tracked_files | command grep -E '(^|/)(test_[^/]*|[^/]*_test)\.py$' >/dev/null 2>&1
}

if ! git_hooks_pytest_cov_has_tests; then
  git_hooks_log_skip 'pytest-cov; test files missing'
  exit 0
fi

git_hooks_python_require_tool 'pytest-cov' pytest 'uv add --dev pytest pytest-cov'
git_hooks_pytest_cov_require_status=$?
if [ "$git_hooks_pytest_cov_require_status" -eq 1 ]; then
  exit 0
elif [ "$git_hooks_pytest_cov_require_status" -ne 0 ]; then
  exit "$git_hooks_pytest_cov_require_status"
fi

if ! git_hooks_python_run pytest --help 2>/dev/null | command grep -F -- '--cov' >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'pytest-cov' 'pytest-cov' 'uv add --dev pytest-cov'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_pytest_cov_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-pytest-cov.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for pytest-cov output'
  exit 2
}
git_hooks_pytest_cov_cache=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest-cov-cache.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary directory for pytest-cov cache'
  exit 2
}
git_hooks_pytest_cov_data=
if [ -z "${COVERAGE_FILE:-}" ]; then
  git_hooks_pytest_cov_data=$(mktemp "${TMPDIR:-/tmp}/git-hooks-pytest-cov-data.XXXXXX") || {
    git_hooks_log_error 'failed to create temporary file for pytest-cov data'
    exit 2
  }
  COVERAGE_FILE=$git_hooks_pytest_cov_data
  export COVERAGE_FILE
fi
git_hooks_env_install_abort_traps 'rm -rf "$git_hooks_pytest_cov_output" "$git_hooks_pytest_cov_data" "$git_hooks_pytest_cov_cache"' || exit $?

if git_hooks_log_is_verbose; then
  git_hooks_python_run pytest -o "cache_dir=$git_hooks_pytest_cov_cache" --cov=. --cov-report=term-missing:skip-covered
  exit $?
fi

git_hooks_python_run pytest -o "cache_dir=$git_hooks_pytest_cov_cache" --cov=. --cov-report=term-missing:skip-covered >"$git_hooks_pytest_cov_output" 2>&1
git_hooks_pytest_cov_status=$?

if [ "$git_hooks_pytest_cov_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "pytest-cov failed; exit=$git_hooks_pytest_cov_status"

if [ -s "$git_hooks_pytest_cov_output" ]; then
  command sed -n '1,120p' "$git_hooks_pytest_cov_output" >&2
  git_hooks_pytest_cov_lines=$(command wc -l <"$git_hooks_pytest_cov_output" | command tr -d ' ')
  if [ "$git_hooks_pytest_cov_lines" -gt 120 ]; then
    git_hooks_log_warn "pytest-cov output truncated; lines=$git_hooks_pytest_cov_lines shown=120"
  fi
fi

exit "$git_hooks_pytest_cov_status"
