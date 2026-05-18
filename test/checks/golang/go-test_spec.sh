Describe 'lib/checks/golang/go-test.sh'
  It 'skips outside Go modules or workspaces'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-test.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/golang/go-test.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips modules with no Go files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-test.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/go"
      chmod +x "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      sh "$ROOT/lib/checks/golang/go-test.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when go is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-test.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/go-test.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip go-test: missing go; install: install Go from https://go.dev/dl/'
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-test.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/go" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "go test noisy success stdout"
printf "%s\n" "go test noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/go-test.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'creates missing configured Go runtime directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-test.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=0
      export GOCACHE="$tmpdir/cache/go/build"
      export GOTMPDIR="$tmpdir/cache/go/tmp"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/go" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ -d "$GOCACHE" ] || exit 91
[ -d "$GOTMPDIR" ] || exit 92
exit 0
EOF
      chmod +x "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/go-test.sh"
      test -d "$GOCACHE"
      test -d "$GOTMPDIR"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'does not leak Git local repository environment into go test'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-test.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      export GO_FAKE_REPO="$tmpdir/fake"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/outer" "$GO_FAKE_REPO"
      GO_FAKE_REPO=$(CDPATH="" cd "$GO_FAKE_REPO" && pwd -P)
      export GO_FAKE_REPO
      cat > "$tmpdir/bin/go" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ "$1" = test ] || exit 8
[ "$2" = ./... ] || exit 8
[ -z "${GIT_DIR+x}" ] || exit 9
[ -z "${GIT_WORK_TREE+x}" ] || exit 9
[ -z "${GIT_COMMON_DIR+x}" ] || exit 9
[ -z "${GIT_INDEX_FILE+x}" ] || exit 9
actual=$(git -C "$GO_FAKE_REPO" rev-parse --show-toplevel) || exit 10
[ "$actual" = "$GO_FAKE_REPO" ] || exit 11
printf isolated
exit 0
EOF
      chmod +x "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/outer"
      git init -q
      git -C "$GO_FAKE_REPO" init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      export GIT_DIR="$PWD/.git"
      export GIT_WORK_TREE="$PWD"
      export GIT_COMMON_DIR="$PWD/.git"
      export GIT_INDEX_FILE="$PWD/.git/index"
      sh "$ROOT/lib/checks/golang/go-test.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'isolated'
    The stderr should eq ''
  End

  It 'reports test failure output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-test.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/go" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "tests failed"
exit 6
EOF
      chmod +x "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/go-test.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 6
    The stdout should eq ''
    The stderr should include 'git-hooks: error: go test failed; exit=6'
    The stderr should include 'tests failed'
  End
End
