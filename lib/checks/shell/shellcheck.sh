#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_files.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_shellcheck_files=$(git_hooks_shell_staged_sh_bash_files)
git_hooks_shellcheck_status=0

if [ -z "$git_hooks_shellcheck_files" ]; then
  git_hooks_log_skip 'shellcheck; no staged .sh or .bash files'
  exit 0
fi

if ! command -v shellcheck >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'shellcheck' 'shellcheck' 'brew install shellcheck'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_shellcheck_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for shellcheck output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_shellcheck_output" "$git_hooks_shellcheck_output.current"' || exit $?

while IFS= read -r git_hooks_shellcheck_file || [ -n "$git_hooks_shellcheck_file" ]; do
  [ -n "$git_hooks_shellcheck_file" ] || continue
  git_hooks_shellcheck_shell=$(git_hooks_shell_staged_shell_dialect "$git_hooks_shellcheck_file")
  if [ "$git_hooks_shellcheck_shell" = zsh ]; then
    git_hooks_log_skip "shellcheck; zsh syntax unsupported: $git_hooks_shellcheck_file"
    continue
  fi

  if git_hooks_log_is_verbose; then
    command shellcheck --severity=warning -s "$git_hooks_shellcheck_shell" "$git_hooks_shellcheck_file"
    git_hooks_shellcheck_current_status=$?
  else
    command shellcheck --severity=warning -s "$git_hooks_shellcheck_shell" "$git_hooks_shellcheck_file" >"$git_hooks_shellcheck_output.current" 2>&1
    git_hooks_shellcheck_current_status=$?
  fi

  if [ "$git_hooks_shellcheck_current_status" -ne 0 ] && [ "$git_hooks_shellcheck_status" -eq 0 ]; then
    git_hooks_shellcheck_status=$git_hooks_shellcheck_current_status
  fi
  if [ -s "$git_hooks_shellcheck_output.current" ]; then
    command cat "$git_hooks_shellcheck_output.current" >>"$git_hooks_shellcheck_output"
  fi
  command rm -f "$git_hooks_shellcheck_output.current"
done <<EOF
$git_hooks_shellcheck_files
EOF

if [ "$git_hooks_shellcheck_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "shellcheck failed; exit=$git_hooks_shellcheck_status"

if [ -s "$git_hooks_shellcheck_output" ]; then
  command sed -n '1,120p' "$git_hooks_shellcheck_output" >&2
  git_hooks_shellcheck_lines=$(command wc -l <"$git_hooks_shellcheck_output" | command tr -d ' ')
  if [ "$git_hooks_shellcheck_lines" -gt 120 ]; then
    git_hooks_log_warn "shellcheck output truncated; lines=$git_hooks_shellcheck_lines shown=120"
  fi
fi

exit "$git_hooks_shellcheck_status"
