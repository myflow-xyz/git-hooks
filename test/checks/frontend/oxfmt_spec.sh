Describe 'lib/checks/frontend/oxfmt.sh'
  It 'skips without staged frontend source files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/frontend/oxfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips staged binary frontend source files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/src"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-ts" > src/generated.ts
      git add src/generated.ts
      sh "$ROOT/lib/checks/frontend/oxfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when pnpm is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME" "$tmpdir/src"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > src/main.ts
      git add package.json src/main.ts
      sh "$ROOT/lib/checks/frontend/oxfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip oxfmt: missing pnpm; install: corepack enable pnpm'
  End

  It 'skips with a dev dependency install hint when the repo-local oxfmt bin is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/src"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/bin/pnpm"
      chmod +x "$tmpdir/bin/pnpm"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > src/main.ts
      git add package.json src/main.ts
      sh "$ROOT/lib/checks/frontend/oxfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip oxfmt: missing node_modules/.bin/oxfmt; install: pnpm add -D oxfmt'
  End

  It 'suppresses noisy successful oxfmt output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/src" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
[ "\$1" = exec ] || exit 8
[ "\$2" = oxfmt ] || exit 8
[ "\$3" = --check ] || exit 8
[ "\$4" = src/main.ts ] || exit 8
printf "%s\n" "oxfmt noisy success stdout"
printf "%s\n" "oxfmt noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/oxfmt"
      chmod +x "$tmpdir/node_modules/.bin/oxfmt"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > src/main.ts
      git add package.json src/main.ts
      sh "$ROOT/lib/checks/frontend/oxfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'returns the oxfmt status and prints output when format check fails'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/src" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "format failed"
exit 5
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/oxfmt"
      chmod +x "$tmpdir/node_modules/.bin/oxfmt"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > src/main.ts
      git add package.json src/main.ts
      sh "$ROOT/lib/checks/frontend/oxfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 5
    The stdout should eq ''
    The stderr should include 'git-hooks: error: oxfmt failed; exit=5'
    The stderr should include 'format failed'
  End

  It 'checks staged frontend files outside src'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export OXFMT_LOG="$tmpdir/oxfmt-log"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/app" "$tmpdir/src" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "\$*" >> "$OXFMT_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/oxfmt"
      chmod +x "$tmpdir/node_modules/.bin/oxfmt"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > app/main.ts
      printf "console.log(2)\n" > src/unrelated.ts
      git add package.json app/main.ts
      sh "$ROOT/lib/checks/frontend/oxfmt.sh"
      cat "$OXFMT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'exec oxfmt --check app/main.ts'
    The stdout should not include 'src/unrelated.ts'
  End
End
