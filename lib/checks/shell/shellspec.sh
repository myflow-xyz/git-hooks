#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_files.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_shellspec_dirs=$(git_hooks_shell_tracked_shellspec_dirs)
git_hooks_shellspec_status=0

git_hooks_shellspec_run() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_shellspec_run <dir>'
    return 2
  fi

  (
    cd "$1" || return 1

    # Project ShellSpec suites should run like manual tests, not inherit hook policy.
    git_hooks_env_run_project_command shellspec
  )
}

if [ -z "$git_hooks_shellspec_dirs" ]; then
  git_hooks_log_skip 'shellspec; no tracked .shellspec files'
  exit 0
fi

if ! command -v shellspec >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'shellspec' 'shellspec' 'brew install shellspec'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_shellspec_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for shellspec output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_shellspec_output" "$git_hooks_shellspec_output.current"' || exit $?

while IFS= read -r git_hooks_shellspec_dir || [ -n "$git_hooks_shellspec_dir" ]; do
  [ -n "$git_hooks_shellspec_dir" ] || continue
  git_hooks_log_info "shellspec; dir=$git_hooks_shellspec_dir"

  if git_hooks_log_is_verbose; then
    git_hooks_shellspec_run "$git_hooks_shellspec_dir"
    git_hooks_shellspec_current_status=$?
  else
    git_hooks_shellspec_run "$git_hooks_shellspec_dir" >"$git_hooks_shellspec_output.current" 2>&1
    git_hooks_shellspec_current_status=$?
  fi

  if [ "$git_hooks_shellspec_current_status" -ne 0 ]; then
    if [ "$git_hooks_shellspec_current_status" -ge 128 ] 2>/dev/null; then
      git_hooks_log_error "shellspec interrupted; dir=$git_hooks_shellspec_dir; exit=$git_hooks_shellspec_current_status"
      command rm -f "$git_hooks_shellspec_output.current"
      exit "$git_hooks_shellspec_current_status"
    fi

    if [ "$git_hooks_shellspec_status" -eq 0 ]; then
      git_hooks_shellspec_status=$git_hooks_shellspec_current_status
    fi

    git_hooks_log_error "shellspec failed; dir=$git_hooks_shellspec_dir; exit=$git_hooks_shellspec_current_status"
    if [ -s "$git_hooks_shellspec_output.current" ]; then
      command sed -n '1,120p' "$git_hooks_shellspec_output.current" >&2
      git_hooks_shellspec_lines=$(command wc -l <"$git_hooks_shellspec_output.current" | command tr -d ' ')
      if [ "$git_hooks_shellspec_lines" -gt 120 ]; then
        git_hooks_log_warn "shellspec output truncated; lines=$git_hooks_shellspec_lines shown=120"
      fi
    fi
  fi

  command rm -f "$git_hooks_shellspec_output.current"
done <<EOF
$git_hooks_shellspec_dirs
EOF

exit "$git_hooks_shellspec_status"
