Describe 'lib/checks/python/pytest-cov.sh'
  It 'skips when tests are missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest-cov.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/python/pytest-cov.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when pytest is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest-cov.XXXXXX")
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
      sh "$ROOT/lib/checks/python/pytest-cov.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip pytest-cov; missing tool: pytest; install: uv add --dev pytest pytest-cov'
  End

  It 'skips when pytest-cov is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest-cov.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/tests"
      printf "%s\n" "#!/usr/bin/env sh" "[ \"\$1\" = --help ] && exit 0" "exit 8" > "$tmpdir/bin/pytest"
      chmod +x "$tmpdir/bin/pytest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "def test_ok():\n    assert True\n" > tests/test_app.py
      git add tests/test_app.py
      git commit -qm init
      sh "$ROOT/lib/checks/python/pytest-cov.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip pytest-cov; missing tool: pytest-cov; install: uv add --dev pytest-cov'
  End

  It 'runs pytest with coverage and keeps success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest-cov.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PYTEST_LOG="$tmpdir/pytest-log"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/tests"
      cat > "$tmpdir/bin/pytest" <<EOF
#!/usr/bin/env sh
if [ "\$1" = --help ]; then
  printf "%s\n" "  --cov=SOURCE"
  exit 0
fi
printf "%s\n" "\$*" >> "$PYTEST_LOG"
[ -n "\${COVERAGE_FILE:-}" ] || exit 8
exit 0
EOF
      chmod +x "$tmpdir/bin/pytest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "def test_ok():\n    assert True\n" > tests/test_app.py
      git add tests/test_app.py
      git commit -qm init
      sh "$ROOT/lib/checks/python/pytest-cov.sh"
      cat "$PYTEST_LOG"
      [ ! -e .coverage ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '-o cache_dir='
    The stdout should include '--cov=. --cov-report=term-missing:skip-covered'
    The stdout should not include '.pytest_cache'
    The stderr should eq ''
  End

  It 'returns status and prints output when coverage fails'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pytest-cov.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/tests"
      cat > "$tmpdir/bin/pytest" <<EOF
#!/usr/bin/env sh
if [ "\$1" = --help ]; then
  printf "%s\n" "  --cov=SOURCE"
  exit 0
fi
printf "%s\n" "coverage failed"
exit 9
EOF
      chmod +x "$tmpdir/bin/pytest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "def test_bad():\n    assert False\n" > tests/test_app.py
      git add tests/test_app.py
      git commit -qm init
      sh "$ROOT/lib/checks/python/pytest-cov.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 9
    The stdout should eq ''
    The stderr should include 'git-hooks: error: pytest-cov failed; exit=9'
    The stderr should include 'coverage failed'
  End
End
