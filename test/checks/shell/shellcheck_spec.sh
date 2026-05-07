Describe 'lib/checks/shell/shellcheck.sh'
  It 'skips without staged sh or bash files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "print zsh\n" > app.zsh
      git add app.zsh
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips staged ShellSpec files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/shellcheck"
      chmod +x "$tmpdir/bin/shellcheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "Describe spec\n" > app_spec.sh
      git add app_spec.sh
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when shellcheck is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      git add app.sh
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip shellcheck; missing tool: shellcheck; install: brew install shellcheck'
  End

  It 'uses sh and bash dialects from extension or shebang'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export SHELLCHECK_LOG="$tmpdir/shellcheck-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/shellcheck" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "$*" >> "$SHELLCHECK_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/shellcheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      printf "#!/usr/bin/env bash\nprintf bash\n" > bin.sh
      printf "printf bash\n" > app.bash
      git add app.sh bin.sh app.bash
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
      sort "$SHELLCHECK_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--severity=warning'
    The stdout should include '-s sh app.sh'
    The stdout should include '-s bash app.bash'
    The stdout should include '-s bash bin.sh'
    The stderr should eq ''
  End

  It 'skips sh files with zsh shebangs'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/shellcheck"
      chmod +x "$tmpdir/bin/shellcheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "#!/usr/bin/env zsh\nprint zsh\n" > app.sh
      git add app.sh
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" noisy" "exit 0" > "$tmpdir/bin/shellcheck"
      chmod +x "$tmpdir/bin/shellcheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      git add app.sh
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'returns status and prints output on failure'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" shellcheck-failed" "exit 7" > "$tmpdir/bin/shellcheck"
      chmod +x "$tmpdir/bin/shellcheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      git add app.sh
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 7
    The stdout should eq ''
    The stderr should include 'git-hooks: error: shellcheck failed; exit=7'
    The stderr should include 'shellcheck-failed'
  End

  It 'skips staged binary shell files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellcheck.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/shellcheck"
      chmod +x "$tmpdir/bin/shellcheck"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-sh" > generated.sh
      git add generated.sh
      sh "$ROOT/lib/checks/shell/shellcheck.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End
End
