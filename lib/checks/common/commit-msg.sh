#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/log.sh" || exit $?

git_hooks_commit_msg_usage() {
  printf '%s\n' 'Usage: commit-msg.sh <commit-message-file>'
}

git_hooks_commit_msg_allowed_types='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
git_hooks_commit_msg_expected='<type>(scope): brief description'

if [ "$#" -lt 1 ]; then
  git_hooks_commit_msg_usage >&2
  exit 2
fi

git_hooks_commit_msg_file=$1

if [ ! -f "$git_hooks_commit_msg_file" ]; then
  git_hooks_log_error "commit message file not found: $git_hooks_commit_msg_file"
  exit 1
fi

git_hooks_commit_msg_subject=$(command sed -n '1p' "$git_hooks_commit_msg_file")

if ! printf '%s\n' "$git_hooks_commit_msg_subject" |
  command grep -Eq "^($git_hooks_commit_msg_allowed_types)\([^()[:space:]]+\)!?: [^[:space:]].*$"
then
  git_hooks_log_error "invalid commit message subject: ${git_hooks_commit_msg_subject:-'(empty)'}"
  git_hooks_log_error "expected: $git_hooks_commit_msg_expected"
  git_hooks_log_error 'scope is mandatory; example: feat(config): add git hook checks'
  git_hooks_log_error "allowed types: $git_hooks_commit_msg_allowed_types"
  exit 1
fi
