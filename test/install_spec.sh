Describe 'install.sh'
  It 'installs the shared runtime into XDG config home'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME"
      sh "$ROOT/install.sh"
      [ -L "$XDG_CONFIG_HOME/git-hooks" ]
      [ "$(readlink "$XDG_CONFIG_HOME/git-hooks")" = "$ROOT" ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'installed;'
  End

  It 'rejects install when git is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      shell_path=$(command -v sh)
      mkdir -p "$tmpdir/bin"
      PATH="$tmpdir/bin" "$shell_path" "$ROOT/install.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'required command not found: git'
    The stderr should include 'Git >= 2.9.0'
  End

  It 'rejects install when git version cannot be detected'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      shell_path=$(command -v sh)
      mkdir -p "$tmpdir/bin"
      printf "%s\n" "#!$shell_path" "exit 1" > "$tmpdir/bin/git"
      chmod +x "$tmpdir/bin/git"
      PATH="$tmpdir/bin" "$shell_path" "$ROOT/install.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'git version not found'
    The stderr should include 'Git >= 2.9.0'
  End

  It 'rejects install when git is too old for core.hooksPath'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      shell_path=$(command -v sh)
      mkdir -p "$tmpdir/bin"
      printf "%s\n" "#!$shell_path" "printf \"%s\\n\" \"git version 2.8.5\"" > "$tmpdir/bin/git"
      chmod +x "$tmpdir/bin/git"
      PATH="$tmpdir/bin" "$shell_path" "$ROOT/install.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'git version too old: 2.8.5'
    The stderr should include 'Git >= 2.9.0'
  End

  It 'checks an existing XDG runtime symlink'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME"
      ln -s "$ROOT" "$XDG_CONFIG_HOME/git-hooks"
      sh "$ROOT/install.sh" --check
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'check ok;'
  End

  It 'checks successfully when invoked through the installed XDG symlink'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME"
      sh "$ROOT/install.sh"
      sh "$XDG_CONFIG_HOME/git-hooks/install.sh" --check
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'check ok;'
  End

  It 'does not rewrite the runtime link when fix is invoked through the installed XDG symlink'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME"
      sh "$ROOT/install.sh" >/dev/null
      before=$(readlink "$XDG_CONFIG_HOME/git-hooks")
      sh "$XDG_CONFIG_HOME/git-hooks/install.sh" --fix-links
      after=$(readlink "$XDG_CONFIG_HOME/git-hooks")
      [ "$before" = "$after" ]
      [ "$after" != "$XDG_CONFIG_HOME/git-hooks" ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'check ok;'
  End

  It 'fails default install when target points elsewhere'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$tmpdir/other"
      ln -s "$tmpdir/other" "$XDG_CONFIG_HOME/git-hooks"
      sh "$ROOT/install.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'target symlink points elsewhere'
    The stderr should include 'run install.sh --fix-links'
  End

  It 'suggests fix-links when default install finds a real target'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME/git-hooks"
      sh "$ROOT/install.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'target exists and is not a symlink'
    The stderr should include 'run install.sh --fix-links'
  End

  It 'fixes a wrong XDG runtime symlink explicitly'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$tmpdir/other"
      ln -s "$tmpdir/other" "$XDG_CONFIG_HOME/git-hooks"
      sh "$ROOT/install.sh" --fix-links
      [ "$(readlink "$XDG_CONFIG_HOME/git-hooks")" = "$ROOT" ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'installed;'
  End

  It 'backs up a real target before fixing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export XDG_CONFIG_HOME="$tmpdir/xdg-config"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME/git-hooks"
      sh "$ROOT/install.sh" --fix-links
      [ "$(readlink "$XDG_CONFIG_HOME/git-hooks")" = "$ROOT" ]
      backup=$(find "$XDG_CONFIG_HOME" -maxdepth 1 -name "git-hooks.*.bak" -type d -print | head -n 1)
      [ -d "$backup" ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'backed up target;'
  End
End
