Describe 'lib/common/path.sh'
  It 'resolves git hooks home from XDG_CONFIG_HOME'
    When run sh -u -c '
      ROOT=$1
      export HOME=/tmp/home
      export XDG_CONFIG_HOME=/tmp/xdg
      . "$ROOT/lib/common/path.sh"
      git_hooks_paths_home
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '/tmp/xdg/git-hooks'
  End

  It 'joins paths without duplicate slashes'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/path.sh"
      git_hooks_paths_join "/tmp/root/" "/child" "leaf"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '/tmp/root/child/leaf'
  End

  It 'resolves check IDs under lib checks'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/path.sh"
      git_hooks_paths_check "/tmp/hooks" "common/whitespace"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '/tmp/hooks/lib/checks/common/whitespace.sh'
  End

  It 'passes absolute check paths through'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/path.sh"
      git_hooks_paths_check "/tmp/hooks" "/tmp/custom/check.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '/tmp/custom/check.sh'
  End

  It 'resolves direct local hook IDs under repo githooks'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/path.sh"
      git_hooks_paths_local_hook "/tmp/repo/.githooks" "yhook"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '/tmp/repo/.githooks/hooks/yhook.sh'
  End

  It 'resolves nested local hook IDs under repo githooks'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/path.sh"
      git_hooks_paths_local_hook "/tmp/repo/.githooks" "dir/xhook"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq '/tmp/repo/.githooks/hooks/dir/xhook.sh'
  End

  It 'rejects invalid local hook IDs'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/path.sh"
      ! git_hooks_paths_local_hook "/tmp/repo/.githooks" "" >/dev/null 2>&1
      for id in /xhook ../xhook dir/../xhook dir/./xhook dir//xhook dir/xhook/ dir/xhook.sh; do
        if git_hooks_paths_local_hook "/tmp/repo/.githooks" "$id" >/dev/null 2>&1; then
          printf "accepted:%s\n" "$id"
          exit 1
        fi
      done
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End
End
