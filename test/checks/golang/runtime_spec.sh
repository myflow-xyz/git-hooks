Describe 'lib/checks/golang/runtime.sh'
  It 'creates missing configured runtime directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golang-runtime.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=0
      export GOCACHE="$tmpdir/cache/go/build"
      export GOTMPDIR="$tmpdir/cache/go/tmp"
      mkdir -p "$HOME"
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/golang/runtime.sh"
      git_hooks_golang_prepare_runtime_dirs
      test -d "$GOCACHE"
      test -d "$GOTMPDIR"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'reports created paths in verbose mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golang-runtime.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      export GOCACHE="$tmpdir/cache/go/build"
      export GOTMPDIR="$tmpdir/cache/go/tmp"
      mkdir -p "$HOME"
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/golang/runtime.sh"
      git_hooks_golang_prepare_runtime_dirs
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'git-hooks: created GOCACHE:'
    The stdout should include 'git-hooks: created GOTMPDIR:'
    The stderr should eq ''
  End

  It 'fails when a configured runtime path is not a directory'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golang-runtime.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=0
      export GOCACHE="$tmpdir/go-cache"
      export GOTMPDIR="$tmpdir/go-tmp"
      mkdir -p "$HOME"
      printf "%s\n" "not a directory" > "$GOCACHE"
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/golang/runtime.sh"
      git_hooks_golang_prepare_runtime_dirs
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stdout should eq ''
    The stderr should include 'git-hooks: error: GOCACHE is not a directory:'
  End
End
