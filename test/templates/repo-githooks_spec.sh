Describe 'templates/repo-githooks'
  It 'dispatches each wrapper to its matching hook phase and forwards arguments'
    When run sh -u -c '
      ROOT=$1
      set -e
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-template.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      export DISPATCH_LOG="$tmpdir/dispatch-log"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib/dispatcher"
      printf "%s\n" \
        "#!/usr/bin/env sh" \
        "printf \"%s\\n\" \"\$*\" >> \"\$DISPATCH_LOG\"" \
        > "$GIT_HOOKS_HOME/lib/dispatcher/run-hook.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/dispatcher/run-hook.sh"

      "$ROOT/templates/repo-githooks/pre-commit" alpha beta
      "$ROOT/templates/repo-githooks/pre-push" origin main
      "$ROOT/templates/repo-githooks/commit-msg" "$tmpdir/COMMIT_EDITMSG"

      cat "$DISPATCH_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'pre-commit alpha beta'
    The stdout should include 'pre-push origin main'
    The stdout should include 'commit-msg'
    The stdout should include 'COMMIT_EDITMSG'
  End

  It 'fails clearly when the dispatcher is missing'
    When run sh -u -c '
      ROOT=$1
      set -e
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-template.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME"

      "$ROOT/templates/repo-githooks/pre-commit"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 127
    The stderr should include 'git-hooks: dispatcher is not executable:'
    The stderr should include '/lib/dispatcher/run-hook.sh'
  End
End
