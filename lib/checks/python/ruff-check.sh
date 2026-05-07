#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_ruff_check_files=$(git_hooks_git_staged_text_files_by_extension py pyi)
git_hooks_ruff_check_status=0

if [ -z "$git_hooks_ruff_check_files" ]; then
  git_hooks_log_skip 'ruff-check; no staged Python files'
  exit 0
fi

git_hooks_python_require_tool 'ruff-check' ruff 'uv add --dev ruff'
git_hooks_ruff_check_require_status=$?
if [ "$git_hooks_ruff_check_require_status" -eq 1 ]; then
  exit 0
elif [ "$git_hooks_ruff_check_require_status" -ne 0 ]; then
  exit "$git_hooks_ruff_check_require_status"
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_ruff_check_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-ruff-check.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for ruff-check output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_ruff_check_output"' || exit $?

while IFS= read -r git_hooks_ruff_check_file || [ -n "$git_hooks_ruff_check_file" ]; do
  [ -n "$git_hooks_ruff_check_file" ] || continue

  if git_hooks_log_is_verbose; then
    git_hooks_python_run ruff check --no-cache "$git_hooks_ruff_check_file"
    git_hooks_ruff_check_current_status=$?
  else
    git_hooks_python_run ruff check --no-cache "$git_hooks_ruff_check_file" >>"$git_hooks_ruff_check_output" 2>&1
    git_hooks_ruff_check_current_status=$?
  fi

  if [ "$git_hooks_ruff_check_current_status" -ne 0 ] && [ "$git_hooks_ruff_check_status" -eq 0 ]; then
    git_hooks_ruff_check_status=$git_hooks_ruff_check_current_status
  fi
done <<EOF
$git_hooks_ruff_check_files
EOF

if [ "$git_hooks_ruff_check_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "ruff-check failed; exit=$git_hooks_ruff_check_status"

if [ -s "$git_hooks_ruff_check_output" ]; then
  command sed -n '1,120p' "$git_hooks_ruff_check_output" >&2
  git_hooks_ruff_check_lines=$(command wc -l <"$git_hooks_ruff_check_output" | command tr -d ' ')
  if [ "$git_hooks_ruff_check_lines" -gt 120 ]; then
    git_hooks_log_warn "ruff-check output truncated; lines=$git_hooks_ruff_check_lines shown=120"
  fi
fi

exit "$git_hooks_ruff_check_status"
