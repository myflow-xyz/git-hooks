Describe 'lib/checks/shell/shfmt.sh'
  It 'skips without staged sh or bash files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "print zsh\n" > app.zsh
      git add app.zsh
      sh "$ROOT/lib/checks/shell/shfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips staged ShellSpec files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/shfmt"
      chmod +x "$tmpdir/bin/shfmt"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "Describe spec\n" > app_spec.sh
      git add app_spec.sh
      sh "$ROOT/lib/checks/shell/shfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when shfmt is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      git add app.sh
      sh "$ROOT/lib/checks/shell/shfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip shfmt; missing tool: shfmt; install: go install mvdan.cc/sh/v3/cmd/shfmt@latest'
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" noisy >&2" "exit 0" > "$tmpdir/bin/shfmt"
      chmod +x "$tmpdir/bin/shfmt"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      git add app.sh
      sh "$ROOT/lib/checks/shell/shfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'fails when files need formatting'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/shfmt" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
while [ "$#" -gt 1 ]; do shift; done
printf "%s\n" "$1"
exit 0
EOF
      chmod +x "$tmpdir/bin/shfmt"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      git add app.sh
      sh "$ROOT/lib/checks/shell/shfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stdout should eq ''
    The stderr should include 'git-hooks: error: shfmt failed; exit=1'
    The stderr should include 'app.sh'
  End

  It 'skips staged binary shell files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shfmt.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf unexpected" "exit 1" > "$tmpdir/bin/shfmt"
      chmod +x "$tmpdir/bin/shfmt"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-sh" > generated.sh
      git add generated.sh
      sh "$ROOT/lib/checks/shell/shfmt.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End
End
