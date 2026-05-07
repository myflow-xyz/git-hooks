Describe 'lib/checks/common/whitespace.sh'
  It 'passes when staged files have no whitespace errors'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-whitespace.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "ok\n" > file.txt
      git add file.txt
      sh "$ROOT/lib/checks/common/whitespace.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'fails on staged whitespace errors'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-whitespace.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "bad trailing space \n" > file.txt
      git add file.txt
      sh "$ROOT/lib/checks/common/whitespace.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stdout should include 'trailing whitespace'
  End

  It 'passes with staged binary files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-whitespace.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary trailing space " > image.bin
      git add image.bin
      sh "$ROOT/lib/checks/common/whitespace.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End
End
