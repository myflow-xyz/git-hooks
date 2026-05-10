Describe 'lib/checks/golang/go-mod-tidy.sh'
  It 'skips outside Go modules'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-mod-tidy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/golang/go-mod-tidy.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when go is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-mod-tidy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      sh "$ROOT/lib/checks/golang/go-mod-tidy.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip go-mod-tidy: missing go; install: install Go from https://go.dev/dl/'
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-mod-tidy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/go" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "go mod tidy noisy success stdout"
printf "%s\n" "go mod tidy noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      sh "$ROOT/lib/checks/golang/go-mod-tidy.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'creates missing configured Go runtime directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-mod-tidy.XXXXXX")
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
      sh "$ROOT/lib/checks/golang/go-mod-tidy.sh"
      test -d "$GOCACHE"
      test -d "$GOTMPDIR"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'reports tidy diff failure output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-go-mod-tidy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/go" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "diff current/go.mod tidy/go.mod"
exit 8
EOF
      chmod +x "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      sh "$ROOT/lib/checks/golang/go-mod-tidy.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 8
    The stdout should eq ''
    The stderr should include 'git-hooks: error: go mod tidy failed; exit=8'
    The stderr should include 'diff current/go.mod tidy/go.mod'
  End
End
