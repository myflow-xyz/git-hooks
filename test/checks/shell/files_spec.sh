Describe 'lib/checks/shell/_files.sh'
  It 'finds staged shell text files by extension'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-files.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_COMMON_DIR="$ROOT/lib/common"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      printf "printf bash\n" > app.bash
      printf "print zsh\n" > app.zsh
      printf "# Title\n" > README.md
      git add app.sh app.bash app.zsh README.md
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/shell/_files.sh"
      git_hooks_shell_staged_files
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'app.sh'
    The stdout should include 'app.bash'
    The stdout should include 'app.zsh'
    The stdout should not include 'README.md'
  End

  It 'excludes zsh files from sh and bash tool input'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-files.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_COMMON_DIR="$ROOT/lib/common"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "printf sh\n" > app.sh
      printf "printf bash\n" > app.bash
      printf "print zsh\n" > app.zsh
      git add app.sh app.bash app.zsh
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/shell/_files.sh"
      git_hooks_shell_staged_sh_bash_files
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'app.sh'
    The stdout should include 'app.bash'
    The stdout should not include 'app.zsh'
  End

  It 'excludes ShellSpec files from sh and bash tool input'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-files.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_COMMON_DIR="$ROOT/lib/common"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "printf app\n" > app.sh
      printf "Describe spec\n" > app_spec.sh
      git add app.sh app_spec.sh
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/shell/_files.sh"
      git_hooks_shell_staged_sh_bash_files
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'app.sh'
    The stdout should not include 'app_spec.sh'
  End

  It 'skips staged binary shell files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-files.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_COMMON_DIR="$ROOT/lib/common"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "\000\001binary-sh" > generated.sh
      git add generated.sh
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/shell/_files.sh"
      git_hooks_shell_staged_files
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End

  It 'detects staged executable file mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-files.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_COMMON_DIR="$ROOT/lib/common"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "#!/usr/bin/env sh\n" > run.sh
      chmod +x run.sh
      git add run.sh
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/shell/_files.sh"
      git_hooks_shell_staged_file_is_executable run.sh
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'detects shell dialect from staged shebang or extension'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-files.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_COMMON_DIR="$ROOT/lib/common"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      printf "#!/usr/bin/env bash\n" > script.sh
      printf "printf bash\n" > fragment.bash
      git add script.sh fragment.bash
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/shell/_files.sh"
      git_hooks_shell_staged_shell_dialect script.sh
      git_hooks_shell_staged_shell_dialect fragment.bash
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq "$(printf 'bash\nbash')"
  End

  It 'discovers tracked ShellSpec directories'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-shell-files.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_COMMON_DIR="$ROOT/lib/common"
      mkdir -p "$HOME"
      cd "$tmpdir"
      git init -q
      mkdir -p config scripts
      : > .shellspec
      : > config/.shellspec
      : > scripts/.shellspec
      git add .shellspec config/.shellspec scripts/.shellspec
      . "$ROOT/lib/common/env.sh"
      . "$ROOT/lib/checks/shell/_files.sh"
      git_hooks_shell_tracked_shellspec_dirs
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq "$(printf '.\nconfig\nscripts')"
  End
End
