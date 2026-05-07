#!/usr/bin/env sh

# Git query helpers shared by dispatcher and checks.

git_hooks_git_repo_root() {
  command git rev-parse --show-toplevel 2>/dev/null
}

git_hooks_git_current_branch() {
  command git branch --show-current 2>/dev/null
}

git_hooks_git_staged_files() {
  command git diff --cached --name-only --diff-filter=ACMR 2>/dev/null
}

git_hooks_git_has_staged_files() {
  [ -n "$(git_hooks_git_staged_files)" ]
}

git_hooks_git_staged_files_by_extension() {
  if [ "$#" -lt 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_staged_files_by_extension <extension...>' >&2
    return 2
  fi

  git_hooks_git_staged_files |
  while IFS= read -r git_hooks_git_staged_file || [ -n "$git_hooks_git_staged_file" ]
  do
    [ -n "$git_hooks_git_staged_file" ] || continue
    for git_hooks_git_extension in "$@"
    do
      git_hooks_git_extension=${git_hooks_git_extension#.}
      case "$git_hooks_git_staged_file" in
        *."$git_hooks_git_extension")
          printf '%s\n' "$git_hooks_git_staged_file"
          break
          ;;
      esac
    done
  done
}

git_hooks_git_staged_text_files_by_extension() {
  if [ "$#" -lt 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_staged_text_files_by_extension <extension...>' >&2
    return 2
  fi

  git_hooks_git_staged_files_by_extension "$@" |
  while IFS= read -r git_hooks_git_staged_file || [ -n "$git_hooks_git_staged_file" ]
  do
    [ -n "$git_hooks_git_staged_file" ] || continue
    git_hooks_git_is_staged_binary "$git_hooks_git_staged_file" && continue
    printf '%s\n' "$git_hooks_git_staged_file"
  done
}

git_hooks_git_is_staged_binary() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_is_staged_binary <path>' >&2
    return 2
  fi

  git_hooks_git_numstat=$(command git diff --cached --numstat -- "$1" 2>/dev/null | command awk 'NR == 1 { print $1 " " $2 }')
  [ "$git_hooks_git_numstat" = '- -' ]
}

git_hooks_git_show_staged_file() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: git_hooks_git_show_staged_file <path>' >&2
    return 2
  fi

  command git show ":$1" 2>/dev/null
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
