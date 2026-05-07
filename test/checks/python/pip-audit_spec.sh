Describe 'lib/checks/python/pip-audit.sh'
  It 'skips when dependency manifests are missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pip-audit.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/python/pip-audit.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when pip-audit is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pip-audit.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "[project]\nname = \"app\"\n" > pyproject.toml
      sh "$ROOT/lib/checks/python/pip-audit.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip pip-audit; missing tool: pip-audit; install: uv add --dev pip-audit'
  End

  It 'audits pyproject project path'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pip-audit.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PIP_AUDIT_LOG="$tmpdir/pip-audit-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$PIP_AUDIT_LOG\"" "exit 0" > "$tmpdir/bin/pip-audit"
      chmod +x "$tmpdir/bin/pip-audit"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "[project]\nname = \"app\"\n" > pyproject.toml
      sh "$ROOT/lib/checks/python/pip-audit.sh"
      cat "$PIP_AUDIT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '--progress-spinner off .'
    The stderr should eq ''
  End

  It 'audits requirements file'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pip-audit.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PIP_AUDIT_LOG="$tmpdir/pip-audit-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$PIP_AUDIT_LOG\"" "exit 0" > "$tmpdir/bin/pip-audit"
      chmod +x "$tmpdir/bin/pip-audit"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "requests==2.32.0\n" > requirements.txt
      sh "$ROOT/lib/checks/python/pip-audit.sh"
      cat "$PIP_AUDIT_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '--progress-spinner off -r requirements.txt'
    The stderr should eq ''
  End

  It 'returns status and prints output when audit fails'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pip-audit.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"audit failed\"" "exit 10" > "$tmpdir/bin/pip-audit"
      chmod +x "$tmpdir/bin/pip-audit"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      printf "[project]\nname = \"app\"\n" > pyproject.toml
      sh "$ROOT/lib/checks/python/pip-audit.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 10
    The stdout should eq ''
    The stderr should include 'git-hooks: error: pip-audit failed; exit=10'
    The stderr should include 'audit failed'
  End
End
