Describe 'lib/checks/pmem/ref-footer.sh'
  It 'skips with a warning when the pmem CLI is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      export PATH=/usr/bin:/bin
      unset GIT_HOOK_PMEM_BIN
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should include 'commit-msg: warn: pmem check enabled but no cli client found; skip'
  End

  It 'skips with a warning when repo pmem config is absent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ "$1" = info ] || exit 8
[ "$2" = --repo ] || exit 8
[ "$3" = --json ] || exit 8
printf "%s\n" "{\"project_exists\":false}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should include 'commit-msg: warn: no pmem config but pmem check hook enabled; skip'
  End

  It 'ignores ambient pmem project selectors when probing repo config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      export PMEM_PROJECT_ID=ambient-project
      export PMEM_PROJECT_KEY=AMBIENT
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
[ "$1" = info ] || exit 8
[ "$2" = --repo ] || exit 8
[ "$3" = --json ] || exit 8
if [ -n "${PMEM_PROJECT_ID:-}" ] || [ -n "${PMEM_PROJECT_KEY:-}" ]; then
  printf "%s\n" "{\"project_id\":\"ambient-project\"}"
  exit 0
fi
printf "%s\n" "{\"project_exists\":false}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "feat(pmem): no repo config" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should include 'commit-msg: warn: no pmem config but pmem check hook enabled; skip'
    The stderr should not include 'missing Refs footer'
  End

  It 'passes silently when a Refs footer references an open task'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  [ "$4" = proj-1 ] || exit 8
  [ "$5" = --id ] || exit 8
  [ "$6" = SPEC-123 ] || exit 8
  [ "$7" = --fields ] || exit 8
  [ "$8" = status,type ] || exit 8
  [ "$9" = --json ] || exit 8
  [ "${10}" = --quiet ] || exit 8
  printf "%s\n" "{\"status\":\"open\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'rejects the old singular Ref footer'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "pmem wi get should not be called" >&2
  exit 8
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): reject old ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing Refs footer'
    The stderr should include 'commit-msg: info: expected footer: Refs: <task-id>; 3 <= id length < 24'
    The stderr should not include 'pmem wi get should not be called'
  End

  It 'rejects non-trailer text after a valid Refs footer'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"status\":\"open\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n%s\n" "feat(pmem): reject malformed footer" "Refs: SPEC-123" "not-a-footer" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing Refs footer'
    The stderr should include 'commit-msg: info: expected footer: Refs: <task-id>; 3 <= id length < 24'
  End

  It 'rejects duplicate Refs footers before checking a single work item'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "pmem wi get should not be called" >&2
  exit 9
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n%s\n" "feat(pmem): reject duplicate refs" "Refs: OPEN-1" "Refs: CLOSED-1" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: multiple Refs footers are not allowed'
    The stderr should include 'commit-msg: info: expected footer: Refs: <task-id>; 3 <= id length < 24'
    The stderr should include 'commit-msg: info: reference exactly one PMem ticket per commit; split changes into separate commits when they belong to different tickets'
    The stderr should not include 'pmem wi get should not be called'
  End

  It 'rejects duplicate Refs footers split across commit message paragraphs'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "pmem wi get should not be called" >&2
  exit 9
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "Refs: OPEN-1" "Refs: CLOSED-1" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: multiple Refs footers are not allowed'
    The stderr should include 'commit-msg: info: reference exactly one PMem ticket per commit; split changes into separate commits when they belong to different tickets'
    The stderr should not include 'pmem wi get should not be called'
  End

  It 'rejects case-insensitive duplicate Refs footers before checking a single work item'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "pmem wi get should not be called" >&2
  exit 9
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n%s\n" "feat(pmem): reject duplicate refs" "Refs: OPEN-1" "refs: CLOSED-1" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: multiple Refs footers are not allowed'
    The stderr should include 'commit-msg: info: reference exactly one PMem ticket per commit; split changes into separate commits when they belong to different tickets'
    The stderr should not include 'pmem wi get should not be called'
  End

  It 'suppresses pmem warnings on successful checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  [ "$4" = --quiet ] || printf "%s\n" "pmem warning: noisy info" >&2
  printf "%s\n" "{\"project_id\":\"proj-quiet\"}"
  ;;
"wi get --project-id")
  [ "${10}" = --quiet ] || printf "%s\n" "pmem warning: noisy wi get" >&2
  printf "%s\n" "{\"status\":\"open\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'uses the test pmem client when an ambient binary override exists'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      export GIT_HOOK_PMEM_BIN="$tmpdir/ambient/pmem"
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin" "$tmpdir/ambient"
      printf "%s\n" "#!/usr/bin/env sh" "exit 9" > "$GIT_HOOK_PMEM_BIN"
      chmod +x "$GIT_HOOK_PMEM_BIN"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-test\"}"
  ;;
"wi get --project-id")
  [ "$4" = proj-test ] || exit 8
  printf "%s\n" "{\"status\":\"open\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'prints pmem details in verbose mode'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-verbose\",\"project_name\":\"Verbose\\nProject\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"type\":\"task\",\"status\":\"active\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: task_123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should not include 'commit-msg: pmem info response:'
    The stdout should not include 'commit-msg: pmem wi get response:'
    The stdout should not include '"events"'
    The stdout should not include '"warnings"'
    The stdout should include 'commit-msg: pmem details:'
    The stdout should include '	project=Verbose Project (proj-verbose)'
    The stdout should include '	task=task_123; type=task; status=active'
    The stderr should eq ''
  End

  It 'fails when pmem info exits non-zero'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "exit 7" > "$tmpdir/bin/pmem"
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem info failed; exit=7'
  End

  It 'fails when pmem info returns an invalid project id'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{\"project_id\":false}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem info response has invalid project_id'
  End

  It 'fails when pmem info returns malformed JSON'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"not-json\"" > "$tmpdir/bin/pmem"
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem info returned malformed JSON'
  End

  It 'fails when pmem info returns malformed JSON containing an expected field'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{bad,\"project_id\":\"proj-1\"}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem info returned malformed JSON'
  End

  It 'fails when active repo pmem config omits project id'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{\"project_exists\":true}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem repo config missing project_id'
  End

  It 'fails when the Refs footer is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{\"project_id\":\"proj-1\"}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): require footer" "Body only." > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing Refs footer'
    The stderr should include 'commit-msg: info: expected footer: Refs: <task-id>; 3 <= id length < 24'
  End

  It 'passes when GIT_HOOK_PMEM_BIN points at a local pmem client'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      export GIT_HOOK_PMEM_BIN="$tmpdir/local/pmem"
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/local"
      cat > "$GIT_HOOK_PMEM_BIN" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-local\"}"
  ;;
"wi get --project-id")
  [ "$4" = proj-local ] || exit 8
  printf "%s\n" "{\"status\":\"open\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$GIT_HOOK_PMEM_BIN"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'fails when the task id is shorter than three characters'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{\"project_id\":\"proj-1\"}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): reject short id" "Refs: ab" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid Refs footer id'
    The stderr should include 'commit-msg: info: expected footer: Refs: <task-id>; 3 <= id length < 24'
  End

  It 'fails when the task id has twenty-four characters'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{\"project_id\":\"proj-1\"}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): reject long id" "Refs: abcdefghijklmnopqrstuvwx" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid Refs footer id'
    The stderr should include 'commit-msg: info: expected footer: Refs: <task-id>; 3 <= id length < 24'
  End

  It 'fails when the task id contains unsupported characters'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{\"project_id\":\"proj-1\"}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): reject malformed id" "Refs: issue.123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid Refs footer id'
    The stderr should include 'commit-msg: info: expected footer: Refs: <task-id>; 3 <= id length < 24'
  End

  It 'rejects a task id outside the footer block'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
printf "%s\n" "{\"project_id\":\"proj-1\"}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n%s\n" "feat(pmem): reject body token" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing Refs footer'
  End

  It 'fails when pmem wi get exits non-zero'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  exit 6
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem wi get failed; id=SPEC-123; exit=6'
  End

  It 'fails when pmem wi get returns an invalid task status'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"status\":false}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem wi get response has invalid task status; id=SPEC-123'
  End

  It 'fails when pmem wi get omits task status'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"title\":\"task\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem wi get response missing task status; id=SPEC-123'
  End

  It 'fails when pmem wi get returns malformed JSON containing an expected field'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{bad,\"status\":\"open\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem wi get returned malformed JSON'
  End

  It 'fails when the task status is canceled'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"status\":\"canceled\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): canceled task" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: ticket has been canceled and does not accept new changes under this status; check whether using a correct ticket'
  End

  It 'fails when the task status is done'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"status\":\"done\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): done task" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: ticket has been done and does not accept new changes under this status; check whether using a correct ticket'
  End

  It 'fails when the task status is closed'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-pmem-commit-msg.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_PHASE=commit-msg
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/bin"
      cat > "$tmpdir/bin/pmem" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"project_id\":\"proj-1\"}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"status\":\"closed\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export GIT_HOOK_PMEM_BIN="$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): closed task" "Refs: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: ticket has been closed and does not accept new changes under this status; check whether using a correct ticket'
  End

  It 'rejects missing commit message file argument'
    When run sh "$SHELLSPEC_PROJECT_ROOT/lib/checks/pmem/ref-footer.sh"
    The status should eq 2
    The stderr should include 'Usage: ref-footer.sh <commit-message-file>'
  End
End
