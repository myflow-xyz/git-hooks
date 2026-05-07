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
    The stderr should include 'warn: skip ruff-format; missing tool: ruff; install: uv add --dev ruff'
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
End
