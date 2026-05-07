#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

if ! git_hooks_git_has_staged_files; then
  git_hooks_log_skip 'whitespace; no staged files'
  exit 0
fi

command git diff --cached --check
