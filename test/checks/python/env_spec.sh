Describe 'lib/checks/python/_env.sh'
  It 'defaults to path runner without uv.lock'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-python-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/python/_env.sh"
      git_hooks_python_runner
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'path'
    The stderr should eq ''
  End

  It 'auto-selects uv when uv.lock and uv exist'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-python-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/bin/uv"
      chmod +x "$tmpdir/bin/uv"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      : > uv.lock
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/python/_env.sh"
      git_hooks_python_runner
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'uv'
    The stderr should eq ''
  End

  It 'rejects invalid runner value'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-python-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PYTHON_RUNNER=nope
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/python/_env.sh"
      git_hooks_python_runner
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stdout should eq ''
    The stderr should include 'git-hooks: error: invalid GIT_HOOK_PYTHON_RUNNER: nope'
  End

  It 'reports missing tool in path mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-python-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PYTHON_RUNNER=path
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/python/_env.sh"
      git_hooks_python_require_tool ruff-format ruff "uv add --dev ruff"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'warn: skip ruff-format: missing ruff; install: uv add --dev ruff'
  End

  It 'runs commands through uv with configured args'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-python-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PYTHON_RUNNER=uv
      export GIT_HOOK_PYTHON_UV_ARGS="--frozen --offline"
      export UV_LOG="$tmpdir/uv-log"
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$UV_LOG\"" "exit 0" > "$tmpdir/bin/uv"
      chmod +x "$tmpdir/bin/uv"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/python/_env.sh"
      git_hooks_python_run ruff check app.py
      cat "$UV_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'run --frozen --offline -- ruff check app.py'
    The stderr should eq ''
  End

  It 'does not leak Git local repository environment into Python tools'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-python-env.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PYTHON_RUNNER=path
      export PYTHON_FAKE_REPO="$tmpdir/fake"
      mkdir -p "$HOME" "$tmpdir/outer" "$tmpdir/bin" "$PYTHON_FAKE_REPO"
      PYTHON_FAKE_REPO=$(CDPATH="" cd "$PYTHON_FAKE_REPO" && pwd -P)
      export PYTHON_FAKE_REPO
      cat > "$tmpdir/bin/pytest" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ -z "${GIT_DIR+x}" ] || exit 9
[ -z "${GIT_WORK_TREE+x}" ] || exit 9
[ -z "${GIT_COMMON_DIR+x}" ] || exit 9
[ -z "${GIT_INDEX_FILE+x}" ] || exit 9
[ -z "${GIT_HOOK_PYTHON_RUNNER+x}" ] || exit 9
actual=$(git -C "$PYTHON_FAKE_REPO" rev-parse --show-toplevel) || exit 10
[ "$actual" = "$PYTHON_FAKE_REPO" ] || exit 11
printf isolated
exit 0
EOF
      chmod +x "$tmpdir/bin/pytest"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/outer"
      git init -q
      git -C "$PYTHON_FAKE_REPO" init -q
      export GIT_DIR="$PWD/.git"
      export GIT_WORK_TREE="$PWD"
      export GIT_COMMON_DIR="$PWD/.git"
      export GIT_INDEX_FILE="$PWD/.git/index"
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/python/_env.sh"
      git_hooks_python_run pytest
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'isolated'
    The stderr should eq ''
  End
End
