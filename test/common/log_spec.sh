Describe 'lib/common/log.sh'
  It 'keeps info output silent by default'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/log.sh"
      git_hooks_log_info "hello"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End

  It 'prints info output when verbose'
    When run sh -u -c '
      ROOT=$1
      export GIT_HOOK_VERBOSE=1
      . "$ROOT/lib/common/log.sh"
      git_hooks_log_info "hello"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'git-hooks: hello'
  End

  It 'parses verbose env values robustly'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/log.sh"

      for verbose_value in 1 true TRUE True
      do
        GIT_HOOK_VERBOSE=$verbose_value
        export GIT_HOOK_VERBOSE
        git_hooks_log_is_verbose || exit 1
      done

      for quiet_value in 0 false FALSE False ""
      do
        GIT_HOOK_VERBOSE=$quiet_value
        export GIT_HOOK_VERBOSE
        git_hooks_log_is_verbose && exit 1
      done

      unset GIT_HOOK_VERBOSE
      git_hooks_log_is_verbose && exit 1
      exit 0
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'prints skipped missing-tool warnings to stderr'
    When run sh -u -c '
      ROOT=$1
      . "$ROOT/lib/common/log.sh"
      git_hooks_log_skip_missing_tool "check" "tool" "install tool"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stderr should include 'warn: skip check; missing tool: tool; install: install tool'
  End
End
