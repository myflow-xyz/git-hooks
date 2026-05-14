Describe 'lib/checks/frontend/vitest.sh'
  It 'skips when package.json is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/frontend/vitest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when pnpm is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      sh "$ROOT/lib/checks/frontend/vitest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip vitest: missing pnpm; install: corepack enable pnpm'
  End

  It 'skips with a dev dependency install hint when the repo-local vitest bin is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/bin/pnpm"
      chmod +x "$tmpdir/bin/pnpm"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      sh "$ROOT/lib/checks/frontend/vitest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip vitest: missing node_modules/.bin/vitest; install: pnpm add -D vitest'
  End

  It 'suppresses noisy successful vitest output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
[ "\$1" = exec ] || exit 8
[ "\$2" = vitest ] || exit 8
[ "\$3" = run ] || exit 8
printf "%s\n" "vitest noisy success stdout"
printf "%s\n" "vitest noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/vitest"
      chmod +x "$tmpdir/node_modules/.bin/vitest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      sh "$ROOT/lib/checks/frontend/vitest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips when vitest reports no test files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "No test files found, exiting with code 1"
exit 1
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/vitest"
      chmod +x "$tmpdir/node_modules/.bin/vitest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      sh "$ROOT/lib/checks/frontend/vitest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips verbosely when vitest reports no test files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "No test files found, exiting with code 1"
exit 1
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/vitest"
      chmod +x "$tmpdir/node_modules/.bin/vitest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      sh "$ROOT/lib/checks/frontend/vitest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'git-hooks: skip: vitest; no test files found'
    The stderr should eq ''
  End

  It 'returns the vitest status and prints output when tests fail'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-vitest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "tests failed"
exit 6
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/vitest"
      chmod +x "$tmpdir/node_modules/.bin/vitest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      sh "$ROOT/lib/checks/frontend/vitest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 6
    The stdout should eq ''
    The stderr should include 'git-hooks: error: vitest failed; exit=6'
    The stderr should include 'tests failed'
  End
End
