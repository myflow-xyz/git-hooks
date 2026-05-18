Describe 'lib/common/env.sh'
  It 'bootstraps dispatcher environment and loads config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/repo/.githooks"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "GIT_HOOK_VERBOSE=1" > .githooks/hooks.env
      printf "%s\n" "GIT_HOOK_PROFILES=\"common custom\"" > .githooks/project.conf
      . "$ROOT/lib/common/env.sh"
      git_hooks_env_bootstrap pre-commit
      printf "%s|%s|%s|%s\n" "$GIT_HOOK_PHASE" "$GIT_HOOK_REPO_ROOT" "$GIT_HOOK_PROJECT_DIR" "$GIT_HOOK_PROFILES"
      [ "$GIT_HOOK_VERBOSE" = 1 ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'pre-commit'
    The stdout should include '.githooks'
    The stdout should include 'common custom'
  End

  It 'defaults missing extra check variables to empty'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/repo/.githooks"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "GIT_HOOK_PROFILES=\"common custom\"" > .githooks/project.conf
      . "$ROOT/lib/common/env.sh"
      git_hooks_env_bootstrap pre-commit
      printf "[%s][%s][%s]\n" "$GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS" "$GIT_HOOK_PRE_PUSH_EXTRA_CHECKS" "$GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '[][][]'
  End

  It 'rejects unknown phases'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      . "$ROOT/lib/common/env.sh"
      git_hooks_env_bootstrap nope
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'unknown hook phase'
  End

  It 'bootstraps check environment and loads repo policy'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/repo/.githooks"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "GIT_HOOK_VERBOSE=1" > .githooks/hooks.env
      printf "%s\n" "GIT_HOOK_PYTHON_RUNNER=path" > .githooks/project.conf
      . "$ROOT/lib/common/env.sh"
      git_hooks_env_bootstrap_check
      printf "%s|%s|%s|%s\n" "$GIT_HOOK_REPO_ROOT" "$GIT_HOOK_PROJECT_DIR" "$GIT_HOOK_VERBOSE" "$GIT_HOOK_PYTHON_RUNNER"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '.githooks'
    The stdout should include '|1|path'
  End

  It 'runs project commands without Git local or hook runtime environment'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/outer" "$tmpdir/fake"
      fake_repo=$(CDPATH="" cd "$tmpdir/fake" && pwd -P)
      cd "$tmpdir/outer"
      git init -q
      git -C "$fake_repo" init -q
      export GIT_DIR="$PWD/.git"
      export GIT_WORK_TREE="$PWD"
      export GIT_COMMON_DIR="$PWD/.git"
      export GIT_INDEX_FILE="$PWD/.git/index"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=pre-push
      export GIT_HOOK_VERBOSE=1
      export GIT_HOOK_PYTHON_RUNNER=path
      . "$ROOT/lib/common/env.sh"
      git_hooks_env_run_project_command sh -c '"'"'
        [ -z "${GIT_DIR+x}" ] || exit 9
        [ -z "${GIT_WORK_TREE+x}" ] || exit 9
        [ -z "${GIT_COMMON_DIR+x}" ] || exit 9
        [ -z "${GIT_INDEX_FILE+x}" ] || exit 9
        [ -z "${GIT_HOOKS_HOME+x}" ] || exit 9
        [ -z "${GIT_HOOK_PHASE+x}" ] || exit 9
        [ -z "${GIT_HOOK_VERBOSE+x}" ] || exit 9
        [ -z "${GIT_HOOK_PYTHON_RUNNER+x}" ] || exit 9
        actual=$(git -C "$1" rev-parse --show-toplevel) || exit 10
        [ "$actual" = "$1" ] || exit 11
      '"'"' sh "$fake_repo"
      [ "${GIT_DIR:-}" = "$PWD/.git" ]
      [ "${GIT_HOOKS_HOME:-}" = "$ROOT" ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'runs cleanup and exits immediately on interrupt'
    When run sh -u -c '
      ROOT=$1
      export GIT_HOOKS_HOME="$ROOT"
      . "$ROOT/lib/common/env.sh"
      git_hooks_env_install_abort_traps "printf cleanup"
      kill -INT $$
      printf after
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 130
    The stdout should eq 'cleanup'
    The stdout should not include 'after'
  End
End
