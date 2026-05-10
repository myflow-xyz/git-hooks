Describe 'lib/checks/python/ruff-format.sh'
  It 'skips without staged Python files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-ruff-format.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/python/ruff-format.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips staged binary Python files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-ruff-format.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-py" > generated.py
      git add generated.py
      sh "$ROOT/lib/checks/python/ruff-format.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when ruff is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-ruff-format.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "print(1)\n" > app.py
      git add app.py
      sh "$ROOT/lib/checks/python/ruff-format.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip ruff-format: missing ruff; install: uv add --dev ruff'
  End

  It 'runs ruff format check and keeps success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-ruff-format.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export RUFF_LOG="$tmpdir/ruff-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$RUFF_LOG\"" "exit 0" > "$tmpdir/bin/ruff"
      chmod +x "$tmpdir/bin/ruff"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "print(1)\n" > app.py
      git add app.py
      sh "$ROOT/lib/checks/python/ruff-format.sh"
      cat "$RUFF_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'format --check app.py'
    The stderr should eq ''
  End

  It 'uses uv runner when uv.lock exists in auto mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-ruff-format.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export UV_LOG="$tmpdir/uv-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/uv" <<EOF
#!/usr/bin/env sh
printf "%s\n" "\$*" >> "$UV_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/uv"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      : > uv.lock
      printf "print(1)\n" > app.py
      git add app.py
      sh "$ROOT/lib/checks/python/ruff-format.sh"
      cat "$UV_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'run --frozen -- ruff --version'
    The stdout should include 'run --frozen -- ruff format --check app.py'
    The stderr should eq ''
  End

  It 'returns status and prints output when format fails'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-ruff-format.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"format failed\"" "exit 3" > "$tmpdir/bin/ruff"
      chmod +x "$tmpdir/bin/ruff"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "print(1)\n" > app.py
      git add app.py
      sh "$ROOT/lib/checks/python/ruff-format.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 3
    The stdout should eq ''
    The stderr should include 'git-hooks: error: ruff-format failed; exit=3'
    The stderr should include 'format failed'
  End
End
