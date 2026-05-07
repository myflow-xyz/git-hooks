Describe 'lib/checks/python/pytest.sh'
  It 'skips when tests are missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/python/pytest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when pytest is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME" "$tmpdir/tests"
      cd "$tmpdir"
      git init -q
      printf "def test_ok():\n    assert True\n" > tests/test_app.py
      git add tests/test_app.py
      git commit -qm init
      sh "$ROOT/lib/checks/python/pytest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip pytest; missing tool: pytest; install: uv add --dev pytest'
  End

  It 'runs pytest and keeps success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PYTEST_LOG="$tmpdir/pytest-log"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/tests"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$PYTEST_LOG\"" "exit 0" > "$tmpdir/bin/pytest"
      chmod +x "$tmpdir/bin/pytest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "def test_ok():\n    assert True\n" > tests/test_app.py
      git add tests/test_app.py
      git commit -qm init
      sh "$ROOT/lib/checks/python/pytest.sh"
      cat "$PYTEST_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '-o cache_dir='
    The stdout should not include '.pytest_cache'
    The stderr should eq ''
  End

  It 'returns status and prints output when tests fail'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/tests"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"tests failed\"" "exit 7" > "$tmpdir/bin/pytest"
      chmod +x "$tmpdir/bin/pytest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "def test_bad():\n    assert False\n" > tests/test_app.py
      git add tests/test_app.py
      git commit -qm init
      sh "$ROOT/lib/checks/python/pytest.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 7
    The stdout should eq ''
    The stderr should include 'git-hooks: error: pytest failed; exit=7'
    The stderr should include 'tests failed'
  End
End
