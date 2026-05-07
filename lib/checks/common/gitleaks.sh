#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

if ! git_hooks_git_has_staged_files; then
  git_hooks_log_skip 'gitleaks; no staged files'
  exit 0
fi

if ! command -v gitleaks >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'gitleaks' 'gitleaks' 'brew install gitleaks'
  exit 0
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

if git_hooks_log_is_verbose; then
  command gitleaks protect --staged --redact --verbose
  exit $?
fi

git_hooks_gitleaks_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-gitleaks.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for gitleaks output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_gitleaks_output"' || exit $?

command gitleaks protect --staged --redact >"$git_hooks_gitleaks_output" 2>&1
git_hooks_gitleaks_status=$?

if [ "$git_hooks_gitleaks_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "gitleaks failed; exit=$git_hooks_gitleaks_status"

if [ -s "$git_hooks_gitleaks_output" ]; then
  sed -n '1,120p' "$git_hooks_gitleaks_output" >&2
  git_hooks_gitleaks_lines=$(wc -l <"$git_hooks_gitleaks_output" | tr -d ' ')
  if [ "$git_hooks_gitleaks_lines" -gt 120 ]; then
    git_hooks_log_warn "gitleaks output truncated; lines=$git_hooks_gitleaks_lines shown=120"
  fi
fi

exit "$git_hooks_gitleaks_status"
