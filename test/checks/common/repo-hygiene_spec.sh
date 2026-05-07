Describe 'lib/checks/common/repo-hygiene.sh'
  It 'stays silent in quiet mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-repo-hygiene.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/common/repo-hygiene.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'recommends missing repo hygiene files in verbose mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-repo-hygiene.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/common/repo-hygiene.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'recommend: add .gitattributes'
    The stdout should include 'recommend: add .gitignore'
    The stdout should include 'recommend: add .editorconfig'
  End

  It 'recommends LF policy when gitattributes lacks active eol-lf'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-repo-hygiene.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "* text=auto\n" > .gitattributes
      printf "node_modules/\n" > .gitignore
      printf "[*]\nend_of_line = lf\n" > .editorconfig
      sh "$ROOT/lib/checks/common/repo-hygiene.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'recommend: add active .gitattributes LF policy'
  End

  It 'treats commented eol-lf as inactive'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-repo-hygiene.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# * text=auto eol=lf\n" > .gitattributes
      printf "node_modules/\n" > .gitignore
      printf "[*]\nend_of_line = lf\n" > .editorconfig
      sh "$ROOT/lib/checks/common/repo-hygiene.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'recommend: add active .gitattributes LF policy'
  End

  It 'reports recommended files present in verbose mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-repo-hygiene.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "* text=auto eol=lf\n" > .gitattributes
      printf "node_modules/\n" > .gitignore
      printf "[*]\nend_of_line = lf\ninsert_final_newline = true\n" > .editorconfig
      sh "$ROOT/lib/checks/common/repo-hygiene.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'repo-hygiene: recommended files present'
    The stdout should not include 'recommend:'
  End

  It 'checks repo-root files when run from a subdirectory'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-repo-hygiene.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME" "$tmpdir/sub"
      cd "$tmpdir"
      git init -q
      printf "* text=auto eol=lf\n" > .gitattributes
      printf "node_modules/\n" > .gitignore
      printf "[*]\nend_of_line = lf\ninsert_final_newline = true\n" > .editorconfig
      cd "$tmpdir/sub"
      sh "$ROOT/lib/checks/common/repo-hygiene.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'repo-hygiene: recommended files present'
    The stdout should not include 'recommend:'
  End
End
