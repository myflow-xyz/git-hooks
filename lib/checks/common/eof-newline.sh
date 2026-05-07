#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_eof_tmp=${TMPDIR:-/tmp}/git-hooks-eof-newline.$$
git_hooks_eof_failed=0

git_hooks_env_install_abort_traps 'command rm -f "$git_hooks_eof_tmp"' || exit $?

git_hooks_eof_last_byte_hex() {
  command tail -c 1 "$1" 2>/dev/null |
    command od -An -tx1 |
    command tr -d ' \n'
}

git_hooks_env_bootstrap_check || exit $?

git_hooks_eof_files=$(git_hooks_git_staged_files)

if [ -z "$git_hooks_eof_files" ]; then
  git_hooks_log_skip 'eof-newline; no staged files'
  exit 0
fi

while IFS= read -r git_hooks_eof_file || [ -n "$git_hooks_eof_file" ]; do
  [ -n "$git_hooks_eof_file" ] || continue

  if git_hooks_git_is_staged_binary "$git_hooks_eof_file"; then
    continue
  fi

  git_hooks_git_show_staged_file "$git_hooks_eof_file" >"$git_hooks_eof_tmp" || continue

  if [ ! -s "$git_hooks_eof_tmp" ]; then
    continue
  fi

  if [ "$(git_hooks_eof_last_byte_hex "$git_hooks_eof_tmp")" != 0a ]; then
    git_hooks_log_error "missing trailing newline: $git_hooks_eof_file"
    git_hooks_eof_failed=1
  fi
done <<EOF
$git_hooks_eof_files
EOF

exit "$git_hooks_eof_failed"
