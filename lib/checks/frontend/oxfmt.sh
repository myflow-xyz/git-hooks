#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_oxfmt_files=$(git_hooks_git_staged_text_files_by_extension js jsx ts tsx mjs cjs mts cts)

if [ -z "$git_hooks_oxfmt_files" ]; then
  git_hooks_log_skip 'oxfmt; no staged frontend source files'
  exit 0
fi

if [ ! -f package.json ]; then
  git_hooks_log_skip 'oxfmt; package.json missing'
  exit 0
fi

if ! command -v pnpm >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'oxfmt' 'pnpm' 'corepack enable pnpm'
  exit 0
fi

if [ ! -x node_modules/.bin/oxfmt ]; then
  git_hooks_log_skip_missing_tool 'oxfmt' 'node_modules/.bin/oxfmt' 'pnpm add -D oxfmt'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

if git_hooks_log_is_verbose; then
  git_hooks_oxfmt_status=0
  while IFS= read -r git_hooks_oxfmt_file || [ -n "$git_hooks_oxfmt_file" ]; do
    [ -n "$git_hooks_oxfmt_file" ] || continue
    git_hooks_env_run_project_command pnpm exec oxfmt --check "$git_hooks_oxfmt_file"
    git_hooks_oxfmt_current_status=$?
    if [ "$git_hooks_oxfmt_current_status" -ge 128 ] 2>/dev/null; then
      exit "$git_hooks_oxfmt_current_status"
    fi
    if [ "$git_hooks_oxfmt_current_status" -ne 0 ] && [ "$git_hooks_oxfmt_status" -eq 0 ]; then
      git_hooks_oxfmt_status=$git_hooks_oxfmt_current_status
    fi
  done <<EOF
$git_hooks_oxfmt_files
EOF
  exit "$git_hooks_oxfmt_status"
fi

git_hooks_oxfmt_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for oxfmt output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_oxfmt_output"' || exit $?

git_hooks_oxfmt_status=0
while IFS= read -r git_hooks_oxfmt_file || [ -n "$git_hooks_oxfmt_file" ]; do
  [ -n "$git_hooks_oxfmt_file" ] || continue
  git_hooks_env_run_project_command pnpm exec oxfmt --check "$git_hooks_oxfmt_file" >>"$git_hooks_oxfmt_output" 2>&1
  git_hooks_oxfmt_current_status=$?
  if [ "$git_hooks_oxfmt_current_status" -ge 128 ] 2>/dev/null; then
    exit "$git_hooks_oxfmt_current_status"
  fi
  if [ "$git_hooks_oxfmt_current_status" -ne 0 ] && [ "$git_hooks_oxfmt_status" -eq 0 ]; then
    git_hooks_oxfmt_status=$git_hooks_oxfmt_current_status
  fi
done <<EOF
$git_hooks_oxfmt_files
EOF

if [ "$git_hooks_oxfmt_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "oxfmt failed; exit=$git_hooks_oxfmt_status"

if [ -s "$git_hooks_oxfmt_output" ]; then
  command sed -n '1,120p' "$git_hooks_oxfmt_output" >&2
  git_hooks_oxfmt_lines=$(command wc -l <"$git_hooks_oxfmt_output" | command tr -d ' ')
  if [ "$git_hooks_oxfmt_lines" -gt 120 ]; then
    git_hooks_log_warn "oxfmt output truncated; lines=$git_hooks_oxfmt_lines shown=120"
  fi
fi

exit "$git_hooks_oxfmt_status"
