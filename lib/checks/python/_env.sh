#!/usr/bin/env sh

# Python check runner helpers shared by Python hook entrypoints.

git_hooks_python_runner() {
  git_hooks_python_runner_value=${GIT_HOOK_PYTHON_RUNNER:-auto}

  case "$git_hooks_python_runner_value" in
    auto)
      if [ -f uv.lock ] && command -v uv >/dev/null 2>&1; then
        printf '%s\n' uv
      else
        printf '%s\n' path
      fi
      ;;
    uv|path)
      printf '%s\n' "$git_hooks_python_runner_value"
      ;;
    *)
      git_hooks_log_error "invalid GIT_HOOK_PYTHON_RUNNER: $git_hooks_python_runner_value"
      return 2
      ;;
  esac
}

git_hooks_python_uv_args() {
  printf '%s\n' "${GIT_HOOK_PYTHON_UV_ARGS:---frozen}"
}

git_hooks_python_require_tool() {
  if [ "$#" -lt 3 ]; then
    git_hooks_log_error 'Usage: git_hooks_python_require_tool <check> <tool> <install-hint>'
    return 2
  fi

  git_hooks_python_check=$1
  git_hooks_python_tool=$2
  git_hooks_python_install_hint=$3

  git_hooks_python_selected_runner=$(git_hooks_python_runner) || return $?

  case "$git_hooks_python_selected_runner" in
    uv)
      if ! command -v uv >/dev/null 2>&1; then
        git_hooks_log_skip_missing_tool "$git_hooks_python_check" uv 'brew install uv'
        return 1
      fi
      if ! git_hooks_python_run "$git_hooks_python_tool" --version >/dev/null 2>&1; then
        git_hooks_log_skip_missing_tool "$git_hooks_python_check" "$git_hooks_python_tool" "$git_hooks_python_install_hint"
        return 1
      fi
      ;;
    path)
      if ! command -v "$git_hooks_python_tool" >/dev/null 2>&1; then
        git_hooks_log_skip_missing_tool "$git_hooks_python_check" "$git_hooks_python_tool" "$git_hooks_python_install_hint"
        return 1
      fi
      ;;
  esac
}

git_hooks_python_run() {
  if [ "$#" -lt 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_python_run <tool> [args...]'
    return 2
  fi

  git_hooks_python_selected_runner=$(git_hooks_python_runner) || return $?

  case "$git_hooks_python_selected_runner" in
    uv)
      # GIT_HOOK_PYTHON_UV_ARGS is intentionally shell-split for simple flag lists.
      git_hooks_python_uv_args_value=$(git_hooks_python_uv_args)
      set -f
      # shellcheck disable=SC2086
      set -- $git_hooks_python_uv_args_value -- "$@"
      set +f
      git_hooks_env_run_project_command uv run "$@"
      ;;
    path)
      git_hooks_env_run_project_command "$@"
      ;;
  esac
}
