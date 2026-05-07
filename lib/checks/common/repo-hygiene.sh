#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_repo_hygiene_has_active_lf_policy() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_repo_hygiene_has_active_lf_policy <gitattributes>'
    return 2
  fi

  command awk '
    /^[[:space:]]*($|#)/ { next }
    /(^|[[:space:]])eol=lf([[:space:]]|$)/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$1"
}

git_hooks_env_bootstrap_check || exit $?

git_hooks_log_is_verbose || exit 0

git_hooks_repo_hygiene_gitattributes=$GIT_HOOK_REPO_ROOT/.gitattributes
git_hooks_repo_hygiene_gitignore=$GIT_HOOK_REPO_ROOT/.gitignore
git_hooks_repo_hygiene_editorconfig=$GIT_HOOK_REPO_ROOT/.editorconfig
git_hooks_repo_hygiene_recommended=0

if [ ! -f "$git_hooks_repo_hygiene_gitattributes" ]; then
  git_hooks_log_info 'recommend: add .gitattributes with `* text=auto eol=lf`'
  git_hooks_repo_hygiene_recommended=1
elif ! git_hooks_repo_hygiene_has_active_lf_policy "$git_hooks_repo_hygiene_gitattributes"; then
  git_hooks_log_info 'recommend: add active .gitattributes LF policy, for example `* text=auto eol=lf`'
  git_hooks_repo_hygiene_recommended=1
fi

if [ ! -f "$git_hooks_repo_hygiene_gitignore" ]; then
  git_hooks_log_info 'recommend: add .gitignore for generated, local, cache, and secret-adjacent files'
  git_hooks_repo_hygiene_recommended=1
fi

if [ ! -f "$git_hooks_repo_hygiene_editorconfig" ]; then
  git_hooks_log_info 'recommend: add .editorconfig with `end_of_line = lf` and `insert_final_newline = true`'
  git_hooks_repo_hygiene_recommended=1
fi

if [ "$git_hooks_repo_hygiene_recommended" -eq 0 ]; then
  git_hooks_log_info 'repo-hygiene: recommended files present'
fi

exit 0
