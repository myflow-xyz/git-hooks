Describe 'lib/checks/common/gitleaks.sh'
  It 'skips without staged files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-gitleaks.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/common/gitleaks.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End

  It 'skips with an install hint when gitleaks is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-gitleaks.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "x\n" > file.txt
      git add file.txt
      sh "$ROOT/lib/checks/common/gitleaks.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip gitleaks: missing tool; install: brew install gitleaks'
  End

  It 'suppresses noisy gitleaks output when no leak is present'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-gitleaks.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/gitleaks" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "gitleaks noisy success stdout"
printf "%s\n" "gitleaks noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/gitleaks"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "x\n" > file.txt
      git add file.txt
      sh "$ROOT/lib/checks/common/gitleaks.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'keeps gitleaks output when verbose logging is enabled'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-gitleaks.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/gitleaks" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*"
printf "%s\n" "gitleaks verbose success"
exit 0
EOF
      chmod +x "$tmpdir/bin/gitleaks"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "x\n" > file.txt
      git add file.txt
      sh "$ROOT/lib/checks/common/gitleaks.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'protect --staged --redact --verbose'
    The stdout should include 'gitleaks verbose success'
  End

  It 'returns the gitleaks status and prints output when a leak is reported'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-gitleaks.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/gitleaks" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "leak details"
exit 1
EOF
      chmod +x "$tmpdir/bin/gitleaks"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "secret\n" > file.txt
      git add file.txt
      sh "$ROOT/lib/checks/common/gitleaks.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'git-hooks: error: gitleaks failed; exit=1'
    The stderr should include 'leak details'
  End
End
