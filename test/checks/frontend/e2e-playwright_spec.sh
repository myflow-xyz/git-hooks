Describe 'lib/checks/frontend/e2e-playwright.sh'
  It 'skips when no E2E signal exists'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      git add package.json
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips when package config is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/e2e"
      cd "$tmpdir"
      git init -q
      printf "test\n" > e2e/app.spec.ts
      git add e2e/app.spec.ts
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when pnpm is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME" "$tmpdir/e2e"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "test\n" > e2e/app.spec.ts
      git add package.json e2e/app.spec.ts
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip playwright: missing pnpm; install: corepack enable pnpm'
  End

  It 'skips with a dev dependency install hint when the repo-local Playwright bin is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/e2e"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/bin/pnpm"
      chmod +x "$tmpdir/bin/pnpm"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "test\n" > e2e/app.spec.ts
      git add package.json e2e/app.spec.ts
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'info: skip playwright: missing node_modules/.bin/playwright; install: pnpm add -D @playwright/test'
  End

  It 'suppresses noisy successful Playwright output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/e2e" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
[ "\$1" = exec ] || exit 8
[ "\$2" = playwright ] || exit 8
[ "\$3" = test ] || exit 8
[ "\$4" = --pass-with-no-tests ] || exit 8
[ -z "\${GIT_HOOK_PHASE:-}" ] || exit 9
printf "%s\n" "playwright noisy success stdout"
printf "%s\n" "playwright noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/playwright"
      chmod +x "$tmpdir/node_modules/.bin/playwright"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "test\n" > e2e/app.spec.ts
      git add package.json e2e/app.spec.ts
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'passes Playwright no-test handling through the official option'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
[ "\$1" = exec ] || exit 8
[ "\$2" = playwright ] || exit 8
[ "\$3" = test ] || exit 8
[ "\$4" = --pass-with-no-tests ] || exit 8
printf "%s\n" "no tests, but Playwright exits 0 with --pass-with-no-tests"
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/playwright"
      chmod +x "$tmpdir/node_modules/.bin/playwright"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "export default {}\n" > playwright.config.ts
      git add package.json playwright.config.ts
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'prints successful Playwright output in verbose mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
[ "\$1" = exec ] || exit 8
[ "\$2" = playwright ] || exit 8
[ "\$3" = test ] || exit 8
[ "\$4" = --pass-with-no-tests ] || exit 8
printf "%s\n" "playwright success"
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/playwright"
      chmod +x "$tmpdir/node_modules/.bin/playwright"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "export default {}\n" > playwright.config.ts
      git add package.json playwright.config.ts
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'playwright success'
    The stderr should eq ''
  End

  It 'returns the Playwright status and prints output when tests fail'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-playwright.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/e2e" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "e2e failed"
exit 7
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/playwright"
      chmod +x "$tmpdir/node_modules/.bin/playwright"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "test\n" > e2e/app.spec.ts
      git add package.json e2e/app.spec.ts
      sh "$ROOT/lib/checks/frontend/e2e-playwright.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 7
    The stdout should eq ''
    The stderr should include 'git-hooks: error: playwright failed; exit=7'
    The stderr should include 'e2e failed'
  End
End
