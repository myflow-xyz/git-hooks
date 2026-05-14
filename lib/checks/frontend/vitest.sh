#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
# shellcheck source=lib/common/env.sh
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

if [ ! -f package.json ]; then
  git_hooks_log_skip 'vitest; package.json missing'
  exit 0
fi

if ! command -v pnpm >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'vitest' 'pnpm' 'corepack enable pnpm'
  exit 0
fi

if [ ! -x node_modules/.bin/vitest ]; then
  git_hooks_log_skip_missing_tool 'vitest' 'node_modules/.bin/vitest' 'pnpm add -D vitest'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_vitest_no_test_files() {
  [ "$#" -eq 2 ] || return 2
  [ "$1" -eq 1 ] || return 1
  command grep -F 'No test files found' "$2" >/dev/null 2>&1
}

git_hooks_vitest_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for vitest output'
  exit 2
}
# shellcheck disable=SC2016
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_vitest_output"' || exit $?

git_hooks_vitest_verbose=0
if git_hooks_log_is_verbose; then
  git_hooks_vitest_verbose=1
fi

command pnpm exec vitest run >"$git_hooks_vitest_output" 2>&1
git_hooks_vitest_status=$?

if [ "$git_hooks_vitest_status" -eq 0 ]; then
  if [ "$git_hooks_vitest_verbose" -eq 1 ] && [ -s "$git_hooks_vitest_output" ]; then
    command cat "$git_hooks_vitest_output"
  fi
  exit 0
fi

if git_hooks_vitest_no_test_files "$git_hooks_vitest_status" "$git_hooks_vitest_output"; then
  git_hooks_log_skip 'vitest; no test files found'
  exit 0
fi

if [ "$git_hooks_vitest_verbose" -eq 1 ]; then
  if [ -s "$git_hooks_vitest_output" ]; then
    command cat "$git_hooks_vitest_output" >&2
  fi
  exit "$git_hooks_vitest_status"
fi

git_hooks_log_error "vitest failed; exit=$git_hooks_vitest_status"

if [ -s "$git_hooks_vitest_output" ]; then
  command sed -n '1,120p' "$git_hooks_vitest_output" >&2
  git_hooks_vitest_lines=$(command wc -l <"$git_hooks_vitest_output" | command tr -d ' ')
  if [ "$git_hooks_vitest_lines" -gt 120 ]; then
    git_hooks_log_warn "vitest output truncated; lines=$git_hooks_vitest_lines shown=120"
  fi
fi

exit "$git_hooks_vitest_status"
