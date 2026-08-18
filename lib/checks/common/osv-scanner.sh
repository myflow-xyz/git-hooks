#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_osv_scanner_path=$(command -v osv-scanner 2>/dev/null) || git_hooks_osv_scanner_path=

if [ -z "$git_hooks_osv_scanner_path" ] || [ ! -x "$git_hooks_osv_scanner_path" ]; then
  git_hooks_log_warn 'skip osv-scanner: missing or not executable; install: go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest; see: https://github.com/google/osv-scanner'
  exit 0
fi

git_hooks_osv_scanner_run() {
  git_hooks_env_run_project_command \
    "$git_hooks_osv_scanner_path" scan source \
    --format markdown \
    --verbosity error \
    --recursive .
}

git_hooks_osv_scanner_log_failure() {
  if [ "$1" -eq 1 ]; then
    git_hooks_log_error 'osv-scanner found vulnerabilities; exit=1'
    return 0
  fi

  git_hooks_log_error "osv-scanner failed; exit=$1"
}

git_hooks_log_info 'osv-scanner scan source --format markdown --verbosity error --recursive .'

if git_hooks_log_is_verbose; then
  git_hooks_osv_scanner_run
  git_hooks_osv_scanner_status=$?
  if [ "$git_hooks_osv_scanner_status" -ne 0 ]; then
    git_hooks_osv_scanner_log_failure "$git_hooks_osv_scanner_status"
  fi
  exit "$git_hooks_osv_scanner_status"
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_osv_scanner_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for osv-scanner output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_osv_scanner_output"' || exit $?

git_hooks_osv_scanner_run >"$git_hooks_osv_scanner_output" 2>&1
git_hooks_osv_scanner_status=$?

if [ "$git_hooks_osv_scanner_status" -eq 0 ]; then
  exit 0
fi

git_hooks_osv_scanner_log_failure "$git_hooks_osv_scanner_status"

if [ -s "$git_hooks_osv_scanner_output" ]; then
  command sed -n '1,120p' "$git_hooks_osv_scanner_output" >&2
  git_hooks_osv_scanner_lines=$(command wc -l <"$git_hooks_osv_scanner_output" | command tr -d ' ')
  if [ "$git_hooks_osv_scanner_lines" -gt 120 ]; then
    git_hooks_log_warn "osv-scanner output truncated; lines=$git_hooks_osv_scanner_lines shown=120"
  fi
fi

exit "$git_hooks_osv_scanner_status"
