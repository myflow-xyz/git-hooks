Describe 'lib/common/git.sh'
  It 'lists staged files and filters by extension'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-git.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "# Title\n" > README.md
      printf "package main\n" > main.go
      git add README.md main.go
      . "$ROOT/lib/common/git.sh"
      git_hooks_git_staged_files_by_extension md markdown
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'README.md'
  End

  It 'lists staged text files by extension and skips binary files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-git.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "console.log(1)\n" > app.ts
      printf "\000\001binary-ts" > generated.ts
      git add app.ts generated.ts
      . "$ROOT/lib/common/git.sh"
      git_hooks_git_staged_text_files_by_extension ts
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'app.ts'
  End

  It 'detects when staged files exist'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-git.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "x\n" > file.txt
      git add file.txt
      . "$ROOT/lib/common/git.sh"
      git_hooks_git_has_staged_files
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'reads staged file content from the index'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-git.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "staged\n" > file.txt
      git add file.txt
      printf "worktree\n" > file.txt
      . "$ROOT/lib/common/git.sh"
      git_hooks_git_show_staged_file file.txt
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'staged'
  End
End
