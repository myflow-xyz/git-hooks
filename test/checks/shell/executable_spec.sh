Describe 'lib/checks/shell/executable.sh'
  It 'skips without staged shell files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-exec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      git add README.md
      sh "$ROOT/lib/checks/shell/executable.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'allows non-executable shell fragments'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-exec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "export APP=1\n" > env.sh
      git add env.sh
      sh "$ROOT/lib/checks/shell/executable.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'passes executable shell files with shell shebang'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-exec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "#!/usr/bin/env sh\nprintf ok\n" > run.sh
      chmod +x run.sh
      git add run.sh
      sh "$ROOT/lib/checks/shell/executable.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'fails executable shell files without shell shebang'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-exec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "printf missing\n" > run.sh
      chmod +x run.sh
      git add run.sh
      sh "$ROOT/lib/checks/shell/executable.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stdout should eq ''
    The stderr should include 'shell-executable: run.sh; missing supported shebang'
  End

  It 'checks zsh executable files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-exec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "#!/usr/bin/env zsh\nprint ok\n" > run.zsh
      chmod +x run.zsh
      git add run.zsh
      sh "$ROOT/lib/checks/shell/executable.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'skips staged binary shell files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-exec.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-sh" > generated.sh
      chmod +x generated.sh
      git add generated.sh
      sh "$ROOT/lib/checks/shell/executable.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End
End
