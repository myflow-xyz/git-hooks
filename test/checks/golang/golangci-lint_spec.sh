Describe 'lib/checks/golang/golangci-lint.sh'
  It 'skips outside Go modules or workspaces'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips modules with no Go files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
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
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when golangci-lint is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
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
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip golangci-lint: missing tool; install: install upstream binary from golangci-lint releases; avoid Homebrew Go runtime shims'
    The stderr should not include 'brew install golangci-lint'
  End

  It 'prefers repo-local golangci-lint config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$ROOT"
      export GOLANGCI_LOG="$tmpdir/golangci.log"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin" "$XDG_CONFIG_HOME/golangci-lint"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$GOLANGCI_LOG\"" > "$tmpdir/bin/golangci-lint"
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      printf "version: \"2\"\n" > .golangci.yml
      printf "version: \"2\"\n" > .golangci.yaml
      printf "version: \"2\"\n" > "$XDG_CONFIG_HOME/golangci-lint/config.yaml"
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
      cat "$GOLANGCI_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include '.golangci.yml'
  End

  It 'prefers repo .golangci.yaml over bundled golangci-lint config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
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
      printf "package main\n" > main.go
      printf "version: \"2\"\n" > .golangci.yaml
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
      cat "$GOLANGCI_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include '.golangci.yaml'
    The stdout should not include 'config/golangci-lint/config.yaml'
  End

  It 'falls back to user XDG golangci-lint config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$ROOT"
      export GOLANGCI_LOG="$tmpdir/golangci.log"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin" "$XDG_CONFIG_HOME/golangci-lint"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$GOLANGCI_LOG\"" > "$tmpdir/bin/golangci-lint"
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      printf "version: \"2\"\n" > "$XDG_CONFIG_HOME/golangci-lint/config.yaml"
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
      cat "$GOLANGCI_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include 'xdg/golangci-lint/config.yaml'
  End

  It 'falls back to bundled git-hooks golangci-lint config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
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
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
      cat "$GOLANGCI_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include 'config/golangci-lint/config.yaml'
  End

  It 'falls back to built-in defaults when no config is available'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$tmpdir/missing-hooks"
      export GOLANGCI_LOG="$tmpdir/golangci.log"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$GOLANGCI_LOG\"" > "$tmpdir/bin/golangci-lint"
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
      cat "$GOLANGCI_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'run'
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/golangci-lint" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "golangci noisy success stdout"
printf "%s\n" "golangci noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'creates missing configured Go runtime directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
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
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
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
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-golangci.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/golangci-lint" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "lint failed"
exit 4
EOF
      chmod +x "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      sh "$ROOT/lib/checks/golang/golangci-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 4
    The stdout should eq ''
    The stderr should include 'git-hooks: error: golangci-lint failed; exit=4'
    The stderr should include 'lint failed'
  End
End
