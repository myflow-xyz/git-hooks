#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/log.sh" || exit $?

git_hooks_commit_msg_usage() {
  printf '%s\n' 'Usage: commit-msg.sh <commit-message-file>'
}

git_hooks_commit_msg_info() {
  printf '%s: info: %s\n' "$(git_hooks_log_prefix)" "$*" >&2
}

git_hooks_commit_msg_type_is_allowed() {
  case "$1" in
  feat | fix | docs | style | refactor | perf | test | build | ci | chore | revert)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

git_hooks_commit_msg_invalid_cause() {
  git_hooks_commit_msg_subject_to_check=$1

  if [ -z "$git_hooks_commit_msg_subject_to_check" ]; then
    printf '%s\n' 'subject is empty'
    return 0
  fi

  case "$git_hooks_commit_msg_subject_to_check" in
  *': '*)
    git_hooks_commit_msg_prefix=${git_hooks_commit_msg_subject_to_check%%: *}
    git_hooks_commit_msg_description=${git_hooks_commit_msg_subject_to_check#*: }
    ;;
  *)
    printf '%s\n' "missing ': ' separator"
    return 0
    ;;
  esac

  git_hooks_commit_msg_type=${git_hooks_commit_msg_prefix%%(*}
  git_hooks_commit_msg_type=${git_hooks_commit_msg_type%!}

  if ! git_hooks_commit_msg_type_is_allowed "$git_hooks_commit_msg_type"; then
    printf '%s\n' 'unknown type'
    return 0
  fi

  git_hooks_commit_msg_prefix_core=${git_hooks_commit_msg_prefix%!}
  git_hooks_commit_msg_scope=${git_hooks_commit_msg_prefix_core#"$git_hooks_commit_msg_type("}

  if [ "$git_hooks_commit_msg_scope" = "$git_hooks_commit_msg_prefix_core" ]; then
    printf '%s\n' 'scope is required'
    return 0
  fi

  case "$git_hooks_commit_msg_scope" in
  *')')
    git_hooks_commit_msg_scope=${git_hooks_commit_msg_scope%)}
    ;;
  *)
    printf '%s\n' 'scope is invalid'
    return 0
    ;;
  esac

  if [ -z "$git_hooks_commit_msg_scope" ]; then
    printf '%s\n' 'scope is required'
    return 0
  fi

  if ! printf '%s\n' "$git_hooks_commit_msg_scope" | command grep -Eq '^[^()[:space:]]+$'; then
    printf '%s\n' 'scope is invalid'
    return 0
  fi

  case "$git_hooks_commit_msg_description" in
  '' | [[:space:]]*)
    printf '%s\n' 'description is required'
    return 0
    ;;
  esac

  printf '%s\n' 'format is invalid'
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
  command grep -Eq "^($git_hooks_commit_msg_allowed_types)\([^()[:space:]]+\)!?: [^[:space:]].*$"; then
  git_hooks_commit_msg_cause=$(git_hooks_commit_msg_invalid_cause "$git_hooks_commit_msg_subject")
  git_hooks_log_error "invalid commit subject: $git_hooks_commit_msg_cause"
  git_hooks_commit_msg_info "expected subject: $git_hooks_commit_msg_expected; allowed types: $git_hooks_commit_msg_allowed_types"
  exit 1
fi
