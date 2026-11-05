Describe 'pre-push checkout cleanliness'
  push_clean_case() (
    push_root=$SHELLSPEC_PROJECT_ROOT
    push_case=$1
    push_tmp=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-push-clean.XXXXXX") || exit 2
    trap 'rm -rf "$push_tmp"' EXIT HUP INT TERM
    GIT_HOOKS_COMMON_DIR=$push_root/lib/common
    . "$GIT_HOOKS_COMMON_DIR/env.sh"
    git_hooks_env_unset_git_local_vars
    git_hooks_env_unset_hook_runtime_vars
    export GIT_HOOKS_HOME="$push_tmp/runtime" GIT_HOOK_VERBOSE=0
    export PUSH_GUARD_TRACE="$push_tmp/trace" PUSH_GUARD_MODE="$push_case"
    mkdir -p "$GIT_HOOKS_HOME/lib/dispatcher" "$GIT_HOOKS_HOME/lib/checks/test" \
      "$GIT_HOOKS_HOME/profiles/test" "$push_tmp/repo/.githooks/hooks" "$push_tmp/bin"
    cp -R "$push_root/lib/common" "$GIT_HOOKS_HOME/lib/common"
    cp "$push_root/lib/dispatcher/run-hook.sh" "$GIT_HOOKS_HOME/lib/dispatcher/run-hook.sh"
    cat >"$GIT_HOOKS_HOME/lib/checks/test/record.sh" <<'EOF'
#!/usr/bin/env sh
printf 'profile\n' >>"$PUSH_GUARD_TRACE"
if [ "$PUSH_GUARD_MODE" = after_tracked ]; then
  printf 'changed by check\n' >'tracked file.txt'
fi
EOF
    cat >"$push_tmp/repo/.githooks/hooks/finish.sh" <<'EOF'
#!/usr/bin/env sh
printf 'local\n' >>"$PUSH_GUARD_TRACE"
case "$PUSH_GUARD_MODE" in
  after_untracked) printf 'generated\n' >generated.txt ;;
  after_staged)
    printf 'staged by check\n' >'tracked file.txt'
    git add -- 'tracked file.txt'
    ;;
  ignored_after)
    mkdir -p ignored-output
    printf 'cache\n' >ignored-output/result
    ;;
esac
EOF
    chmod +x "$GIT_HOOKS_HOME/lib/checks/test/record.sh" "$push_tmp/repo/.githooks/hooks/finish.sh"
    printf 'test/record\n' >"$GIT_HOOKS_HOME/profiles/test/pre-push.list"
    printf 'test/record\n' >"$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
    printf '%s\n' 'GIT_HOOK_PROFILES=test' 'GIT_HOOK_PRE_PUSH_EXTRA_LOCAL_HOOKS=finish' \
      >"$push_tmp/repo/.githooks/project.conf"
    cd "$push_tmp/repo" || exit 2
    git init -q
    git config core.hooksPath /dev/null
    git config user.name Test
    git config user.email test@example.com
    git config commit.gpgsign false
    printf '/ignored-output/\n' >.git/info/exclude
    printf 'original\n' >'tracked file.txt'
    git add --all
    git commit -qm fixture

    if [ "$push_case" = real_push ]; then
      mkdir -p "$push_tmp/hooks"
      cp "$push_root/templates/repo-githooks/pre-push" "$push_tmp/hooks/pre-push"
      git config core.hooksPath "$push_tmp/hooks"
      git init --bare -q "$push_tmp/remote.git"
      printf 'unfinished\n' >'tracked file.txt'
      if git push "$push_tmp/remote.git" HEAD:refs/heads/check >"$push_tmp/push.log" 2>&1; then
        exit 91
      fi
      grep -q 'push requires a clean checkout' "$push_tmp/push.log" || exit 92
      push_remote_ref=$(git --git-dir="$push_tmp/remote.git" for-each-ref --format='%(objectname)' refs/heads/check) || exit $?
      [ -z "$push_remote_ref" ] && [ ! -f "$PUSH_GUARD_TRACE" ] || exit 93
      printf 'original\n' >'tracked file.txt'
      git push "$push_tmp/remote.git" HEAD:refs/heads/check >"$push_tmp/push.log" 2>&1 || {
        cat "$push_tmp/push.log" >&2
        exit 94
      }
      push_remote_ref=$(git --git-dir="$push_tmp/remote.git" rev-parse refs/heads/check) || exit $?
      [ "$push_remote_ref" = "$(git rev-parse HEAD)" ] || exit 95
      exit 0
    fi

    push_phase=pre-push
    case "$push_case" in
    staged)
      printf 'pending\n' >'tracked file.txt'
      git add -- 'tracked file.txt'
      ;;
    unstaged | no_checks)
      printf 'pending\n' >'tracked file.txt'
      if [ "$push_case" = no_checks ]; then
        rm "$GIT_HOOKS_HOME/profiles/test/pre-push.list"
      fi
      ;;
    untracked)
      git config status.showUntrackedFiles no
      printf 'pending\n' >'new file.txt'
      ;;
    deleted) rm 'tracked file.txt' ;;
    ignored)
      mkdir ignored-output
      printf 'cache\n' >ignored-output/cache
      ;;
    commit)
      push_phase=pre-commit
      printf 'staged\n' >'tracked file.txt'
      git add -- 'tracked file.txt'
      printf 'unstaged\n' >'tracked file.txt'
      ;;
    query_error)
      PUSH_REAL_GIT=$(command -v git)
      export PUSH_REAL_GIT
      cat >"$push_tmp/bin/git" <<'EOF'
#!/usr/bin/env sh
if [ "$1" = status ]; then
  printf 'Git status failed\n' >&2
  exit 9
fi
exec "$PUSH_REAL_GIT" "$@"
EOF
      chmod +x "$push_tmp/bin/git"
      export PATH="$push_tmp/bin:$PATH"
      ;;
    esac

    git diff --binary HEAD >"$push_tmp/before"
    git ls-files --stage >"$push_tmp/index-before"
    sh "$GIT_HOOKS_HOME/lib/dispatcher/run-hook.sh" "$push_phase" >"$push_tmp/output" 2>"$push_tmp/errors"
    push_status=$?
    case "$push_case" in
    staged | unstaged | untracked | deleted | no_checks | query_error)
      [ ! -f "$PUSH_GUARD_TRACE" ] || exit 96
      git diff --binary HEAD >"$push_tmp/after"
      git ls-files --stage >"$push_tmp/index-after"
      cmp -s "$push_tmp/before" "$push_tmp/after" || exit 97
      cmp -s "$push_tmp/index-before" "$push_tmp/index-after" || exit 98
      ;;
    commit)
      [ "$(cat "$PUSH_GUARD_TRACE")" = profile ] || exit 99
      ;;
    *)
      [ "$(cat "$PUSH_GUARD_TRACE")" = "$(printf 'profile\nlocal')" ] || exit 100
      ;;
    esac
    cat "$push_tmp/output"
    cat "$push_tmp/errors" >&2
    exit "$push_status"
  )

  It 'allows a clean checkout and runs profile and local checks'
    When run push_clean_case clean
    The status should eq 0
    The output should eq ''
  End

  It 'rejects staged changes before running checks'
    When run push_clean_case staged
    The status should eq 1
    The stderr should include 'push requires a clean checkout'
    The stderr should include 'tracked file.txt'
  End

  It 'rejects unstaged changes before running checks'
    When run push_clean_case unstaged
    The status should eq 1
    The stderr should include 'push requires a clean checkout'
  End

  It 'rejects untracked files even when user status configuration hides them'
    When run push_clean_case untracked
    The status should eq 1
    The stderr should include 'new file.txt'
  End

  It 'rejects unstaged deletions'
    When run push_clean_case deleted
    The status should eq 1
    The stderr should include 'tracked file.txt'
  End

  It 'allows ignored files'
    When run push_clean_case ignored
    The status should eq 0
    The output should eq ''
  End

  It 'rejects tracked files changed by a successful check'
    When run push_clean_case after_tracked
    The status should eq 1
    The stderr should include 'tracked file.txt'
  End

  It 'rejects untracked output from the last local hook'
    When run push_clean_case after_untracked
    The status should eq 1
    The stderr should include 'generated.txt'
  End

  It 'rejects changes staged by a successful local hook'
    When run push_clean_case after_staged
    The status should eq 1
    The stderr should include 'tracked file.txt'
  End

  It 'allows ignored output generated by checks'
    When run push_clean_case ignored_after
    The status should eq 0
    The output should eq ''
  End

  It 'enforces cleanliness even without a profile phase list'
    When run push_clean_case no_checks
    The status should eq 1
    The stderr should include 'push requires a clean checkout'
  End

  It 'preserves Git query failures and does not run checks'
    When run push_clean_case query_error
    The status should eq 9
    The stderr should include 'Git status failed'
    The stderr should include 'cannot verify checkout cleanliness; exit=9'
  End

  It 'does not impose push cleanliness on commits'
    When run push_clean_case commit
    The status should eq 0
    The output should eq ''
  End

  It 'blocks a real local push until the checkout is clean'
    When run push_clean_case real_push
    The status should eq 0
    The output should eq ''
  End
End
