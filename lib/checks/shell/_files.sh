#!/usr/bin/env sh

# Shell file discovery helpers for checks under lib/checks/shell.

git_hooks_shell_staged_files() {
  git_hooks_git_staged_text_files_by_extension sh bash zsh
}

git_hooks_shell_staged_sh_bash_files() {
  git_hooks_git_staged_text_files_by_extension sh bash |
    while IFS= read -r git_hooks_shell_staged_file || [ -n "$git_hooks_shell_staged_file" ]; do
      [ -n "$git_hooks_shell_staged_file" ] || continue
      case "$git_hooks_shell_staged_file" in
      *_spec.sh)
        continue
        ;;
      esac
      printf '%s\n' "$git_hooks_shell_staged_file"
    done
}

git_hooks_shell_staged_file_mode() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_shell_staged_file_mode <path>'
    return 2
  fi

  command git ls-files -s -- "$1" 2>/dev/null | command awk 'NR == 1 { print $1 }'
}

git_hooks_shell_staged_file_is_executable() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_shell_staged_file_is_executable <path>'
    return 2
  fi

  [ "$(git_hooks_shell_staged_file_mode "$1")" = '100755' ]
}

git_hooks_shell_staged_first_line() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_shell_staged_first_line <path>'
    return 2
  fi

  git_hooks_git_show_staged_file "$1" |
    {
      IFS= read -r git_hooks_shell_line || git_hooks_shell_line=
      printf '%s\n' "$git_hooks_shell_line"
    }
}

git_hooks_shell_staged_shell_shebang_dialect() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_shell_staged_shell_shebang_dialect <path>'
    return 2
  fi

  git_hooks_shell_first_line=$(git_hooks_shell_staged_first_line "$1")

  case "$git_hooks_shell_first_line" in
  '#!'*/env' -S bash' | '#!'*/env' -S bash '* | '#!'*/env' bash' | '#!'*/env' bash '* | '#!'*/bash | '#!'*/bash' '*)
    printf '%s\n' bash
    ;;
  '#!'*/env' -S zsh' | '#!'*/env' -S zsh '* | '#!'*/env' zsh' | '#!'*/env' zsh '* | '#!'*/zsh | '#!'*/zsh' '*)
    printf '%s\n' zsh
    ;;
  '#!'*/env' -S sh' | '#!'*/env' -S sh '* | '#!'*/env' sh' | '#!'*/env' sh '* | '#!'*/sh | '#!'*/sh' '*)
    printf '%s\n' sh
    ;;
  esac
}

git_hooks_shell_staged_shell_dialect() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_shell_staged_shell_dialect <path>'
    return 2
  fi

  git_hooks_shell_dialect=$(git_hooks_shell_staged_shell_shebang_dialect "$1")
  if [ -n "$git_hooks_shell_dialect" ]; then
    printf '%s\n' "$git_hooks_shell_dialect"
    return 0
  fi

  case "$1" in
  *.bash)
    printf '%s\n' bash
    ;;
  *.zsh)
    printf '%s\n' zsh
    ;;
  *.sh)
    printf '%s\n' sh
    ;;
  esac
}

git_hooks_shell_staged_file_has_shell_shebang() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_shell_staged_file_has_shell_shebang <path>'
    return 2
  fi

  [ -n "$(git_hooks_shell_staged_shell_shebang_dialect "$1")" ]
}

git_hooks_shell_tracked_shellspec_dirs() {
  git_hooks_git_tracked_files |
    while IFS= read -r git_hooks_shell_tracked_file || [ -n "$git_hooks_shell_tracked_file" ]; do
      case "$git_hooks_shell_tracked_file" in
      .shellspec)
        printf '%s\n' .
        ;;
      */.shellspec)
        printf '%s\n' "${git_hooks_shell_tracked_file%/.shellspec}"
        ;;
      esac
    done |
    command sort -u
}
