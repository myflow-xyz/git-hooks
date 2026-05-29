#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
# shellcheck source=lib/common/env.sh
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_codegraph_initialized() {
  [ -f .codegraph/codegraph.db ]
}

git_hooks_codegraph_run() {
  git_hooks_env_run_project_command codegraph "$@" </dev/null
}

git_hooks_codegraph_replay_output() {
  [ "$#" -eq 1 ] || {
    git_hooks_log_error 'Usage: git_hooks_codegraph_replay_output <output-file>'
    return 2
  }

  [ -s "$1" ] || return 0

  command sed -n '1,120p' "$1" >&2
  git_hooks_codegraph_lines=$(command wc -l <"$1" | command tr -d ' ')
  if [ "$git_hooks_codegraph_lines" -gt 120 ]; then
    git_hooks_log_warn "codegraph-build-index output truncated; lines=$git_hooks_codegraph_lines shown=120"
  fi
}

if ! command -v codegraph >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'codegraph-build-index' 'codegraph' 'npm install -g @colbymchenry/codegraph'
  exit 0
fi

if git_hooks_codegraph_initialized; then
  git_hooks_codegraph_command='codegraph index --force .'
  set -- index --force .
else
  git_hooks_codegraph_command='codegraph init -i .'
  set -- init -i .
fi

git_hooks_log_info "$git_hooks_codegraph_command"

if git_hooks_log_is_verbose; then
  git_hooks_codegraph_run "$@"
  git_hooks_codegraph_status=$?
  if [ "$git_hooks_codegraph_status" -ne 0 ]; then
    git_hooks_log_error "codegraph-build-index failed; exit=$git_hooks_codegraph_status"
  fi
  exit "$git_hooks_codegraph_status"
fi

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_codegraph_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for codegraph-build-index output'
  exit 2
}
# shellcheck disable=SC2016
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_codegraph_output"' || exit $?

git_hooks_codegraph_run "$@" >"$git_hooks_codegraph_output" 2>&1
git_hooks_codegraph_status=$?

if [ "$git_hooks_codegraph_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "codegraph-build-index failed; exit=$git_hooks_codegraph_status"
git_hooks_codegraph_replay_output "$git_hooks_codegraph_output" || exit $?

exit "$git_hooks_codegraph_status"
