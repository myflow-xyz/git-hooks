Describe 'lib/checks/python/mypy.sh'
  It 'skips outside Python projects'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-mypy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/python/mypy.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when mypy is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-mypy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "[project]\nname = \"app\"\n" > pyproject.toml
      sh "$ROOT/lib/checks/python/mypy.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip mypy; missing tool: mypy; install: uv add --dev mypy'
  End

  It 'runs mypy and keeps success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-mypy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export MYPY_LOG="$tmpdir/mypy-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MYPY_LOG\"" "exit 0" > "$tmpdir/bin/mypy"
      chmod +x "$tmpdir/bin/mypy"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "[project]\nname = \"app\"\n" > pyproject.toml
      sh "$ROOT/lib/checks/python/mypy.sh"
      cat "$MYPY_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '--cache-dir'
    The stdout should include ' .'
    The stderr should eq ''
  End

  It 'returns status and prints output when mypy fails'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-mypy.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"type failed\"" "exit 6" > "$tmpdir/bin/mypy"
      chmod +x "$tmpdir/bin/mypy"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "[project]\nname = \"app\"\n" > pyproject.toml
      sh "$ROOT/lib/checks/python/mypy.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 6
    The stdout should eq ''
    The stderr should include 'git-hooks: error: mypy failed; exit=6'
    The stderr should include 'type failed'
  End
End
