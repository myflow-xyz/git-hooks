Describe 'lib/checks/dev/codegraph-build-index.sh'
  It 'skips with an install hint when codegraph is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/dev/codegraph-build-index.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should include 'warn: skip codegraph-build-index: missing codegraph; install: npm install -g @colbymchenry/codegraph'
  End

  It 'initializes and builds the index when missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export CODEGRAPH_LOG="$tmpdir/codegraph.log"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/codegraph" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*" >> "$CODEGRAPH_LOG"
[ "$*" = "init -i ." ] || exit 11
mkdir -p .codegraph
: > .codegraph/codegraph.db
printf "%s\n" "codegraph init output"
exit 0
EOF
      chmod +x "$tmpdir/bin/codegraph"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/dev/codegraph-build-index.sh"
      grep -Fx "init -i ." "$CODEGRAPH_LOG" >/dev/null
      test -f .codegraph/codegraph.db
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'rebuilds the index when initialized'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export CODEGRAPH_LOG="$tmpdir/codegraph.log"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/codegraph" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*" >> "$CODEGRAPH_LOG"
[ "$*" = "index --force ." ] || exit 12
printf "%s\n" "codegraph index output"
exit 0
EOF
      chmod +x "$tmpdir/bin/codegraph"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p .codegraph
      : > .codegraph/codegraph.db
      sh "$ROOT/lib/checks/dev/codegraph-build-index.sh"
      grep -Fx "index --force ." "$CODEGRAPH_LOG" >/dev/null
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'keeps clean success silent in quiet mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/codegraph" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "noisy codegraph success stdout"
printf "%s\n" "noisy codegraph success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/codegraph"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p .codegraph
      : > .codegraph/codegraph.db
      sh "$ROOT/lib/checks/dev/codegraph-build-index.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'does not pass pre-push stdin to codegraph'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/codegraph" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
if IFS= read -r codegraph_stdin_line; then
  printf "%s\n" "unexpected stdin: $codegraph_stdin_line"
  exit 7
fi
exit 0
EOF
      chmod +x "$tmpdir/bin/codegraph"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p .codegraph
      : > .codegraph/codegraph.db
      printf "%s\n" "refs from git pre-push" | sh "$ROOT/lib/checks/dev/codegraph-build-index.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'streams native output when verbose mode is enabled'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/codegraph" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*"
printf "%s\n" "codegraph native stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/codegraph"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p .codegraph
      : > .codegraph/codegraph.db
      sh "$ROOT/lib/checks/dev/codegraph-build-index.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'git-hooks: codegraph index --force .'
    The stdout should include 'index --force .'
    The stderr should include 'codegraph native stderr'
  End

  It 'reports failure output and returns the tool exit code'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-codegraph.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/codegraph" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "codegraph failure details"
exit 8
EOF
      chmod +x "$tmpdir/bin/codegraph"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p .codegraph
      : > .codegraph/codegraph.db
      sh "$ROOT/lib/checks/dev/codegraph-build-index.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 8
    The stdout should eq ''
    The stderr should include 'git-hooks: error: codegraph-build-index failed; exit=8'
    The stderr should include 'codegraph failure details'
  End
End
