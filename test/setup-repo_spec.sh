Describe 'setup-repo.sh'
  It 'bootstraps minimal repo-local hooks with the default common profile'
    When run sh -u -c '
      ROOT=$1
      set -e
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh"
      [ -x .githooks/pre-commit ]
      [ -x .githooks/commit-msg ]
      [ -x .githooks/pre-push ]
      cmp -s "$ROOT/templates/repo-githooks/pre-commit" .githooks/pre-commit
      cmp -s "$ROOT/templates/repo-githooks/commit-msg" .githooks/commit-msg
      cmp -s "$ROOT/templates/repo-githooks/pre-push" .githooks/pre-push
      [ ! -e .githooks/hooks.env ]
      [ ! -e .githooks/project.conf ]
      [ "$(git config --local --get core.hooksPath)" = ".githooks" ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'installed;'
    The stdout should include 'hooks=pre-commit pre-push commit-msg'
  End

  It 'supports optional hook selection'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --hooks "pre-commit pre-push commit-msg"
      [ -x .githooks/pre-commit ]
      [ -x .githooks/pre-push ]
      [ -x .githooks/commit-msg ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'hooks=pre-commit pre-push commit-msg'
  End

  It 'supports custom profile settings through project config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --profiles "common react-vite"
      grep -F "GIT_HOOK_PROFILES=\"common react-vite\"" .githooks/project.conf >/dev/null
      [ -x .githooks/pre-push ]
      ! grep -F "GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS" .githooks/project.conf >/dev/null
      ! grep -F "GIT_HOOK_PRE_PUSH_EXTRA_CHECKS" .githooks/project.conf >/dev/null
      ! grep -F "GIT_HOOK_COMMIT_MSG_EXTRA_CHECKS" .githooks/project.conf >/dev/null
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'installed;'
    The stdout should include 'hooks=pre-commit pre-push commit-msg'
  End

  It 'infers pre-push when selected profiles define pre-push checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --profiles "common shell"
      [ -x .githooks/pre-commit ]
      [ -x .githooks/pre-push ]
      [ -x .githooks/commit-msg ]
      grep -F "GIT_HOOK_PROFILES=\"common shell\"" .githooks/project.conf >/dev/null
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'hooks=pre-commit pre-push commit-msg'
    The stdout should include 'profiles=common shell'
  End

  It 'lets explicit hook selection override profile hook inference'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --hooks "pre-commit commit-msg" --profiles "common shell"
      [ -x .githooks/pre-commit ]
      [ ! -e .githooks/pre-push ]
      [ -x .githooks/commit-msg ]
      grep -F "GIT_HOOK_PROFILES=\"common shell\"" .githooks/project.conf >/dev/null
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'hooks=pre-commit commit-msg'
  End

  It 'checks project config that omits default profile and sets only extra checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" >/dev/null
      printf "%s\n" "GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS=\"common/whitespace\"" > .githooks/project.conf
      sh "$ROOT/setup-repo.sh" --check
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'check ok;'
  End

  It 'checks an existing bootstrap'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" >/dev/null
      sh "$ROOT/setup-repo.sh" --check
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'check ok;'
  End

  It 'fails check when core.hooksPath is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo/.githooks"
      cd "$tmpdir/repo"
      git init -q
      cp "$ROOT/templates/repo-githooks/pre-commit" .githooks/pre-commit
      cp "$ROOT/templates/repo-githooks/pre-push" .githooks/pre-push
      cp "$ROOT/templates/repo-githooks/commit-msg" .githooks/commit-msg
      chmod +x .githooks/pre-commit
      chmod +x .githooks/pre-push
      chmod +x .githooks/commit-msg
      sh "$ROOT/setup-repo.sh" --check
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'core.hooksPath mismatch'
  End

  It 'supports --repo from outside the target repository'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/outside"
      cd "$tmpdir/repo"
      git init -q
      cd "$tmpdir/outside"
      sh "$ROOT/setup-repo.sh" --repo "$tmpdir/repo"
      [ ! -e "$tmpdir/repo/.githooks/project.conf" ]
      [ "$(git -C "$tmpdir/repo" config --local --get core.hooksPath)" = ".githooks" ]
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'profiles=common'
  End

  It 'preserves an existing hooks.env without creating one by default'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo/.githooks"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "GIT_HOOK_VERBOSE=1" > .githooks/hooks.env
      sh "$ROOT/setup-repo.sh" >/dev/null
      grep -F "GIT_HOOK_VERBOSE=1" .githooks/hooks.env >/dev/null
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'fails check when non-default profile config is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --profiles "common" >/dev/null
      sh "$ROOT/setup-repo.sh" --check --profiles "common react-vite"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'missing project config'
  End

  It 'fails check when profiles do not match'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" >/dev/null
      printf "%s\n" "GIT_HOOK_PROFILES=\"common\"" > .githooks/project.conf
      sh "$ROOT/setup-repo.sh" --check --profiles "common react-vite"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'profile mismatch'
  End

  It 'rejects unknown hook names'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --hooks "pre-commit nope"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'unknown hook: nope'
  End

  It 'rejects empty hook selection'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --hooks ""
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'hooks cannot be empty'
  End

  It 'rejects empty profile selection'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --profiles ""
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'profiles cannot be empty'
  End

  It 'rejects whitespace-only profile selection'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --profiles "   "
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'profiles cannot be empty'
  End

  It 'rejects unknown profiles during install'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" --profiles "common golagn"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'unknown profile: golagn'
  End

  It 'rejects unknown profiles during check'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" >/dev/null
      sh "$ROOT/setup-repo.sh" --check --profiles "common golagn"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'unknown profile: golagn'
  End

  It 'rejects duplicate profiles during check'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-install.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-repo.sh" >/dev/null
      sh "$ROOT/setup-repo.sh" --check --profiles "common common"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'duplicate profile: common'
  End
End
