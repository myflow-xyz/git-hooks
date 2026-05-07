Describe 'lib/checks/golang/golangci-lint-fast.sh'
  It 'skips outside Go modules or workspaces'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips without staged Go files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/golangci-lint"
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when golangci-lint is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
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
      git add main.go
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip golangci-lint-fast; missing tool: golangci-lint; install: install upstream binary from golangci-lint releases; avoid Homebrew Go runtime shims'
    The stderr should not include 'brew install golangci-lint'
  End

  It 'skips when bundled fast config is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/missing-hooks"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/bin/golangci-lint"
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip golangci-lint-fast; missing bundled config:'
  End

  It 'uses bundled fast config with patch-scoped --fast-only'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GOLANGCI_LOG="$tmpdir/golangci.log"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$GOLANGCI_LOG\"" > "$tmpdir/bin/golangci-lint"
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "version: \"2\"\n" > .golangci.yml
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
      cat "$GOLANGCI_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include 'config/golangci-lint/fast.yaml'
    The stdout should include '--fast-only'
    The stdout should include '--new-from-patch='
    The stdout should include '--whole-files'
    The stdout should not include '.golangci.yml'
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/golangci-lint" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "golangci fast noisy success stdout"
printf "%s\n" "golangci fast noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'creates missing configured Go runtime directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=0
      export GOCACHE="$tmpdir/cache/go/build"
      export GOTMPDIR="$tmpdir/cache/go/tmp"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/golangci-lint" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ -d "$GOCACHE" ] || exit 91
[ -d "$GOTMPDIR" ] || exit 92
exit 0
EOF
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
      test -d "$GOCACHE"
      test -d "$GOTMPDIR"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'reports lint failure output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/golangci-lint" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "fast lint failed"
exit 7
EOF
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      git add main.go
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 7
    The stdout should eq ''
    The stderr should include 'git-hooks: error: golangci-lint-fast failed; exit=7'
    The stderr should include 'fast lint failed'
  End

  It 'skips staged binary Go files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci-fast.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/golangci-lint"
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "\000\001binary-go" > generated.go
      git add generated.go
      sh "$ROOT/lib/checks/golang/golangci-lint-fast.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End
End
