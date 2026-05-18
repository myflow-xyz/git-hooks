Describe 'lib/checks/shell/shellspec.sh'
  It 'skips without tracked shellspec files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/shell/shellspec.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips with an install hint when shellspec is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      : > .shellspec
      git add .shellspec
      sh "$ROOT/lib/checks/shell/shellspec.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip shellspec: missing tool; install: brew install shellspec'
  End

  It 'runs once per tracked ShellSpec directory'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export SHELLSPEC_LOG="$tmpdir/shellspec-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/shellspec" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "${PWD##*/}" in
  config|scripts) printf "%s\n" "${PWD##*/}" ;;
  *) printf "%s\n" . ;;
esac >> "$SHELLSPEC_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/shellspec"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p config scripts
      : > .shellspec
      : > config/.shellspec
      : > scripts/.shellspec
      git add .shellspec config/.shellspec scripts/.shellspec
      sh "$ROOT/lib/checks/shell/shellspec.sh"
      sort "$SHELLSPEC_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq "$(printf '.\nconfig\nscripts')"
    The stderr should eq ''
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" noisy" "exit 0" > "$tmpdir/bin/shellspec"
      chmod +x "$tmpdir/bin/shellspec"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      : > .shellspec
      git add .shellspec
      sh "$ROOT/lib/checks/shell/shellspec.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'reports failed directory and capped output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" shellspec-failed" "exit 6" > "$tmpdir/bin/shellspec"
      chmod +x "$tmpdir/bin/shellspec"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p config
      : > config/.shellspec
      git add config/.shellspec
      sh "$ROOT/lib/checks/shell/shellspec.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 6
    The stdout should eq ''
    The stderr should include 'git-hooks: error: shellspec failed; dir=config; exit=6'
    The stderr should include 'shellspec-failed'
  End

  It 'does not leak hook runtime environment into project ShellSpec suites'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PROFILES="common shell"
      export GIT_HOOK_PRE_PUSH_EXTRA_CHECKS="shell/shellspec"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/shellspec" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ -z "${GIT_HOOKS_HOME+x}" ] || exit 9
[ -z "${GIT_HOOK_PROFILES+x}" ] || exit 9
[ -z "${GIT_HOOK_PRE_PUSH_EXTRA_CHECKS+x}" ] || exit 9
[ -z "${GIT_HOOK_VERBOSE+x}" ] || exit 9
printf isolated
exit 0
EOF
      chmod +x "$tmpdir/bin/shellspec"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      : > .shellspec
      git add .shellspec
      sh "$ROOT/lib/checks/shell/shellspec.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'isolated'
    The stderr should eq ''
  End

  It 'does not leak Git local repository environment into project ShellSpec suites'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      export SHELLSPEC_FAKE_REPO="$tmpdir/fake"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/outer" "$SHELLSPEC_FAKE_REPO"
      SHELLSPEC_FAKE_REPO=$(CDPATH="" cd "$SHELLSPEC_FAKE_REPO" && pwd -P)
      export SHELLSPEC_FAKE_REPO
      cat > "$tmpdir/bin/shellspec" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ -z "${GIT_DIR+x}" ] || exit 9
[ -z "${GIT_WORK_TREE+x}" ] || exit 9
[ -z "${GIT_COMMON_DIR+x}" ] || exit 9
[ -z "${GIT_INDEX_FILE+x}" ] || exit 9
actual=$(git -C "$SHELLSPEC_FAKE_REPO" rev-parse --show-toplevel) || exit 10
[ "$actual" = "$SHELLSPEC_FAKE_REPO" ] || {
  printf "%s\n" "$actual"
  exit 11
}
printf isolated
exit 0
EOF
      chmod +x "$tmpdir/bin/shellspec"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/outer"
      git init -q
      : > .shellspec
      git add .shellspec
      git -C "$SHELLSPEC_FAKE_REPO" init -q
      export GIT_DIR="$PWD/.git"
      export GIT_WORK_TREE="$PWD"
      export GIT_COMMON_DIR="$PWD/.git"
      export GIT_INDEX_FILE="$PWD/.git/index"
      sh "$ROOT/lib/checks/shell/shellspec.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'isolated'
    The stderr should eq ''
  End

  It 'stops after an interrupted ShellSpec root'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shellspec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export SHELLSPEC_LOG="$tmpdir/shellspec-log"
      mkdir -p "$HOME" "$tmpdir/bin"
      cat > "$tmpdir/bin/shellspec" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "${PWD##*/}" in
  config)
    printf "%s\n" config >> "$SHELLSPEC_LOG"
    exit 130
    ;;
  scripts)
    printf "%s\n" scripts >> "$SHELLSPEC_LOG"
    exit 0
    ;;
esac
exit 0
EOF
      chmod +x "$tmpdir/bin/shellspec"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir"
      git init -q
      mkdir -p config scripts
      : > config/.shellspec
      : > scripts/.shellspec
      git add config/.shellspec scripts/.shellspec
      sh "$ROOT/lib/checks/shell/shellspec.sh"
      status=$?
      cat "$SHELLSPEC_LOG"
      exit "$status"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 130
    The stdout should eq 'config'
    The stdout should not include 'scripts'
    The stderr should include 'git-hooks: error: shellspec interrupted; dir=config; exit=130'
  End
End
