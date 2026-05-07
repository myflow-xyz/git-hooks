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
End
