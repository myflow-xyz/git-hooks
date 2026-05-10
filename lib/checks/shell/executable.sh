#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
. "$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/_files.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_shell_executable_files=$(git_hooks_shell_staged_files)
git_hooks_shell_executable_status=0

if [ -z "$git_hooks_shell_executable_files" ]; then
  git_hooks_log_skip 'shell-executable; no staged .sh, .bash, or .zsh files'
  exit 0
fi

while IFS= read -r git_hooks_shell_executable_file || [ -n "$git_hooks_shell_executable_file" ]; do
  [ -n "$git_hooks_shell_executable_file" ] || continue

  if git_hooks_shell_staged_file_is_executable "$git_hooks_shell_executable_file" &&
    ! git_hooks_shell_staged_file_has_shell_shebang "$git_hooks_shell_executable_file"; then
    git_hooks_log_error "shell-executable: $git_hooks_shell_executable_file; missing supported shebang"
    git_hooks_shell_executable_status=1
  fi
done <<EOF
$git_hooks_shell_executable_files
EOF

exit "$git_hooks_shell_executable_status"
