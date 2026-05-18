#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?
GIT_HOOKS_GOLANG_DIR=${GIT_HOOKS_GOLANG_DIR:-$(CDPATH='' cd -- "$(dirname "$0")" && pwd)}
. "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit $?

git_hooks_env_bootstrap_check || exit $?

git_hooks_golangci_fast_config=$GIT_HOOKS_HOME/config/golangci-lint/fast.yaml
git_hooks_golangci_fast_files=$(git_hooks_git_staged_text_files_by_extension go)

if [ ! -f go.mod ] && [ ! -f go.work ]; then
  git_hooks_log_skip 'golangci-lint-fast; go.mod or go.work missing'
  exit 0
fi

if [ -z "$git_hooks_golangci_fast_files" ]; then
  git_hooks_log_skip 'golangci-lint-fast; no staged Go files'
  exit 0
fi

if ! command -v golangci-lint >/dev/null 2>&1; then
  git_hooks_log_skip_missing_tool 'golangci-lint-fast' 'golangci-lint' 'install upstream binary from golangci-lint releases; avoid Homebrew Go runtime shims'
  exit 0
fi

if [ ! -f "$git_hooks_golangci_fast_config" ]; then
  git_hooks_log_warn "skip golangci-lint-fast; missing bundled config: $git_hooks_golangci_fast_config"
  exit 0
fi

git_hooks_log_info "golangci-lint-fast config: $git_hooks_golangci_fast_config"

if ! command -v mktemp >/dev/null 2>&1; then
  git_hooks_log_error 'required command not found: mktemp'
  exit 127
fi

git_hooks_golangci_fast_patch=$(mktemp "${TMPDIR:-/tmp}/git-hooks-golangci-lint-fast-patch.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for golangci-lint-fast patch'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_golangci_fast_patch"' || exit $?

git_hooks_golangci_fast_output=$(mktemp "${TMPDIR:-/tmp}/git-hooks-golangci-lint-fast.XXXXXX") || {
  git_hooks_log_error 'failed to create temporary file for golangci-lint-fast output'
  exit 2
}
git_hooks_env_install_abort_traps 'rm -f "$git_hooks_golangci_fast_patch" "$git_hooks_golangci_fast_output"' || exit $?

: >"$git_hooks_golangci_fast_patch" || {
  git_hooks_log_error 'failed to initialize temporary patch for golangci-lint-fast'
  exit 2
}

while IFS= read -r git_hooks_golangci_fast_file || [ -n "$git_hooks_golangci_fast_file" ]; do
  [ -n "$git_hooks_golangci_fast_file" ] || continue
  command git diff --cached --no-ext-diff -- "$git_hooks_golangci_fast_file" >>"$git_hooks_golangci_fast_patch" || {
    git_hooks_log_error "failed to write staged patch for: $git_hooks_golangci_fast_file"
    exit 2
  }
done <<EOF
$git_hooks_golangci_fast_files
EOF

if [ ! -s "$git_hooks_golangci_fast_patch" ]; then
  git_hooks_log_skip 'golangci-lint-fast; staged Go patch is empty'
  exit 0
fi

git_hooks_golang_prepare_lint_runtime_dirs || exit $?

git_hooks_golangci_fast_run_linter() {
  git_hooks_env_run_project_command golangci-lint run \
    --config "$git_hooks_golangci_fast_config" \
    --fast-only \
    --new-from-patch="$git_hooks_golangci_fast_patch" \
    --whole-files
}

if git_hooks_log_is_verbose; then
  git_hooks_golangci_fast_run_linter
  exit $?
fi

git_hooks_golangci_fast_run_linter >"$git_hooks_golangci_fast_output" 2>&1
git_hooks_golangci_fast_status=$?

if [ "$git_hooks_golangci_fast_status" -eq 0 ]; then
  exit 0
fi

git_hooks_log_error "golangci-lint-fast failed; exit=$git_hooks_golangci_fast_status"

if [ -s "$git_hooks_golangci_fast_output" ]; then
  command sed -n '1,120p' "$git_hooks_golangci_fast_output" >&2
  git_hooks_golangci_fast_lines=$(command wc -l <"$git_hooks_golangci_fast_output" | command tr -d ' ')
  if [ "$git_hooks_golangci_fast_lines" -gt 120 ]; then
    git_hooks_log_warn "golangci-lint-fast output truncated; lines=$git_hooks_golangci_fast_lines shown=120"
  fi
fi

exit "$git_hooks_golangci_fast_status"
