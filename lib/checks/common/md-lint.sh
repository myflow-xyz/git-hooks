#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_md_select_config() {
  git_hooks_md_xdg_config_home=${XDG_CONFIG_HOME:-$HOME/.config}

  for git_hooks_md_config_candidate in \
    "$GIT_HOOK_REPO_ROOT/.markdownlint-cli2.yaml" \
    "$GIT_HOOK_REPO_ROOT/.markdownlint.yaml" \
    "$git_hooks_md_xdg_config_home/markdownlint/markdownlint.yaml" \
    "$GIT_HOOKS_HOME/config/markdownlint/markdownlint.yaml"; do
    if [ -f "$git_hooks_md_config_candidate" ]; then
      printf '%s\n' "$git_hooks_md_config_candidate"
      return 0
    fi
  done

  return 1
}

git_hooks_md_run_linter() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_md_run_linter <markdown-file>'
    return 2
  fi

  if [ -n "$git_hooks_md_config" ]; then
    command markdownlint-cli2 --no-globs --config "$git_hooks_md_config" "$1"
    return $?
  fi

  command markdownlint-cli2 "$1"
}

git_hooks_md_files=$(git_hooks_git_staged_text_files_by_extension md markdown)
git_hooks_md_text_files=
git_hooks_md_status=0

if [ -z "$git_hooks_md_files" ]; then
  git_hooks_log_skip 'md-lint; no staged markdown files'
  exit 0
fi

while IFS= read -r git_hooks_md_file || [ -n "$git_hooks_md_file" ]; do
  [ -n "$git_hooks_md_file" ] || continue

  if [ -z "$git_hooks_md_text_files" ]; then
    git_hooks_md_text_files=$git_hooks_md_file
  else
    git_hooks_md_text_files=$git_hooks_md_text_files'
'$git_hooks_md_file
  fi
done <<EOF
$git_hooks_md_files
EOF

if [ -z "$git_hooks_md_text_files" ]; then
  git_hooks_log_skip 'md-lint; no staged text markdown files'
  exit 0
fi

if ! command -v markdownlint-cli2 >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'md-lint' 'markdownlint-cli2' 'pnpm add -g markdownlint-cli2'
  exit 0
fi

git_hooks_md_config=$(git_hooks_md_select_config) || git_hooks_md_config=

if [ -n "$git_hooks_md_config" ]; then
  git_hooks_log_info "md-lint config: $git_hooks_md_config"
else
  git_hooks_log_info 'md-lint config: markdownlint defaults'
fi

git_hooks_md_verbose=0

if git_hooks_log_is_verbose; then
  git_hooks_md_verbose=1
else
  if ! command -v mktemp >/dev/null 2>&1; then
    git_hooks_log_error 'required command not found: mktemp'
    exit 127
  fi

  git_hooks_md_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-md-lint.XXXXXX") || {
    git_hooks_log_error 'failed to create temporary file for md-lint output'
    exit 2
  }
  git_hooks_env_install_abort_traps 'rm -f "$git_hooks_md_output" "$git_hooks_md_output.current"' || exit $?
fi

while IFS= read -r git_hooks_md_file || [ -n "$git_hooks_md_file" ]; do
  [ -n "$git_hooks_md_file" ] || continue

  if [ "$git_hooks_md_verbose" -eq 1 ]; then
    git_hooks_md_run_linter "$git_hooks_md_file"
    git_hooks_md_current_status=$?
  else
    git_hooks_md_run_linter "$git_hooks_md_file" >"$git_hooks_md_output.current" 2>&1
    git_hooks_md_current_status=$?
    if [ "$git_hooks_md_current_status" -ne 0 ]; then
      {
        printf 'file: %s\n' "$git_hooks_md_file"
        command cat "$git_hooks_md_output.current"
      } >>"$git_hooks_md_output"
    fi
    command rm -f "$git_hooks_md_output.current"
  fi

  if [ "$git_hooks_md_current_status" -ne 0 ] && [ "$git_hooks_md_status" -eq 0 ]; then
    git_hooks_md_status=$git_hooks_md_current_status
  fi
done <<EOF
$git_hooks_md_text_files
EOF

if [ "$git_hooks_md_status" -ne 0 ] && [ "$git_hooks_md_verbose" -eq 0 ]; then
  git_hooks_log_error "md-lint failed; exit=$git_hooks_md_status"
  if [ -s "$git_hooks_md_output" ]; then
    command sed -n '1,120p' "$git_hooks_md_output" >&2
    git_hooks_md_lines=$(command wc -l <"$git_hooks_md_output" | command tr -d ' ')
    if [ "$git_hooks_md_lines" -gt 120 ]; then
      git_hooks_log_warn "md-lint output truncated; lines=$git_hooks_md_lines shown=120"
    fi
  fi
fi

exit "$git_hooks_md_status"
