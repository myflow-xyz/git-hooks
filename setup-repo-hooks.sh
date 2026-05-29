#!/usr/bin/env sh

set -u

git_hooks_install_usage() {
  cat <<'EOF'
Usage: setup-repo-hooks.sh [--check | --update] [--repo <path>] [--hooks <hooks>] [--profiles <profiles>]

Bootstrap repo-local Git hooks for a project.

Typical example:
  setup-repo-hooks.sh
  setup-repo-hooks.sh --profiles "common shell"
  setup-repo-hooks.sh --check --profiles "common shell"
  setup-repo-hooks.sh --update
  setup-repo-hooks.sh --repo /path/to/repo --profiles "common shell"
  setup-repo-hooks.sh --hooks "pre-commit commit-msg" --profiles "common shell"

Options:
  --check                 verify repo-local hook setup without changing files
  --update                refresh existing repo-local wrappers only
  --repo <path>           target repository; defaults to current Git repo
  --hooks <hooks>         explicit wrapper phases; default is inferred
                          from profiles when omitted
  --profiles <profiles>   built-in profiles; default: common
  -h, --help              show this help

Default hook inference:
  common                  pre-commit pre-push commit-msg
  common <stack-profile>  pre-commit pre-push commit-msg when any profile
                          has pre-push checks
EOF
}

git_hooks_install_error() {
  printf 'git-hooks: error: %s\n' "$*" >&2
}

git_hooks_install_info() {
  printf 'git-hooks: %s\n' "$*"
}

git_hooks_install_repo_root() {
  if [ -n "${git_hooks_install_repo:-}" ]; then
    (cd "$git_hooks_install_repo" 2>/dev/null && command git rev-parse --show-toplevel 2>/dev/null)
    return $?
  fi

  command git rev-parse --show-toplevel 2>/dev/null
}

git_hooks_install_write_project_conf() {
  git_hooks_install_conf=$1
  command mkdir -p "$(command dirname "$git_hooks_install_conf")" || return $?

  cat >"$git_hooks_install_conf" <<EOF
# Repo-local Git hook policy.
GIT_HOOK_PROFILES="$git_hooks_install_profiles"
EOF
}

git_hooks_install_is_default_profiles() {
  [ "$git_hooks_install_profiles" = common ]
}

git_hooks_install_validate_hooks() {
  if [ -z "$git_hooks_install_hooks" ]; then
    git_hooks_install_error 'hooks cannot be empty'
    return 2
  fi

  for git_hooks_install_hook_name in $git_hooks_install_hooks; do
    case "$git_hooks_install_hook_name" in
    pre-commit | pre-push | commit-msg)
      ;;
    *)
      git_hooks_install_error "unknown hook: $git_hooks_install_hook_name"
      return 2
      ;;
    esac
  done
}

git_hooks_install_validate_profiles() {
  if [ -z "$git_hooks_install_profiles" ]; then
    git_hooks_install_error 'profiles cannot be empty'
    return 2
  fi

  git_hooks_install_seen_profiles=

  for git_hooks_install_profile_name in $git_hooks_install_profiles; do
    if [ ! -d "$git_hooks_install_home/profiles/$git_hooks_install_profile_name" ]; then
      git_hooks_install_error "unknown profile: $git_hooks_install_profile_name"
      return 2
    fi

    case " $git_hooks_install_seen_profiles " in
    *" $git_hooks_install_profile_name "*)
      git_hooks_install_error "duplicate profile: $git_hooks_install_profile_name"
      return 2
      ;;
    esac

    git_hooks_install_seen_profiles="$git_hooks_install_seen_profiles $git_hooks_install_profile_name"
  done

  if [ -z "$git_hooks_install_seen_profiles" ]; then
    git_hooks_install_error 'profiles cannot be empty'
    return 2
  fi
}

git_hooks_install_profile_has_pre_push() {
  git_hooks_install_profile_name=$1

  [ -s "$git_hooks_install_home/profiles/$git_hooks_install_profile_name/pre-push.list" ]
}

git_hooks_install_default_hooks_for_profiles() {
  for git_hooks_install_profile_name in $git_hooks_install_profiles; do
    if git_hooks_install_profile_has_pre_push "$git_hooks_install_profile_name"; then
      printf '%s\n' 'pre-commit pre-push commit-msg'
      return 0
    fi
  done

  printf '%s\n' 'pre-commit commit-msg'
}

git_hooks_install_check_file() {
  git_hooks_install_path=$1
  git_hooks_install_label=$2

  if [ ! -f "$git_hooks_install_path" ]; then
    git_hooks_install_error "missing $git_hooks_install_label: $git_hooks_install_path"
    return 1
  fi

  return 0
}

git_hooks_install_check_executable() {
  git_hooks_install_path=$1
  git_hooks_install_label=$2

  git_hooks_install_check_file "$git_hooks_install_path" "$git_hooks_install_label" || return $?

  if [ ! -x "$git_hooks_install_path" ]; then
    git_hooks_install_error "not executable $git_hooks_install_label: $git_hooks_install_path"
    return 1
  fi

  return 0
}

git_hooks_install_check_profiles() {
  git_hooks_install_conf=$1

  if ! command grep -F "GIT_HOOK_PROFILES=\"$git_hooks_install_profiles\"" "$git_hooks_install_conf" >/dev/null 2>&1; then
    git_hooks_install_error "profile mismatch: expected '$git_hooks_install_profiles' in $git_hooks_install_conf"
    return 1
  fi

  return 0
}

git_hooks_install_conf_has_profiles() {
  git_hooks_install_conf=$1
  command grep -E '^[[:space:]]*GIT_HOOK_PROFILES=' "$git_hooks_install_conf" >/dev/null 2>&1
}

git_hooks_install_check_core_hooks_path() {
  git_hooks_install_root=$1
  git_hooks_install_current=$(command git -C "$git_hooks_install_root" config --local --get core.hooksPath 2>/dev/null || printf '')

  if [ "$git_hooks_install_current" != '.githooks' ]; then
    git_hooks_install_error "core.hooksPath mismatch: expected .githooks, got ${git_hooks_install_current:-'(unset)'}"
    return 1
  fi

  return 0
}

git_hooks_install_copy_wrapper() {
  git_hooks_install_hook_name=$1
  git_hooks_install_dest=$git_hooks_install_repo_hooks/$git_hooks_install_hook_name

  if [ -e "$git_hooks_install_dest" ] && [ ! -f "$git_hooks_install_dest" ]; then
    git_hooks_install_error "wrapper path is not a file: $git_hooks_install_dest"
    return 1
  fi

  command cp \
    "$git_hooks_install_home/templates/repo-githooks/$git_hooks_install_hook_name" \
    "$git_hooks_install_dest" || return $?
  command chmod +x "$git_hooks_install_dest"
}

git_hooks_install_check_wrappers() {
  git_hooks_install_status=0

  for git_hooks_install_hook_name in $git_hooks_install_hooks; do
    git_hooks_install_check_executable \
      "$git_hooks_install_repo_hooks/$git_hooks_install_hook_name" \
      "$git_hooks_install_hook_name wrapper" || git_hooks_install_status=1
  done

  return "$git_hooks_install_status"
}

git_hooks_install_update_wrappers() {
  git_hooks_install_updated_wrappers=

  if [ ! -d "$git_hooks_install_repo_hooks" ]; then
    return 0
  fi

  for git_hooks_install_hook_name in pre-commit pre-push commit-msg; do
    [ -e "$git_hooks_install_repo_hooks/$git_hooks_install_hook_name" ] || continue
    git_hooks_install_copy_wrapper "$git_hooks_install_hook_name" || return $?
    git_hooks_install_updated_wrappers="${git_hooks_install_updated_wrappers:+$git_hooks_install_updated_wrappers }$git_hooks_install_hook_name"
  done
}

git_hooks_install_mode=apply
git_hooks_install_hooks=
git_hooks_install_hooks_explicit=0
git_hooks_install_profiles=common
git_hooks_install_profiles_explicit=0
git_hooks_install_repo=

while [ "$#" -gt 0 ]; do
  case "$1" in
  --check)
    if [ "$git_hooks_install_mode" = update ]; then
      git_hooks_install_error 'choose only one mode: --check or --update'
      exit 2
    fi
    git_hooks_install_mode=check
    shift
    ;;
  --update)
    if [ "$git_hooks_install_mode" = check ]; then
      git_hooks_install_error 'choose only one mode: --check or --update'
      exit 2
    fi
    git_hooks_install_mode=update
    shift
    ;;
  --repo)
    if [ "$#" -lt 2 ]; then
      git_hooks_install_usage >&2
      exit 2
    fi
    git_hooks_install_repo=$2
    shift 2
    ;;
  --hooks)
    if [ "$#" -lt 2 ]; then
      git_hooks_install_usage >&2
      exit 2
    fi
    git_hooks_install_hooks=$2
    git_hooks_install_hooks_explicit=1
    shift 2
    ;;
  --profiles)
    if [ "$#" -lt 2 ]; then
      git_hooks_install_usage >&2
      exit 2
    fi
    git_hooks_install_profiles=$2
    git_hooks_install_profiles_explicit=1
    shift 2
    ;;
  -h | --help)
    git_hooks_install_usage
    exit 0
    ;;
  *)
    git_hooks_install_usage >&2
    exit 2
    ;;
  esac
done

git_hooks_install_home=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)

if [ "$git_hooks_install_mode" = update ]; then
  if [ "$git_hooks_install_hooks_explicit" -ne 0 ]; then
    git_hooks_install_error '--hooks cannot be used with --update'
    exit 2
  fi

  if [ "$git_hooks_install_profiles_explicit" -ne 0 ]; then
    git_hooks_install_error '--profiles cannot be used with --update'
    exit 2
  fi
else
  git_hooks_install_validate_profiles || exit $?
fi

git_hooks_install_root=$(git_hooks_install_repo_root) || {
  git_hooks_install_error 'not inside a git repository; pass --repo <path>'
  exit 1
}

if [ "$git_hooks_install_mode" != update ]; then
  if [ "$git_hooks_install_hooks_explicit" -eq 0 ]; then
    git_hooks_install_hooks=$(git_hooks_install_default_hooks_for_profiles)
  fi
  git_hooks_install_validate_hooks || exit $?
fi

git_hooks_install_repo_hooks=$git_hooks_install_root/.githooks
git_hooks_install_project_conf=$git_hooks_install_repo_hooks/project.conf

case "$git_hooks_install_mode" in
check)
  git_hooks_install_status=0
  git_hooks_install_check_wrappers || git_hooks_install_status=1

  if [ -f "$git_hooks_install_project_conf" ]; then
    if git_hooks_install_conf_has_profiles "$git_hooks_install_project_conf"; then
      git_hooks_install_check_profiles "$git_hooks_install_project_conf" || git_hooks_install_status=1
    elif ! git_hooks_install_is_default_profiles; then
      git_hooks_install_check_profiles "$git_hooks_install_project_conf" || git_hooks_install_status=1
    fi
  elif ! git_hooks_install_is_default_profiles; then
    git_hooks_install_check_file "$git_hooks_install_project_conf" 'project config' || git_hooks_install_status=1
  fi

  git_hooks_install_check_core_hooks_path "$git_hooks_install_root" || git_hooks_install_status=1

  if [ "$git_hooks_install_status" -eq 0 ]; then
    git_hooks_install_info "check ok; repo=$git_hooks_install_root; hooks=$git_hooks_install_hooks; profiles=$git_hooks_install_profiles"
  fi
  exit "$git_hooks_install_status"
  ;;
update)
  git_hooks_install_update_wrappers || exit $?
  git_hooks_install_updated_wrappers_label=$git_hooks_install_updated_wrappers
  if [ -z "$git_hooks_install_updated_wrappers_label" ]; then
    git_hooks_install_updated_wrappers_label='(none)'
  fi
  git_hooks_install_info "updated; repo=$git_hooks_install_root; wrappers=$git_hooks_install_updated_wrappers_label"
  exit 0
  ;;
esac

command mkdir -p "$git_hooks_install_repo_hooks" || exit $?
for git_hooks_install_hook_name in $git_hooks_install_hooks; do
  git_hooks_install_copy_wrapper "$git_hooks_install_hook_name" || exit $?
done

if ! git_hooks_install_is_default_profiles; then
  git_hooks_install_write_project_conf "$git_hooks_install_project_conf" || exit $?
fi

command git -C "$git_hooks_install_root" config --local core.hooksPath .githooks || exit $?

git_hooks_install_info "installed; repo=$git_hooks_install_root; hooks=$git_hooks_install_hooks; profiles=$git_hooks_install_profiles"
