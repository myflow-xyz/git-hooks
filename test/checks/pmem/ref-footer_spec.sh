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
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
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
printf "%s\n" "{\"ok\":true,\"data\":{\"project_exists\":false},\"events\":[],\"warnings\":[]}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should include 'commit-msg: warn: no pmem config but pmem check hook enabled; skip'
  End

  It 'passes silently when a ref footer references an open task'
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  [ "$4" = proj-1 ] || exit 8
  [ "$5" = --id ] || exit 8
  [ "$6" = SPEC-123 ] || exit 8
  [ "$7" = --json ] || exit 8
  printf "%s\n" "{\"ok\":true,\"data\":{\"status\":\"open\"},\"events\":[],\"warnings\":[]}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-verbose\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"ok\":true,\"data\":{\"status\":\"active\"},\"events\":[],\"warnings\":[]}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: task_123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'commit-msg: pmem project_id: proj-verbose'
    The stdout should include 'commit-msg: pmem task_id: task_123'
    The stdout should include 'commit-msg: pmem task_status: active'
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
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem info failed; exit=7'
  End

  It 'fails when pmem info reports ok false'
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
printf "%s\n" "{\"ok\":false,\"error\":\"api unavailable\"}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem info returned ok=false'
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
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
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
printf "%s\n" "{\"ok\":true,\"data\":{\"project_exists\":true},\"events\":[],\"warnings\":[]}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem repo config missing project_id'
  End

  It 'fails when the ref footer is missing'
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
printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): require footer" "Body only." > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing ref footer'
    The stderr should include 'commit-msg: info: expected footer: Ref: <task-id>; 3 <= id length < 24'
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
      export PATH=/usr/bin:/bin
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/local"
      cat > "$GIT_HOOK_PMEM_BIN" <<'"'"'EOF'"'"'
#!/usr/bin/env sh
case "$1 $2 $3" in
"info --repo --json")
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-local\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  [ "$4" = proj-local ] || exit 8
  printf "%s\n" "{\"ok\":true,\"data\":{\"status\":\"open\"},\"events\":[],\"warnings\":[]}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$GIT_HOOK_PMEM_BIN"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
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
printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): reject short id" "Ref: ab" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid ref footer id'
    The stderr should include 'commit-msg: info: expected footer: Ref: <task-id>; 3 <= id length < 24'
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
printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): reject long id" "Ref: abcdefghijklmnopqrstuvwx" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid ref footer id'
    The stderr should include 'commit-msg: info: expected footer: Ref: <task-id>; 3 <= id length < 24'
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
printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): reject malformed id" "Ref: issue.123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: invalid ref footer id'
    The stderr should include 'commit-msg: info: expected footer: Ref: <task-id>; 3 <= id length < 24'
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
printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n%s\n" "feat(pmem): reject body token" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: missing ref footer'
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
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
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem wi get failed; id=SPEC-123; exit=6'
  End

  It 'fails when pmem wi get reports ok false'
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"ok\":false,\"error\":\"missing work item\"}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem wi get returned ok=false'
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"ok\":true,\"data\":{\"title\":\"task\"},\"events\":[],\"warnings\":[]}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): add ref footer" "Ref: SPEC-123" > COMMIT_EDITMSG
      sh "$ROOT/lib/checks/pmem/ref-footer.sh" COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'commit-msg: error: pmem wi get response missing task status; id=SPEC-123'
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"ok\":true,\"data\":{\"status\":\"canceled\"},\"events\":[],\"warnings\":[]}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): canceled task" "Ref: SPEC-123" > COMMIT_EDITMSG
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"ok\":true,\"data\":{\"status\":\"done\"},\"events\":[],\"warnings\":[]}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): done task" "Ref: SPEC-123" > COMMIT_EDITMSG
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
  printf "%s\n" "{\"ok\":true,\"data\":{\"project_id\":\"proj-1\"},\"events\":[],\"warnings\":[]}"
  ;;
"wi get --project-id")
  printf "%s\n" "{\"ok\":true,\"data\":{\"status\":\"closed\"},\"events\":[],\"warnings\":[]}"
  ;;
*)
  exit 8
  ;;
esac
EOF
      chmod +x "$tmpdir/bin/pmem"
      export PATH="$tmpdir/bin:$PATH"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n\n%s\n" "feat(pmem): closed task" "Ref: SPEC-123" > COMMIT_EDITMSG
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
