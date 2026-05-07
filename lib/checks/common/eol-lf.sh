#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_eol_lf_tmp=${TMPDIR:-/tmp}/git-hooks-eol-lf.$$
git_hooks_eol_lf_failed=0
git_hooks_eol_lf_cr=$(printf '\r')

git_hooks_env_install_abort_traps 'command rm -f "$git_hooks_eol_lf_tmp"' || exit $?
git_hooks_env_bootstrap_check || exit $?

git_hooks_eol_lf_files=$(git_hooks_git_staged_files)

if [ -z "$git_hooks_eol_lf_files" ]; then
  git_hooks_log_skip 'eol-lf; no staged files'
  exit 0
fi

while IFS= read -r git_hooks_eol_lf_file || [ -n "$git_hooks_eol_lf_file" ]; do
  [ -n "$git_hooks_eol_lf_file" ] || continue

  if git_hooks_git_is_staged_binary "$git_hooks_eol_lf_file"; then
    continue
  fi

  git_hooks_git_show_staged_file "$git_hooks_eol_lf_file" >"$git_hooks_eol_lf_tmp" || continue

  if LC_ALL=C command grep -q "$git_hooks_eol_lf_cr" "$git_hooks_eol_lf_tmp"; then
    git_hooks_log_error "eol-lf failed: $git_hooks_eol_lf_file; use LF line endings"
    git_hooks_eol_lf_failed=1
  fi
done <<EOF
$git_hooks_eol_lf_files
EOF

exit "$git_hooks_eol_lf_failed"
