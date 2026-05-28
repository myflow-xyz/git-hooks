Describe 'lib/checks/golang/govulncheck.sh'
  It 'skips outside Go modules or workspaces'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips modules with no Go files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/govulncheck"
      chmod +x "$tmpdir/bin/govulncheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when govulncheck is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
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
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip govulncheck: missing tool; install: go install golang.org/x/vuln/cmd/govulncheck@latest'
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/govulncheck" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "govulncheck noisy success stdout"
printf "%s\n" "govulncheck noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/govulncheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'creates missing configured Go runtime directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=0
      export GOCACHE="$tmpdir/cache/go/build"
      export GOTMPDIR="$tmpdir/cache/go/tmp"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/govulncheck" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ -d "$GOCACHE" ] || exit 91
[ -d "$GOTMPDIR" ] || exit 92
exit 0
EOF
      chmod +x "$tmpdir/bin/govulncheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
      test -d "$GOCACHE"
      test -d "$GOTMPDIR"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'streams native output when verbose mode is enabled'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/govulncheck" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*"
printf "%s\n" "govulncheck verbose output"
exit 0
EOF
      chmod +x "$tmpdir/bin/govulncheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p .githooks
      printf "%s\n" "GIT_HOOK_VERBOSE=1" > .githooks/hooks.env
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'git-hooks: govulncheck ./...'
    The stdout should include './...'
    The stdout should include 'govulncheck verbose output'
  End

  It 'reports verbose failure output and exit code'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/govulncheck" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "vulnerability details"
exit 9
EOF
      chmod +x "$tmpdir/bin/govulncheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 9
    The stdout should include 'git-hooks: govulncheck ./...'
    The stdout should include 'vulnerability details'
    The stderr should include 'git-hooks: error: govulncheck failed; exit=9'
  End

  It 'reports failure output and returns the tool exit code'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-govulncheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/govulncheck" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "vulnerability details"
exit 8
EOF
      chmod +x "$tmpdir/bin/govulncheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/govulncheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 8
    The stdout should eq ''
    The stderr should include 'git-hooks: error: govulncheck failed; exit=8'
    The stderr should include 'vulnerability details'
  End
End
