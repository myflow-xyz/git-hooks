#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
GIT_HOOKS_GOLANG_DIR=${GIT_HOOKS_GOLANG_DIR:-$(CDPATH='' cd -- "$(dirname "$0")" && pwd)}
. "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_goimports_files=$(git_hooks_git_staged_text_files_by_extension go)
git_hooks_goimports_status=0

if [ -z "$git_hooks_goimports_files" ]; then
  git_hooks_log_skip 'goimports; no staged Go files'
  exit 0
fi

if ! command -v goimports >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'goimports' 'goimports' 'go install golang.org/x/tools/cmd/goimports@latest'
  exit 0
fi

git_hooks_golang_prepare_runtime_dirs || exit $?

git_hooks_log_info 'goimports check staged Go files'

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_goimports_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-goimports.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for goimports output'
  exit 2
}
git_hooks_goimports_error=$(mktemp "${TMPDIR:-/tmp}/git-hooks-goimports-error.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for goimports error output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_goimports_output" "$git_hooks_goimports_error" "$git_hooks_goimports_output.current" "$git_hooks_goimports_error.current"' || exit $?

while IFS= read -r git_hooks_goimports_file || [ -n "$git_hooks_goimports_file" ]; do
  [ -n "$git_hooks_goimports_file" ] || continue

  command goimports -l "$git_hooks_goimports_file" >"$git_hooks_goimports_output.current" 2>"$git_hooks_goimports_error.current"
  git_hooks_goimports_current_status=$?

  if git_hooks_log_is_verbose && [ -s "$git_hooks_goimports_output.current" ]; then
    command cat "$git_hooks_goimports_output.current"
  fi
  if git_hooks_log_is_verbose && [ -s "$git_hooks_goimports_error.current" ]; then
    command cat "$git_hooks_goimports_error.current" >&2
  fi

  if [ "$git_hooks_goimports_current_status" -ne 0 ] && [ "$git_hooks_goimports_status" -eq 0 ]; then
    git_hooks_goimports_status=$git_hooks_goimports_current_status
  fi

  if [ -s "$git_hooks_goimports_output.current" ]; then
    command cat "$git_hooks_goimports_output.current" >>"$git_hooks_goimports_output"
  fi
  if [ "$git_hooks_goimports_current_status" -ne 0 ] && [ -s "$git_hooks_goimports_error.current" ]; then
    command cat "$git_hooks_goimports_error.current" >>"$git_hooks_goimports_error"
  fi

  command rm -f "$git_hooks_goimports_output.current" "$git_hooks_goimports_error.current"
done <<EOF
$git_hooks_goimports_files
EOF

if [ -s "$git_hooks_goimports_output" ] && [ "$git_hooks_goimports_status" -eq 0 ]; then
  git_hooks_goimports_status=1
fi

if [ "$git_hooks_goimports_status" -ne 0 ]; then
  git_hooks_log_error "goimports failed; exit=$git_hooks_goimports_status"
  if [ -s "$git_hooks_goimports_output" ]; then
    command sed -n '1,120p' "$git_hooks_goimports_output" >&2
    git_hooks_goimports_lines=$(command wc -l <"$git_hooks_goimports_output" | command tr -d ' ')
    if [ "$git_hooks_goimports_lines" -gt 120 ]; then
      git_hooks_log_warn "goimports output truncated; lines=$git_hooks_goimports_lines shown=120"
    fi
  fi
  if [ -s "$git_hooks_goimports_error" ]; then
    command sed -n '1,120p' "$git_hooks_goimports_error" >&2
  fi
fi

exit "$git_hooks_goimports_status"
