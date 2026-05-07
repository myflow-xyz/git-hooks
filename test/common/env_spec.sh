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
