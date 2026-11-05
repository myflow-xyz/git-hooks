#!/usr/bin/env sh

# Shared Go runtime helpers for checks that invoke Go tooling.

git_hooks_golang_prepare_runtime_dir() {
  if [ "$#" -ne 2 ]; then
    git_hooks_log_error 'Usage: git_hooks_golang_prepare_runtime_dir <env-name> <path>'
    return 2
  fi

  git_hooks_golang_runtime_dir_name=$1
  git_hooks_golang_runtime_dir_path=$2

  [ -n "$git_hooks_golang_runtime_dir_path" ] || return 0

  if [ -d "$git_hooks_golang_runtime_dir_path" ]; then
    return 0
  fi

  if [ -e "$git_hooks_golang_runtime_dir_path" ]; then
    git_hooks_log_error "$git_hooks_golang_runtime_dir_name is not a directory: $git_hooks_golang_runtime_dir_path"
    return 1
  fi

  if command mkdir -p "$git_hooks_golang_runtime_dir_path"; then
    git_hooks_log_info "created $git_hooks_golang_runtime_dir_name: $git_hooks_golang_runtime_dir_path"
    return 0
  fi

  git_hooks_log_error "failed to create $git_hooks_golang_runtime_dir_name: $git_hooks_golang_runtime_dir_path"
  return 1
}

git_hooks_golang_ensure_repo_root() {
  if [ -z "${GIT_HOOK_REPO_ROOT:-}" ]; then
    GIT_HOOK_REPO_ROOT=$(git_hooks_git_repo_root) || {
      git_hooks_log_error 'not inside a git repository'
      return 1
    }
    export GIT_HOOK_REPO_ROOT
  fi
}

git_hooks_golang_go_config_sets() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_golang_go_config_sets <env-name>'
    return 2
  fi

  command -v go >/dev/null 2>&1 || return 1

  # Go 1.23+ reports values from its config file (`go env -w`) as changed.
  # Older Go rejects -changed, so the caller keeps the repo-local default.
  git_hooks_golang_go_config=$(git_hooks_env_run_project_command go env -changed -json "$1" 2>/dev/null) || return 1

  case "$git_hooks_golang_go_config" in
  *"\"$1\":"*)
    return 0
    ;;
  esac

  return 1
}

git_hooks_golang_default_runtime_dirs() {
  if [ "${GOCACHE+x}" != x ] || [ "${GOTMPDIR+x}" != x ]; then
    git_hooks_golang_ensure_repo_root || return $?
  fi

  if [ "${GOCACHE+x}" != x ] && ! git_hooks_golang_go_config_sets GOCACHE; then
    GOCACHE=$GIT_HOOK_REPO_ROOT/.cache/go-build
  fi

  if [ "${GOTMPDIR+x}" != x ] && ! git_hooks_golang_go_config_sets GOTMPDIR; then
    GOTMPDIR=$GIT_HOOK_REPO_ROOT/.tmp/go
  fi

  # Keep `go env -w` values unset here so Go reads them from its own config.
  if [ "${GOCACHE+x}" = x ]; then
    export GOCACHE
  fi

  if [ "${GOTMPDIR+x}" = x ]; then
    export GOTMPDIR
  fi
}

git_hooks_golang_default_lint_runtime_dirs() {
  if [ "${GOLANGCI_LINT_CACHE+x}" != x ]; then
    git_hooks_golang_ensure_repo_root || return $?
  fi

  if [ "${GOLANGCI_LINT_CACHE+x}" != x ]; then
    GOLANGCI_LINT_CACHE=$GIT_HOOK_REPO_ROOT/.cache/golangci-lint
  fi

  export GOLANGCI_LINT_CACHE
}

git_hooks_golang_prepare_runtime_dirs() {
  git_hooks_golang_default_runtime_dirs || return $?
  git_hooks_golang_prepare_runtime_dir GOCACHE "${GOCACHE:-}" || return $?
  git_hooks_golang_prepare_runtime_dir GOTMPDIR "${GOTMPDIR:-}" || return $?
}

git_hooks_golang_prepare_lint_runtime_dirs() {
  git_hooks_golang_prepare_runtime_dirs || return $?
  git_hooks_golang_default_lint_runtime_dirs || return $?
  git_hooks_golang_prepare_runtime_dir GOLANGCI_LINT_CACHE "${GOLANGCI_LINT_CACHE:-}" || return $?
}

git_hooks_golang_has_go_files() {
  git_hooks_golang_go_files=$(command git ls-files --cached --others --exclude-standard -- '*.go') || return 2
  [ -n "$git_hooks_golang_go_files" ]
}

git_hooks_golang_cleanup() {
  command rm -rf "$GIT_HOOK_GO_STATE_DIR"
  if [ "${git_hooks_golang_keep_output:-0}" -eq 0 ] && [ -n "${git_hooks_golang_output:-}" ]; then
    command rm -f "$git_hooks_golang_output"
  fi
}

git_hooks_golang_begin() {
  if ! command -v mktemp >/dev/null 2>&1; then
    git_hooks_log_error 'required command not found: mktemp'
    return 127
  fi
  GIT_HOOK_GO_STATE_DIR=$(command mktemp -d "${TMPDIR:-/tmp}/git-hooks-go.XXXXXX") || return 2
  git_hooks_golang_output=
  git_hooks_golang_keep_output=0
  export GIT_HOOKS_COMMON_DIR GIT_HOOKS_GOLANG_DIR GIT_HOOK_GO_STATE_DIR
  export GIT_HOOK_GO_TEST_SHORT
  git_hooks_env_install_abort_traps git_hooks_golang_cleanup
}

# NUL paths stay in files/argv. xargs maps child statuses, so record the original
# status before stopping it with 255. No parallel workers share the status file.
git_hooks_golang_each() {
  if [ ! -f "$1" ]; then
    git_hooks_log_error "Go path list missing: $1"
    return 2
  fi
  [ -s "$1" ] || return 0
  command rm -f "$GIT_HOOK_GO_STATE_DIR/status"
  command xargs -0 sh -c '
    . "$GIT_HOOKS_COMMON_DIR/env.sh" || exit 255
    . "$GIT_HOOKS_GOLANG_DIR/runtime.sh" || exit 255
    callback=$1
    shift
    for path do
      "$callback" "$path" </dev/null
      status=$?
      if [ "$status" -ne 0 ]; then
        printf "%s\n" "$status" >"$GIT_HOOK_GO_STATE_DIR/status"
        exit 255
      fi
    done
  ' sh "$2" <"$1"
  git_hooks_golang_each_status=$?
  if [ -f "$GIT_HOOK_GO_STATE_DIR/status" ]; then
    IFS= read -r git_hooks_golang_each_status <"$GIT_HOOK_GO_STATE_DIR/status" || return 2
  fi
  return "$git_hooks_golang_each_status"
}

git_hooks_golang_resolve_module() {
  # The suffix preserves a directory name that ends in a newline.
  git_hooks_golang_module_real=$(CDPATH='' cd -P -- "$GIT_HOOK_REPO_ROOT/$1" && printf '%s/.' "$PWD") || return 2
  git_hooks_golang_module_real=${git_hooks_golang_module_real%/.}
  git_hooks_golang_root_real=$(CDPATH='' cd -P -- "$GIT_HOOK_REPO_ROOT" && printf '%s/.' "$PWD") || return 2
  git_hooks_golang_root_real=${git_hooks_golang_root_real%/.}
  case "$git_hooks_golang_module_real/" in
  "$git_hooks_golang_root_real/"*) ;;
  *)
    git_hooks_log_error "Go module escapes repository: $1"
    return 2
    ;;
  esac
}

git_hooks_golang_module_path() {
  git_hooks_golang_module=$1
  case "$git_hooks_golang_module" in
  '' | /* | .. | ../* | */../* | */..)
    git_hooks_log_error "invalid Go module directory: $git_hooks_golang_module"
    return 2
    ;;
  esac
  git_hooks_golang_module=${git_hooks_golang_module#./}
  git_hooks_golang_module=${git_hooks_golang_module%/}
  git_hooks_golang_resolve_module "$git_hooks_golang_module" || return $?
  if [ "$git_hooks_golang_module_real" = "$git_hooks_golang_root_real" ]; then
    printf 'go.mod\000'
  else
    printf '%s/go.mod\000' "${git_hooks_golang_module_real#"$git_hooks_golang_root_real"/}"
  fi
}

git_hooks_golang_repo_files() {
  set -- --cached --others --exclude-standard -z -- "$@"
  if [ -n "${GIT_HOOK_GO_MODULES:-}" ]; then
    command git ls-files "$@"
    return $?
  fi
  command git ls-files "$@" \
    ':(exclude,glob)**/vendor/**' ':(exclude,glob)**/testdata/**' \
    ':(exclude,glob)**/.cache/**' ':(exclude,glob)**/.tmp/**'
}

git_hooks_golang_collect_modules() {
  if [ -n "${GIT_HOOK_GO_MODULES:-}" ]; then
    while IFS= read -r git_hooks_golang_module || [ -n "$git_hooks_golang_module" ]; do
      [ -n "$git_hooks_golang_module" ] || continue
      if [ ! -f "$GIT_HOOK_REPO_ROOT/$git_hooks_golang_module/go.mod" ]; then
        git_hooks_log_error "Go module manifest missing: $git_hooks_golang_module/go.mod"
        return 2
      fi
      git_hooks_golang_module_path "$git_hooks_golang_module" || return $?
    done <<EOF
$GIT_HOOK_GO_MODULES
EOF
    return 0
  fi

  git_hooks_golang_repo_files go.mod ':(glob)**/go.mod'
}

git_hooks_golang_capture() {
  git_hooks_golang_label=$1
  shift
  if git_hooks_log_is_verbose; then
    "$@"
    git_hooks_golang_status=$?
  else
    git_hooks_golang_output=$(command mktemp "${TMPDIR:-/tmp}/git-hooks-go-output.XXXXXX") || return 2
    "$@" >"$git_hooks_golang_output" 2>&1
    git_hooks_golang_status=$?
    if [ "$git_hooks_golang_status" -ne 0 ]; then
      git_hooks_golang_keep_output=1
      command sed -n '1,120p' "$git_hooks_golang_output" >&2
      git_hooks_log_error "complete failure log: $git_hooks_golang_output"
    fi
  fi
  if [ "$git_hooks_golang_status" -ne 0 ]; then
    git_hooks_log_error "$git_hooks_golang_label failed; exit=$git_hooks_golang_status"
  fi
  return "$git_hooks_golang_status"
}

git_hooks_golang_module_command() (
  git_hooks_golang_manifest=$1
  [ -f "$GIT_HOOK_REPO_ROOT/$git_hooks_golang_manifest" ] || exit 0
  if [ "$GIT_HOOK_GO_CHECK" != go-mod-tidy ]; then
    [ -f "$GIT_HOOK_GO_STATE_DIR/affected/$git_hooks_golang_manifest" ] || exit 0
  fi
  git_hooks_golang_module_dir=${git_hooks_golang_manifest%go.mod}
  git_hooks_golang_resolve_module "$git_hooks_golang_module_dir" || exit $?
  [ ! -f "$GIT_HOOK_GO_STATE_DIR/visited/$git_hooks_golang_manifest" ] || exit 0
  command mkdir -p "$GIT_HOOK_GO_STATE_DIR/visited/${git_hooks_golang_module_dir:-.}" || exit $?
  : >"$GIT_HOOK_GO_STATE_DIR/visited/$git_hooks_golang_manifest" || exit $?
  cd "$git_hooks_golang_module_real" || exit 2
  git_hooks_log_info "Go module: ${git_hooks_golang_module_dir:-.}"
  case "$GIT_HOOK_GO_CHECK" in
  go-mod-tidy) set -- go mod tidy -diff ;;
  go-vet) set -- go vet ./... ;;
  govulncheck) set -- govulncheck ./... ;;
  go-test | go-test-race)
    set -- go test
    [ "$GIT_HOOK_GO_CHECK" != go-test-race ] || set -- "$@" -race
    [ "${GIT_HOOK_GO_TEST_SHORT:-0}" -eq 0 ] || set -- "$@" -short
    set -- "$@" -count=1 ./...
    ;;
  golangci-lint)
    set -- golangci-lint run
    [ -z "${GIT_HOOK_GO_LINT_CONFIG:-}" ] || set -- "$@" --config "$GIT_HOOK_GO_LINT_CONFIG"
    ;;
  golangci-lint-fast)
    command git -C "$GIT_HOOK_REPO_ROOT" --literal-pathspecs diff --cached \
      --no-ext-diff --no-textconv --no-renames --src-prefix=a/ --dst-prefix=b/ \
      --relative="$git_hooks_golang_module_dir" -- "${git_hooks_golang_module_dir:-.}" \
      >"$GIT_HOOK_GO_STATE_DIR/patch" || exit $?
    set -- golangci-lint run \
      --config "$GIT_HOOK_GO_LINT_CONFIG" --fast-only \
      --new-from-patch="$GIT_HOOK_GO_STATE_DIR/patch" --whole-files
    ;;
  *)
    git_hooks_log_error "unknown Go check: $GIT_HOOK_GO_CHECK"
    exit 2
    ;;
  esac
  git_hooks_log_info "$*"
  git_hooks_env_run_project_command "$@"
  git_hooks_golang_module_status=$?
  if [ "$git_hooks_golang_module_status" -ne 0 ]; then
    git_hooks_log_error "Go module failed: ${git_hooks_golang_module_dir:-.}; exit=$git_hooks_golang_module_status"
  fi
  exit "$git_hooks_golang_module_status"
)

git_hooks_golang_run_check() {
  GIT_HOOK_GO_CHECK=$1
  export GIT_HOOK_GO_CHECK
  git_hooks_golang_begin || return $?
  git_hooks_golang_collect_modules >"$GIT_HOOK_GO_STATE_DIR/modules" || return $?
  if [ ! -s "$GIT_HOOK_GO_STATE_DIR/modules" ]; then
    git_hooks_log_skip "$1; no Go modules"
    return 0
  fi
  if [ "$1" != go-mod-tidy ]; then
    git_hooks_golang_repo_files '*.go' >"$GIT_HOOK_GO_STATE_DIR/sources" || return $?
    if [ ! -s "$GIT_HOOK_GO_STATE_DIR/sources" ]; then
      git_hooks_log_skip "$1; no Go files"
      return 0
    fi
    git_hooks_golang_each "$GIT_HOOK_GO_STATE_DIR/sources" git_hooks_golang_mark_affected_module || return $?
  fi
  if ! command -v "$2" >/dev/null 2>&1; then
    git_hooks_log_skip_missing_tool "$1" "$2" "$3"
    return 0
  fi
  case "$1" in
  go-test | go-test-race)
    case "${GIT_HOOK_GO_TEST_SHORT:-0}" in
    0 | 1) ;;
    *)
      git_hooks_log_error 'GIT_HOOK_GO_TEST_SHORT must be 0 or 1'
      return 2
      ;;
    esac
    ;;
  esac
  if [ "$1" = golangci-lint ]; then
    git_hooks_golang_prepare_lint_runtime_dirs || return $?
  else
    git_hooks_golang_prepare_runtime_dirs || return $?
  fi
  case "$1" in
  go-mod-tidy)
    git_hooks_golang_label='go mod tidy'
    ;;
  go-vet)
    git_hooks_golang_label='go vet'
    ;;
  go-test)
    git_hooks_golang_label='go test'
    ;;
  *)
    git_hooks_golang_label=$1
    ;;
  esac
  git_hooks_golang_capture "$git_hooks_golang_label" \
    git_hooks_golang_each "$GIT_HOOK_GO_STATE_DIR/modules" git_hooks_golang_module_command
}

git_hooks_golang_select_staged_file() {
  git_hooks_golang_mode=$(command git --literal-pathspecs ls-files -s -- "$1") || return $?
  case "$git_hooks_golang_mode" in
  100644\ * | 100755\ *) ;;
  *) return 0 ;;
  esac
  git_hooks_git_is_staged_binary "$1"
  git_hooks_golang_binary_status=$?
  case "$git_hooks_golang_binary_status" in
  0) return 0 ;;
  1) ;;
  *) return "$git_hooks_golang_binary_status" ;;
  esac
  printf '%s\000' "$1" >>"$GIT_HOOK_GO_STATE_DIR/staged"
}

git_hooks_golang_collect_staged() {
  : >"$GIT_HOOK_GO_STATE_DIR/staged" || return $?
  git_hooks_git_staged_files_z go >"$GIT_HOOK_GO_STATE_DIR/staged-raw" || return $?
  git_hooks_golang_each "$GIT_HOOK_GO_STATE_DIR/staged-raw" git_hooks_golang_select_staged_file
}

git_hooks_golang_import_file() {
  git_hooks_git_show_staged_file "$1" >"$GIT_HOOK_GO_STATE_DIR/input" || return $?
  git_hooks_env_run_project_command goimports -l -srcdir "$GIT_HOOK_REPO_ROOT/$1" \
    <"$GIT_HOOK_GO_STATE_DIR/input" >"$GIT_HOOK_GO_STATE_DIR/current"
  git_hooks_golang_import_status=$?
  if [ "$git_hooks_golang_import_status" -ne 0 ]; then
    git_hooks_log_error "goimports: $1"
    return "$git_hooks_golang_import_status"
  fi
  if [ -s "$GIT_HOOK_GO_STATE_DIR/current" ]; then
    git_hooks_log_error "goimports: $1; format the staged Go content"
    return 1
  fi
}

git_hooks_golang_mark_affected_module() {
  [ -f "$GIT_HOOK_REPO_ROOT/$1" ] || return 0
  git_hooks_golang_parent=$1
  while :; do
    case "$git_hooks_golang_parent" in
    */*) git_hooks_golang_parent=${git_hooks_golang_parent%/*} ;;
    *) git_hooks_golang_parent=. ;;
    esac
    if [ -f "$GIT_HOOK_REPO_ROOT/$git_hooks_golang_parent/go.mod" ]; then
      command mkdir -p "$GIT_HOOK_GO_STATE_DIR/affected/$git_hooks_golang_parent" || return $?
      : >"$GIT_HOOK_GO_STATE_DIR/affected/$git_hooks_golang_parent/go.mod"
      return $?
    fi
    [ "$git_hooks_golang_parent" != . ] || return 0
  done
}
