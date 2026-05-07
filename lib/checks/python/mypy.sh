#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_mypy_has_python_project() {
  [ -f pyproject.toml ] || [ -f setup.py ] || [ -f setup.cfg ] || [ -f mypy.ini ] ||
    git_hooks_git_tracked_files | command grep -E '\.pyi?$' >/dev/null 2>&1
}

if ! git_hooks_mypy_has_python_project; then
  git_hooks_log_skip 'mypy; Python project files missing'
  exit 0
fi

git_hooks_python_require_tool mypy mypy 'uv add --dev mypy'
git_hooks_mypy_require_status=$?
if [ "$git_hooks_mypy_require_status" -eq 1 ]; then
  exit 0
elif [ "$git_hooks_mypy_require_status" -ne 0 ]; then
  exit "$git_hooks_mypy_require_status"
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_mypy_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-mypy.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for mypy output'
  exit 2
}
git_hooks_mypy_cache=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-mypy-cache.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary directory for mypy cache'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -rf "$git_hooks_mypy_output" "$git_hooks_mypy_cache"' || exit $?

if git_hooks_log_is_verbose; then
  git_hooks_python_run mypy --cache-dir "$git_hooks_mypy_cache" .
  exit $?
fi

git_hooks_python_run mypy --cache-dir "$git_hooks_mypy_cache" . >"$git_hooks_mypy_output" 2>&1
git_hooks_mypy_status=$?

if [ "$git_hooks_mypy_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "mypy failed; exit=$git_hooks_mypy_status"

if [ -s "$git_hooks_mypy_output" ]; then
  command sed -n '1,120p' "$git_hooks_mypy_output" >&2
  git_hooks_mypy_lines=$(command wc -l <"$git_hooks_mypy_output" | command tr -d ' ')
  if [ "$git_hooks_mypy_lines" -gt 120 ]; then
    git_hooks_log_warn "mypy output truncated; lines=$git_hooks_mypy_lines shown=120"
  fi
fi

exit "$git_hooks_mypy_status"
