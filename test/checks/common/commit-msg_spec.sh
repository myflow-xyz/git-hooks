Describe 'lib/checks/common/commit-msg.sh'
  It 'passes conventional commit subject with mandatory scope'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      printf "%s\n\n%s\n" "feat(config): add commit message check" "optional body" > "$tmpdir/COMMIT_EDITMSG"
      sh "$ROOT/lib/checks/common/commit-msg.sh" "$tmpdir/COMMIT_EDITMSG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'fails when scope is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export GIT_HOOK_PHASE=commit-msg
      printf "%s\n" "feat: missing scope" > "$tmpdir/COMMIT_EDITMSG"
      sh "$ROOT/lib/checks/common/commit-msg.sh" "$tmpdir/COMMIT_EDITMSG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid commit subject: scope is required'
    The stderr should include 'commit-msg: info: expected subject: <type>(scope): brief description; allowed types: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
    The stderr should not include 'commit-msg: error: expected subject'
    The stderr should not include 'feat: missing scope'
  End

  It 'fails when type is unknown'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export GIT_HOOK_PHASE=commit-msg
      printf "%s\n" "change(config): unknown type" > "$tmpdir/COMMIT_EDITMSG"
      sh "$ROOT/lib/checks/common/commit-msg.sh" "$tmpdir/COMMIT_EDITMSG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid commit subject: unknown type'
    The stderr should include 'commit-msg: info: expected subject: <type>(scope): brief description; allowed types: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
    The stderr should not include 'change(config): unknown type'
  End

  It 'fails when brief description is empty'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export GIT_HOOK_PHASE=commit-msg
      printf "%s\n" "fix(config): " > "$tmpdir/COMMIT_EDITMSG"
      sh "$ROOT/lib/checks/common/commit-msg.sh" "$tmpdir/COMMIT_EDITMSG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid commit subject: description is required'
    The stderr should include 'commit-msg: info: expected subject: <type>(scope): brief description; allowed types: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
    The stderr should not include 'fix(config):'
  End

  It 'rejects missing commit message file argument'
    When run sh "$SHELLSPEC_PROJECT_ROOT/lib/checks/common/commit-msg.sh"
    The status should eq 2
    The stderr should include 'Usage: commit-msg.sh <commit-message-file>'
  End
End
