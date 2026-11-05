Describe 'lib/checks/golang/go-test-race.sh'
  Include "$SHELLSPEC_PROJECT_ROOT/test/checks/golang/_quality-gate.sh"

  It 'runs fresh race tests and honors short mode'
    When run quality_gate race
    The status should eq 0
    The output should eq ''
  End

  It 'preserves race and unsupported-environment failures'
    When run quality_gate race_failure
    The status should eq 7
    The stderr should include 'go-test-race failed; exit=7'
  End

  It 'keeps race detection out of the default Go profile'
    When run grep -F golang/go-test-race "$SHELLSPEC_PROJECT_ROOT/profiles/golang/pre-push.list"
    The status should eq 1
    The output should eq ''
  End
End
