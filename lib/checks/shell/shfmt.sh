#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_files.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_shfmt_files=$(git_hooks_shell_staged_sh_bash_files)
git_hooks_shfmt_status=0

if [ -z "$git_hooks_shfmt_files" ]; then
  git_hooks_log_skip 'shfmt; no staged .sh or .bash files'
  exit 0
fi

if ! command -v shfmt >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'shfmt' 'shfmt' 'go install mvdan.cc/sh/v3/cmd/shfmt@latest'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_shfmt_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-shfmt.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for shfmt output'
  exit 2
}
git_hooks_shfmt_error=$(mktemp "${TMPDIR:-/tmp}/git-hooks-shfmt-error.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for shfmt error output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_shfmt_output" "$git_hooks_shfmt_error" "$git_hooks_shfmt_output.current" "$git_hooks_shfmt_error.current"' || exit $?

while IFS= read -r git_hooks_shfmt_file || [ -n "$git_hooks_shfmt_file" ]; do
  [ -n "$git_hooks_shfmt_file" ] || continue

  git_hooks_env_run_project_command shfmt -l "$git_hooks_shfmt_file" >"$git_hooks_shfmt_output.current" 2>"$git_hooks_shfmt_error.current"
  git_hooks_shfmt_current_status=$?

  if git_hooks_log_is_verbose && [ -s "$git_hooks_shfmt_output.current" ]; then
    command cat "$git_hooks_shfmt_output.current"
  fi
  if git_hooks_log_is_verbose && [ -s "$git_hooks_shfmt_error.current" ]; then
    command cat "$git_hooks_shfmt_error.current" >&2
  fi

  if [ "$git_hooks_shfmt_current_status" -ne 0 ] && [ "$git_hooks_shfmt_status" -eq 0 ]; then
    git_hooks_shfmt_status=$git_hooks_shfmt_current_status
  fi

  if [ -s "$git_hooks_shfmt_output.current" ]; then
    command cat "$git_hooks_shfmt_output.current" >>"$git_hooks_shfmt_output"
  fi
  if [ "$git_hooks_shfmt_current_status" -ne 0 ] && [ -s "$git_hooks_shfmt_error.current" ]; then
    command cat "$git_hooks_shfmt_error.current" >>"$git_hooks_shfmt_error"
  fi

  command rm -f "$git_hooks_shfmt_output.current" "$git_hooks_shfmt_error.current"
done <<EOF
$git_hooks_shfmt_files
EOF

if [ -s "$git_hooks_shfmt_output" ] && [ "$git_hooks_shfmt_status" -eq 0 ]; then
  git_hooks_shfmt_status=1
fi

if [ "$git_hooks_shfmt_status" -ne 0 ]; then
  git_hooks_log_error "shfmt failed; exit=$git_hooks_shfmt_status"
  if [ -s "$git_hooks_shfmt_output" ]; then
    command sed -n '1,120p' "$git_hooks_shfmt_output" >&2
    git_hooks_shfmt_lines=$(command wc -l <"$git_hooks_shfmt_output" | command tr -d ' ')
    if [ "$git_hooks_shfmt_lines" -gt 120 ]; then
      git_hooks_log_warn "shfmt output truncated; lines=$git_hooks_shfmt_lines shown=120"
    fi
  fi
  if [ -s "$git_hooks_shfmt_error" ]; then
    command sed -n '1,120p' "$git_hooks_shfmt_error" >&2
  fi
fi

exit "$git_hooks_shfmt_status"
