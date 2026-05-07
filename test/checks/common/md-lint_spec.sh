Describe 'lib/checks/common/md-lint.sh'
  It 'skips without staged markdown files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "x\n" > file.txt
      git add file.txt
      sh "$ROOT/lib/checks/common/md-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End

  It 'runs markdownlint-cli2 for staged markdown files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export MARKDOWNLINT_LOG="$tmpdir/markdownlint.log"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MARKDOWNLINT_LOG\"" > "$tmpdir/bin/markdownlint-cli2"
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
      cat "$MARKDOWNLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--no-globs'
    The stdout should include '--config'
    The stdout should include 'README.md'
  End

  It 'does not expand configured globs for explicit staged files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export MARKDOWNLINT_LOG="$tmpdir/markdownlint.log"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/markdownlint-cli2" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*" >> "$MARKDOWNLINT_LOG"
case " $* " in
  *" --no-globs "*) exit 0 ;;
  *) exit 9 ;;
esac
EOF
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
      cat "$MARKDOWNLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--no-globs'
    The stdout should include 'README.md'
  End

  It 'skips with an install hint when markdownlint-cli2 is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip md-lint; missing tool: markdownlint-cli2; install: pnpm add -g markdownlint-cli2'
  End

  It 'skips staged binary markdown files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"unexpected:%s\\n\" \"\$1\"" "exit 1" > "$tmpdir/bin/markdownlint-cli2"
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-markdown" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End

  It 'prefers repo-local .markdownlint-cli2.yaml'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$ROOT"
      export MARKDOWNLINT_LOG="$tmpdir/markdownlint.log"
      mkdir -p "$HOME" "$tmpdir/bin" "$XDG_CONFIG_HOME/markdownlint"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MARKDOWNLINT_LOG\"" > "$tmpdir/bin/markdownlint-cli2"
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "config: {}\n" > .markdownlint-cli2.yaml
      printf "MD013: false\n" > .markdownlint.yaml
      printf "MD013: false\n" > "$XDG_CONFIG_HOME/markdownlint/markdownlint.yaml"
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
      cat "$MARKDOWNLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include '.markdownlint-cli2.yaml'
  End

  It 'falls back to repo-local .markdownlint.yaml'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$ROOT"
      export MARKDOWNLINT_LOG="$tmpdir/markdownlint.log"
      mkdir -p "$HOME" "$tmpdir/bin" "$XDG_CONFIG_HOME/markdownlint"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MARKDOWNLINT_LOG\"" > "$tmpdir/bin/markdownlint-cli2"
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "MD013: false\n" > .markdownlint.yaml
      printf "MD013: false\n" > "$XDG_CONFIG_HOME/markdownlint/markdownlint.yaml"
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
      cat "$MARKDOWNLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include '.markdownlint.yaml'
  End

  It 'falls back to user XDG markdownlint config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$ROOT"
      export MARKDOWNLINT_LOG="$tmpdir/markdownlint.log"
      mkdir -p "$HOME" "$tmpdir/bin" "$XDG_CONFIG_HOME/markdownlint"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MARKDOWNLINT_LOG\"" > "$tmpdir/bin/markdownlint-cli2"
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "MD013: false\n" > "$XDG_CONFIG_HOME/markdownlint/markdownlint.yaml"
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
      cat "$MARKDOWNLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include 'xdg/markdownlint/markdownlint.yaml'
  End

  It 'falls back to bundled git-hooks markdownlint config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$ROOT"
      export MARKDOWNLINT_LOG="$tmpdir/markdownlint.log"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MARKDOWNLINT_LOG\"" > "$tmpdir/bin/markdownlint-cli2"
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
      cat "$MARKDOWNLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--config'
    The stdout should include 'config/markdownlint/markdownlint.yaml'
  End

  It 'falls back to built-in defaults when no config is available'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg"
      export GIT_HOOKS_HOME="$tmpdir/missing-hooks"
      export MARKDOWNLINT_LOG="$tmpdir/markdownlint.log"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MARKDOWNLINT_LOG\"" > "$tmpdir/bin/markdownlint-cli2"
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
      cat "$MARKDOWNLINT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'README.md'
  End

  It 'keeps clean lint success silent in quiet mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/markdownlint-cli2" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "markdownlint noisy success stdout"
printf "%s\n" "markdownlint noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'keeps native linter output when repo hook env enables verbose mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-md.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/markdownlint-cli2" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*"
printf "%s\n" "markdownlint verbose output"
exit 0
EOF
      chmod +x "$tmpdir/bin/markdownlint-cli2"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p .githooks
      printf "%s\n" "GIT_HOOK_VERBOSE=1" > .githooks/hooks.env
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/common/md-lint.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'git-hooks: md-lint config:'
    The stdout should include '--config'
    The stdout should include 'markdownlint verbose output'
  End
End
