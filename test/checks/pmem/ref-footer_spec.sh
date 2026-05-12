Describe 'lib/checks/pmem/ref-footer.sh'
  It 'passes when a ref footer includes a standalone ref id'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > .pmem/env
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'passes when a ref footer uses an exported quoted project key gate'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "export PMEM_PROJECT_KEY=\"APP\"" > .pmem/env
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: issue_123" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'fails when pmem env is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "feat(pmem): require env" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing pmem env: .pmem/env'
    The stderr should include 'commit-msg: info: expected PMEM_PROJECT_KEY=<key> in .pmem/env'
  End

  It 'fails when the project key is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "# no key" > .pmem/env
      printf "%s\n" "feat(pmem): require key" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing PMEM_PROJECT_KEY in .pmem/env'
    The stderr should include 'commit-msg: info: expected key: [A-Za-z0-9][A-Za-z0-9_-]*'
  End

  It 'fails when the project key is invalid'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=bad.key" > .pmem/env
      printf "%s\n" "feat(pmem): reject key" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid PMEM_PROJECT_KEY in .pmem/env'
    The stderr should include 'commit-msg: info: expected key: [A-Za-z0-9][A-Za-z0-9_-]*'
  End

  It 'fails when the ref footer is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > .pmem/env
      printf "%s\n\n%s\n" "feat(pmem): require footer" "Body only." > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing ref footer'
    The stderr should include 'commit-msg: info: expected footer: Ref: <id>; 3 <= id length < 24'
  End

  It 'passes when the ref footer id is independent from the project key'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > .pmem/env
      printf "%s\n\n%s\n" "feat(pmem): accept standalone id" "Ref: OTHER-123" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'fails when the ref id is shorter than three characters'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > .pmem/env
      printf "%s\n\n%s\n" "feat(pmem): reject short id" "Ref: ab" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid ref footer id'
    The stderr should include 'commit-msg: info: expected footer: Ref: <id>; 3 <= id length < 24'
  End

  It 'fails when the ref id has twenty-four characters'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > .pmem/env
      printf "%s\n\n%s\n" "feat(pmem): reject long id" "Ref: abcdefghijklmnopqrstuvwx" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid ref footer id'
    The stderr should include 'commit-msg: info: expected footer: Ref: <id>; 3 <= id length < 24'
  End

  It 'fails when the ref id contains unsupported characters'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > .pmem/env
      printf "%s\n\n%s\n" "feat(pmem): reject malformed id" "Ref: issue.123" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid ref footer id'
    The stderr should include 'commit-msg: info: expected footer: Ref: <id>; 3 <= id length < 24'
  End

  It 'rejects a ref id outside the footer block'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      mkdir -p "$tmpdir/repo/.pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > .pmem/env
      printf "%s\n%s\n" "feat(pmem): reject body token" "Ref: SPEC-123" > COMMIT_EDITMSG
      export GIT_HOOK_PHASE=commit-msg
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing ref footer'
  End

  It 'rejects missing commit message file argument'
    When run sh "$SHELLSPEC_PROJECT_ROOT/lib/checks/pmem/ref-footer.sh"
    The status should eq 2
    The stderr should include 'Usage: ref-footer.sh <commit-message-file>'
  End
End
