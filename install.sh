#!/usr/bin/env sh

set -u

git_hooks_install_usage() {
  cat <<'EOF'
Usage: install.sh [--check|--fix-links]

Install the shared Git hooks runtime into $XDG_CONFIG_HOME/git-hooks.
EOF
}

git_hooks_install_error() {
  printf 'git-hooks: error: %s\n' "$*" >&2
}

git_hooks_install_info() {
  printf 'git-hooks: %s\n' "$*"
}

git_hooks_install_source_home() {
  CDPATH='' cd -- "$(dirname "$0")" && command pwd -P
}

git_hooks_install_target_home() {
  printf '%s/git-hooks\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

git_hooks_install_inspect() {
  git_hooks_install_source=$1
  git_hooks_install_target=$2

  if [ ! -d "$git_hooks_install_source" ]; then
    return 1
  fi

  if [ ! -e "$git_hooks_install_target" ] && [ ! -L "$git_hooks_install_target" ]; then
    return 3
  fi

  if [ ! -L "$git_hooks_install_target" ]; then
    return 4
  fi

  if ! command -v readlink >/dev/null 2>&1; then
    return 127
  fi

  git_hooks_install_existing=$(command readlink "$git_hooks_install_target" 2>/dev/null || printf '')
  if [ "$git_hooks_install_existing" = "$git_hooks_install_source" ]; then
    return 0
  fi

  return 5
}

git_hooks_install_report_state() {
  git_hooks_install_state=$1
  git_hooks_install_source=$2
  git_hooks_install_target=$3

  case "$git_hooks_install_state" in
    0)
      git_hooks_install_info "check ok; target=$git_hooks_install_target; source=$git_hooks_install_source"
      ;;
    1)
      git_hooks_install_error "source directory missing: $git_hooks_install_source"
      ;;
    3)
      git_hooks_install_info "missing; target=$git_hooks_install_target; source=$git_hooks_install_source"
      ;;
    4)
      git_hooks_install_error "target exists and is not a symlink: $git_hooks_install_target"
      ;;
    5)
      git_hooks_install_error "target symlink points elsewhere: $git_hooks_install_target -> $git_hooks_install_existing"
      ;;
    127)
      git_hooks_install_error 'required command not found: readlink'
      ;;
  esac
}

git_hooks_install_backup_target() {
  git_hooks_install_target=$1
  git_hooks_install_timestamp=$(command date +%Y%m%d%H%M%S 2>/dev/null) || {
    git_hooks_install_error "failed to generate backup timestamp for target: $git_hooks_install_target"
    return 1
  }
  git_hooks_install_backup="${git_hooks_install_target}.${git_hooks_install_timestamp}.bak"

  command mv "$git_hooks_install_target" "$git_hooks_install_backup" || {
    git_hooks_install_error "failed to back up target: $git_hooks_install_target"
    return 1
  }

  git_hooks_install_info "backed up target; from=$git_hooks_install_target; to=$git_hooks_install_backup"
}

git_hooks_install_link() {
  git_hooks_install_source=$1
  git_hooks_install_target=$2

  command mkdir -p "$(command dirname "$git_hooks_install_target")" || return $?
  command ln -s "$git_hooks_install_source" "$git_hooks_install_target" || return $?
  git_hooks_install_info "installed; target=$git_hooks_install_target; source=$git_hooks_install_source"
}

git_hooks_install_mode=apply

case "${1:-}" in
  '')
    ;;
  --check)
    git_hooks_install_mode=check
    shift
    ;;
  --fix-links)
    git_hooks_install_mode=fix
    shift
    ;;
  -h|--help)
    git_hooks_install_usage
    exit 0
    ;;
  *)
    git_hooks_install_usage >&2
    exit 2
    ;;
esac

if [ "$#" -ne 0 ]; then
  git_hooks_install_usage >&2
  exit 2
fi

git_hooks_install_source=$(git_hooks_install_source_home) || exit 1
git_hooks_install_target=$(git_hooks_install_target_home)

git_hooks_install_inspect "$git_hooks_install_source" "$git_hooks_install_target"
git_hooks_install_state=$?

case "$git_hooks_install_mode:$git_hooks_install_state" in
  check:0)
    git_hooks_install_report_state "$git_hooks_install_state" "$git_hooks_install_source" "$git_hooks_install_target"
    exit 0
    ;;
  check:*)
    git_hooks_install_report_state "$git_hooks_install_state" "$git_hooks_install_source" "$git_hooks_install_target"
    exit 1
    ;;
  apply:0)
    git_hooks_install_report_state "$git_hooks_install_state" "$git_hooks_install_source" "$git_hooks_install_target"
    exit 0
    ;;
  apply:3)
    git_hooks_install_link "$git_hooks_install_source" "$git_hooks_install_target"
    exit $?
    ;;
  apply:1|apply:127)
    git_hooks_install_report_state "$git_hooks_install_state" "$git_hooks_install_source" "$git_hooks_install_target"
    exit 1
    ;;
  apply:4|apply:5)
    git_hooks_install_report_state "$git_hooks_install_state" "$git_hooks_install_source" "$git_hooks_install_target"
    git_hooks_install_error 'run install.sh --fix-links to repair the target explicitly'
    exit 1
    ;;
  fix:0)
    git_hooks_install_report_state "$git_hooks_install_state" "$git_hooks_install_source" "$git_hooks_install_target"
    exit 0
    ;;
  fix:1|fix:127)
    git_hooks_install_report_state "$git_hooks_install_state" "$git_hooks_install_source" "$git_hooks_install_target"
    exit 1
    ;;
  fix:3)
    git_hooks_install_link "$git_hooks_install_source" "$git_hooks_install_target"
    exit $?
    ;;
  fix:4)
    git_hooks_install_backup_target "$git_hooks_install_target" || exit $?
    git_hooks_install_link "$git_hooks_install_source" "$git_hooks_install_target"
    exit $?
    ;;
  fix:5)
    command rm -f "$git_hooks_install_target" || {
      git_hooks_install_error "failed to remove wrong symlink: $git_hooks_install_target"
      exit 1
    }
    git_hooks_install_link "$git_hooks_install_source" "$git_hooks_install_target"
    exit $?
    ;;
esac

exit 1
