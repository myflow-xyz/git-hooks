Describe 'lib/checks/common/osv-scanner.sh'
  It 'skips with install guidance when osv-scanner is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX")
      trap '\''rm -rf "$tmpdir"'\'' EXIT HUP INT TERM
      export GIT_HOOKS_HOME="$ROOT"
      export PATH=/usr/bin:/bin
      cd "$tmpdir"
      git init -q
      sh "$ROOT/lib/checks/common/osv-scanner.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should include 'warn: skip osv-scanner: missing or not executable'
    The stderr should include 'go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest'
    The stderr should include 'https://github.com/google/osv-scanner'
  End

  It 'skips with install guidance when osv-scanner is not executable'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX")
      trap '\''rm -rf "$tmpdir"'\'' EXIT HUP INT TERM
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$tmpdir/bin" "$tmpdir/repo"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/bin/osv-scanner"
      chmod 644 "$tmpdir/bin/osv-scanner"
      export PATH="$tmpdir/bin:/usr/bin:/bin"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/checks/common/osv-scanner.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should include 'warn: skip osv-scanner: missing or not executable'
    The stderr should include 'go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest'
    The stderr should include 'https://github.com/google/osv-scanner'
  End

  It 'runs a recursive source scan from the repository root with Markdown output'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX")
      trap '\''rm -rf "$tmpdir"'\'' EXIT HUP INT TERM
      export GIT_HOOKS_HOME="$ROOT"
      export OSV_SCANNER_LOG="$tmpdir/osv-scanner-log"
      mkdir -p "$tmpdir/bin" "$tmpdir/repo/nested"
      cat > "$tmpdir/bin/osv-scanner" <<'\''EOF'\''
#!/usr/bin/env sh
printf "pwd=%s\n" "${PWD##*/}" > "$OSV_SCANNER_LOG"
printf "args=%s\n" "$*" >> "$OSV_SCANNER_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/osv-scanner"
      export PATH="$tmpdir/bin:/usr/bin:/bin"
      cd "$tmpdir/repo"
      git init -q
      cd nested
      sh "$ROOT/lib/checks/common/osv-scanner.sh"
      cat "$OSV_SCANNER_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'pwd=repo'
    The stdout should include 'args=scan source --format markdown --verbosity error --recursive .'
    The stderr should eq ''
  End

  It 'keeps clean success silent'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX")
      trap '\''rm -rf "$tmpdir"'\'' EXIT HUP INT TERM
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$tmpdir/bin" "$tmpdir/repo"
      cat > "$tmpdir/bin/osv-scanner" <<'\''EOF'\''
#!/usr/bin/env sh
printf "%s\n" "osv-scanner noisy success stdout"
printf "%s\n" "osv-scanner noisy success stderr" >&2
exit 0
EOF
      chmod +x "$tmpdir/bin/osv-scanner"
      export PATH="$tmpdir/bin:/usr/bin:/bin"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/checks/common/osv-scanner.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
    The stderr should eq ''
  End

  It 'streams native output when verbose mode is enabled'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX")
      trap '\''rm -rf "$tmpdir"'\'' EXIT HUP INT TERM
      export GIT_HOOKS_HOME="$ROOT"
      export GIT_HOOK_VERBOSE=1
      mkdir -p "$tmpdir/bin" "$tmpdir/repo"
      cat > "$tmpdir/bin/osv-scanner" <<'\''EOF'\''
#!/usr/bin/env sh
printf "%s\n" "$*"
printf "%s\n" "| OSV URL | Package |"
exit 0
EOF
      chmod +x "$tmpdir/bin/osv-scanner"
      export PATH="$tmpdir/bin:/usr/bin:/bin"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/checks/common/osv-scanner.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'git-hooks: osv-scanner scan source --format markdown --verbosity error --recursive .'
    The stdout should include 'scan source --format markdown --verbosity error --recursive .'
    The stdout should include '| OSV URL | Package |'
    The stderr should eq ''
  End

  It 'prints Markdown results and returns exit 1 when vulnerabilities are found'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX")
      trap '\''rm -rf "$tmpdir"'\'' EXIT HUP INT TERM
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$tmpdir/bin" "$tmpdir/repo"
      cat > "$tmpdir/bin/osv-scanner" <<'\''EOF'\''
#!/usr/bin/env sh
printf "%s\n" "Total 1 package affected by 1 known vulnerability."
printf "%s\n" "| OSV URL | Package | Version |"
printf "%s\n" "| --- | --- | --- |"
printf "%s\n" "| https://osv.dev/GHSA-test | example | 1.0.0 |"
exit 1
EOF
      chmod +x "$tmpdir/bin/osv-scanner"
      export PATH="$tmpdir/bin:/usr/bin:/bin"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/checks/common/osv-scanner.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stdout should eq ''
    The stderr should include 'git-hooks: error: osv-scanner found vulnerabilities; exit=1'
    The stderr should include '| OSV URL | Package | Version |'
    The stderr should include '| https://osv.dev/GHSA-test | example | 1.0.0 |'
  End

  It 'reports operational failures and preserves the scanner status'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-osv-scanner.XXXXXX")
      trap '\''rm -rf "$tmpdir"'\'' EXIT HUP INT TERM
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$tmpdir/bin" "$tmpdir/repo"
      cat > "$tmpdir/bin/osv-scanner" <<'\''EOF'\''
#!/usr/bin/env sh
printf "%s\n" "no packages found" >&2
exit 128
EOF
      chmod +x "$tmpdir/bin/osv-scanner"
      export PATH="$tmpdir/bin:/usr/bin:/bin"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/checks/common/osv-scanner.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 128
    The stdout should eq ''
    The stderr should include 'git-hooks: error: osv-scanner failed; exit=128'
    The stderr should include 'no packages found'
  End
End
