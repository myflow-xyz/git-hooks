#!/usr/bin/env sh

# Git query helpers shared by dispatcher and checks.

git_hooks_git_repo_root() {
  command git rev-parse --show-toplevel 2>/dev/null
}

git_hooks_git_current_branch() {
  command git branch --show-current 2>/dev/null
}

git_hooks_git_staged_files() {
  command git diff --cached --name-only --diff-filter=ACMR
}

git_hooks_git_staged_files_z() {
  for git_hooks_git_extension; do
    set -- "$@" "*.${git_hooks_git_extension#.}"
    shift
  done
  command git diff --cached --name-only --diff-filter=ACMR -z -- "$@"
}

git_hooks_git_has_staged_files() {
  git_hooks_git_files=$(git_hooks_git_staged_files) || return $?
  [ -n "$git_hooks_git_files" ]
}

git_hooks_git_staged_files_by_extension() {
  if [ "$#" -lt 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_staged_files_by_extension <extension...>' >&2
    return 2
  fi

  git_hooks_git_files=$(git_hooks_git_staged_files) || return $?
  while IFS= read -r git_hooks_git_staged_file || [ -n "$git_hooks_git_staged_file" ]; do
    [ -n "$git_hooks_git_staged_file" ] || continue
    for git_hooks_git_extension in "$@"; do
      git_hooks_git_extension=${git_hooks_git_extension#.}
      case "$git_hooks_git_staged_file" in
      *."$git_hooks_git_extension")
        printf '%s\n' "$git_hooks_git_staged_file"
        break
        ;;
      esac
    done
  done <<EOF
$git_hooks_git_files
EOF
}

git_hooks_git_staged_text_files_by_extension() {
  if [ "$#" -lt 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_staged_text_files_by_extension <extension...>' >&2
    return 2
  fi

  git_hooks_git_files=$(git_hooks_git_staged_files_by_extension "$@") || return $?
  while IFS= read -r git_hooks_git_staged_file || [ -n "$git_hooks_git_staged_file" ]; do
    [ -n "$git_hooks_git_staged_file" ] || continue
    git_hooks_git_is_staged_binary "$git_hooks_git_staged_file"
    git_hooks_git_binary_status=$?
    case "$git_hooks_git_binary_status" in
    0) continue ;;
    1) ;;
    *) return "$git_hooks_git_binary_status" ;;
    esac
    printf '%s\n' "$git_hooks_git_staged_file"
  done <<EOF
$git_hooks_git_files
EOF
}

git_hooks_git_is_staged_binary() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_is_staged_binary <path>' >&2
    return 2
  fi

  git_hooks_git_numstat=$(command git --literal-pathspecs diff --cached --numstat -- "$1") || return 2
  git_hooks_git_numstat=$(printf '%s\n' "$git_hooks_git_numstat" | command awk 'NR == 1 { print $1 " " $2 }')
  [ "$git_hooks_git_numstat" = '- -' ]
}

git_hooks_git_show_staged_file() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_show_staged_file <path>' >&2
    return 2
  fi

  command git show ":$1"
}

git_hooks_git_tracked_files() {
  command git ls-files
}

git_hooks_git_changed_paths() {
  if [ "$#" -eq 0 ]; then
    command git diff --name-only
    return $?
  fi

  command git diff --name-only "$@"
}

git_hooks_git_worktree_status() {
  GIT_OPTIONAL_LOCKS=0 command git status --porcelain=v1 --untracked-files=all --ignore-submodules=none
}
