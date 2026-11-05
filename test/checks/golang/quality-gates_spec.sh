Describe 'Go quality gate behavior'
  Include "$SHELLSPEC_PROJECT_ROOT/test/checks/golang/_quality-gate.sh"

  It 'accepts staged formatting despite unstaged changes'
    When run quality_gate staged_good
    The status should eq 0
    The output should eq ''
  End

  It 'rejects bad staged formatting despite an unstaged fix'
    When run quality_gate staged_bad
    The status should eq 1
    The stderr should include 'goimports: main.go'
  End

  It 'honors an alternate commit index'
    When run quality_gate alternate_index
    The status should eq 1
    The stderr should include 'goimports: main.go'
  End

  It 'handles unusual staged paths and working-file deletion'
    When run quality_gate unusual_paths
    The status should eq 0
    The output should eq ''
  End

  It 'rejects failed Git discovery'
    When run quality_gate discovery_error
    The status should not eq 0
    The stderr should include 'index'
  End

  It 'checks renamed Go files'
    When run quality_gate renamed
    The status should eq 0
    The output should eq ''
  End

  It 'checks copied Go files'
    When run quality_gate copied
    The status should eq 0
    The output should eq ''
  End

  It 'skips deleted Go files'
    When run quality_gate deleted
    The status should eq 0
    The output should eq ''
  End

  It 'skips commits without relevant Go changes'
    When run quality_gate no_go
    The status should eq 0
    The output should eq ''
  End

  It 'tests nested modules and excludes vendor and test fixtures'
    When run quality_gate modules
    The status should eq 0
    The output should eq ''
  End

  It 'honors configured module selection with spaces'
    When run quality_gate explicit_modules
    The status should eq 0
    The output should eq ''
  End

  It 'finds modules below a workspace-only root'
    When run quality_gate workspace
    The status should eq 0
    The output should eq ''
  End

  It 'skips an empty root module without skipping its nested modules'
    When run quality_gate empty_root
    The status should eq 0
    The output should eq ''
  End

  It 'does not repeat checks for duplicate configured module directories'
    When run quality_gate duplicate_modules
    The status should eq 0
    The output should eq ''
  End

  It 'preserves a failed module status'
    When run quality_gate module_failure
    The status should eq 7
    The stderr should include 'selected module failed'
  End

  It 'preserves interrupt status across module iteration'
    When run quality_gate module_interrupt
    The status should eq 130
    The stderr should include 'exit=130'
  End

  It 'rejects missing configured modules'
    When run quality_gate missing_module
    The status should eq 2
    The stderr should include 'Go module manifest missing'
  End

  It 'rejects module traversal outside the selected repository'
    When run quality_gate traversal
    The status should eq 2
    The stderr should include 'invalid Go module directory'
  End

  It 'selects short tests from project configuration without leaking hook policy'
    When run quality_gate short
    The status should eq 0
    The output should eq ''
  End

  It 'rejects an invalid short-test setting'
    When run quality_gate invalid_short
    The status should eq 2
    The stderr should include 'GIT_HOOK_GO_TEST_SHORT must be 0 or 1'
  End

  It 'retains complete diagnostics beyond the console limit'
    When run quality_gate long_output
    The status should eq 0
    The output should eq ''
  End
End
