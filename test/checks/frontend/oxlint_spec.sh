Describe 'lib/checks/frontend/oxlint.sh'
  It 'skips without staged frontend source files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxlint.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/frontend/oxlint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips staged binary frontend source files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxlint.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/src"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-ts" > src/generated.ts
      git add src/generated.ts
      sh "$ROOT/lib/checks/frontend/oxlint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when pnpm is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxlint.XXXXXX")
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
      sh "$ROOT/lib/checks/frontend/oxlint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip oxlint: missing pnpm; install: corepack enable pnpm'
  End

  It 'skips with a dev dependency install hint when the repo-local oxlint bin is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxlint.XXXXXX")
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
      sh "$ROOT/lib/checks/frontend/oxlint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip oxlint: missing node_modules/.bin/oxlint; install: pnpm add -D oxlint'
  End

  It 'suppresses noisy successful oxlint output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxlint.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/src" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
[ "\$1" = exec ] || exit 8
[ "\$2" = oxlint ] || exit 8
shift 2
[ "\$1" = --type-aware ] || exit 8
[ "\$2" = --report-unused-disable-directives ] || exit 8
[ "\$3" = --max-warnings ] || exit 8
[ "\$4" = 0 ] || exit 8
[ "\$5" = src/main.ts ] || exit 8
printf "%s\n" "oxlint noisy success stdout"
printf "%s\n" "oxlint noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/oxlint"
      chmod +x "$tmpdir/node_modules/.bin/oxlint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > src/main.ts
      git add package.json src/main.ts
      sh "$ROOT/lib/checks/frontend/oxlint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'returns the oxlint status and prints output when lint fails'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxlint.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/src" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "lint failed"
exit 4
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/oxlint"
      chmod +x "$tmpdir/node_modules/.bin/oxlint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > src/main.ts
      git add package.json src/main.ts
      sh "$ROOT/lib/checks/frontend/oxlint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 4
    The stdout should eq ''
    The stderr should include 'git-hooks: error: oxlint failed; exit=4'
    The stderr should include 'lint failed'
  End

  It 'lints only staged frontend files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-oxlint.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export OXLINT_LOG="$tmpdir/oxlint-log"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/app" "$tmpdir/src" "$tmpdir/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "\$*" >> "$OXLINT_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/node_modules/.bin/oxlint"
      chmod +x "$tmpdir/node_modules/.bin/oxlint"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > app/main.ts
      printf "console.log(2)\n" > src/unrelated.ts
      git add package.json app/main.ts
      sh "$ROOT/lib/checks/frontend/oxlint.sh"
      cat "$OXLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'exec oxlint --type-aware --report-unused-disable-directives --max-warnings 0 app/main.ts'
    The stdout should not include 'src/unrelated.ts'
  End
End
