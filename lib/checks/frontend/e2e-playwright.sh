#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
# shellcheck source=lib/common/env.sh
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_playwright_has_config() {
  for git_hooks_playwright_config in \
    playwright.config.js \
    playwright.config.cjs \
    playwright.config.mjs \
    playwright.config.ts \
    playwright.config.cts \
    playwright.config.mts; do
    [ -f "$git_hooks_playwright_config" ] && return 0
  done

  return 1
}

git_hooks_playwright_info() {
  printf '%s: info: %s\n' "$(git_hooks_log_prefix)" "$*" >&2
}

git_hooks_playwright_has_tracked_e2e_tests() {
  git_hooks_git_tracked_files |
    command grep -E '(^|/)(e2e|tests/e2e|playwright)(/.*)?\.(e2e|spec|test)\.(cjs|cts|js|jsx|mjs|mts|ts|tsx)$' >/dev/null 2>&1
}

git_hooks_playwright_has_e2e_signal() {
  git_hooks_playwright_has_config || git_hooks_playwright_has_tracked_e2e_tests
}

git_hooks_playwright_no_test_files() {
  [ "$#" -eq 2 ] || return 2
  [ "$1" -eq 1 ] || return 1
  command grep -F 'No tests found' "$2" >/dev/null 2>&1
}

git_hooks_playwright_run() (
  unset GIT_HOOK_PHASE
  unset GIT_HOOKS_HOME
  unset GIT_HOOKS_COMMON_DIR
  unset GIT_HOOK_REPO_ROOT
  unset GIT_HOOK_PROJECT_DIR
  unset GIT_HOOK_PROJECT_ENV
  unset GIT_HOOK_PROJECT_CONF
  unset GIT_HOOK_PROFILES
  unset GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS
  unset GIT_HOOK_PRE_PUSH_EXTRA_CHECKS
  unset GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS
  unset GIT_HOOK_EXTRA_CHECKS
  unset GIT_HOOK_VERBOSE

  command pnpm exec playwright test
)

if ! git_hooks_playwright_has_e2e_signal; then
  git_hooks_log_skip 'playwright; e2e test files missing'
  exit 0
fi

if [ ! -f package.json ]; then
  git_hooks_log_skip 'playwright; package.json missing'
  exit 0
fi

if ! command -v pnpm >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'playwright' 'pnpm' 'corepack enable pnpm'
  exit 0
fi

if [ ! -x node_modules/.bin/playwright ]; then
  git_hooks_playwright_info 'skip playwright: missing node_modules/.bin/playwright; install: pnpm add -D @playwright/test'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_playwright_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for Playwright output'
  exit 2
}
# shellcheck disable=SC2016
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_playwright_output"' || exit $?

git_hooks_playwright_verbose=0
if git_hooks_log_is_verbose; then
  git_hooks_playwright_verbose=1
fi

git_hooks_playwright_run >"$git_hooks_playwright_output" 2>&1
git_hooks_playwright_status=$?

if [ "$git_hooks_playwright_status" -eq 0 ]; then
  if [ "$git_hooks_playwright_verbose" -eq 1 ] && [ -s "$git_hooks_playwright_output" ]; then
    command cat "$git_hooks_playwright_output"
  fi
  exit 0
fi

if git_hooks_playwright_no_test_files "$git_hooks_playwright_status" "$git_hooks_playwright_output"; then
  git_hooks_log_skip 'playwright; no e2e test files found'
  exit 0
fi

if [ "$git_hooks_playwright_verbose" -eq 1 ]; then
  if [ -s "$git_hooks_playwright_output" ]; then
    command cat "$git_hooks_playwright_output" >&2
  fi
  exit "$git_hooks_playwright_status"
fi

git_hooks_log_error "playwright failed; exit=$git_hooks_playwright_status"

if [ -s "$git_hooks_playwright_output" ]; then
  command sed -n '1,120p' "$git_hooks_playwright_output" >&2
  git_hooks_playwright_lines=$(command wc -l <"$git_hooks_playwright_output" | command tr -d ' ')
  if [ "$git_hooks_playwright_lines" -gt 120 ]; then
    git_hooks_log_warn "playwright output truncated; lines=$git_hooks_playwright_lines shown=120"
  fi
fi

exit "$git_hooks_playwright_status"
