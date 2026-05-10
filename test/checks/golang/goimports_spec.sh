Describe 'lib/checks/golang/goimports.sh'
  It 'skips without staged Go files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-goimports.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/golang/goimports.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when goimports is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-goimports.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/goimports.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip goimports: missing tool; install: go install golang.org/x/tools/cmd/goimports@latest'
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-goimports.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/goimports" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "goimports noisy stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/goimports"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/goimports.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'fails when files need import formatting'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-goimports.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/goimports" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
shift
printf "%s\n" "$1"
exit 0
EOF
      chmod +x "$tmpdir/bin/goimports"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/goimports.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stdout should eq ''
    The stderr should include 'git-hooks: error: goimports failed; exit=1'
    The stderr should include 'main.go'
  End

  It 'skips staged binary Go files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-goimports.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/goimports"
      chmod +x "$tmpdir/bin/goimports"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-go" > generated.go
      git add generated.go
      sh "$ROOT/lib/checks/golang/goimports.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'creates missing configured Go runtime directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-goimports.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=0
      export GOCACHE="$tmpdir/cache/go/build"
      export GOTMPDIR="$tmpdir/cache/go/tmp"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/goimports" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ -d "$GOCACHE" ] || exit 91
[ -d "$GOTMPDIR" ] || exit 92
exit 0
EOF
      chmod +x "$tmpdir/bin/goimports"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/goimports.sh"
      test -d "$GOCACHE"
      test -d "$GOTMPDIR"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End
End
