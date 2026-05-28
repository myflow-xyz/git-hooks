Describe 'lib/dispatcher/run-hook.sh'
  It 'runs profile checks through the dispatcher'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf dispatched" > "$GIT_HOOKS_HOME/lib/checks/test/ok.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/ok.sh"
      printf "%s\n" "test/ok" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'dispatched'
  End

  It 'reports unresolved check IDs with the expected script path'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      printf "%s\n" "test/missing" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'check is not executable:'
    The stderr should include '/lib/checks/test/missing.sh'
  End

  It 'passes git hook arguments to checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"arg:%s\" \"\$1\"" > "$GIT_HOOKS_HOME/lib/checks/test/arg.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/arg.sh"
      printf "%s\n" "test/arg" > "$GIT_HOOKS_HOME/profiles/test/commit-msg.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" commit-msg "$tmpdir/COMMIT_EDITMSG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'arg:'
    The stdout should include 'COMMIT_EDITMSG'
  End

  It 'uses the default common profile when project config is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/common" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf default-common" > "$GIT_HOOKS_HOME/lib/checks/test/default.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/default.sh"
      printf "%s\n" "test/default" > "$GIT_HOOKS_HOME/profiles/common/pre-commit.list"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'default-common'
  End

  It 'ignores blank and comment lines in profile lists'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf ok" > "$GIT_HOOKS_HOME/lib/checks/test/ok.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/ok.sh"
      printf "%s\n" "" "  # comment with leading whitespace" "  test/ok  " > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'ok'
  End

  It 'runs multiple profiles in declared order'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/one" "$GIT_HOOKS_HOME/profiles/two" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf one" > "$GIT_HOOKS_HOME/lib/checks/test/one.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf two" > "$GIT_HOOKS_HOME/lib/checks/test/two.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/one.sh" "$GIT_HOOKS_HOME/lib/checks/test/two.sh"
      printf "%s\n" "test/one" > "$GIT_HOOKS_HOME/profiles/one/pre-commit.list"
      printf "%s\n" "test/two" > "$GIT_HOOKS_HOME/profiles/two/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=\"one two\"" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'onetwo'
  End

  It 'skips duplicate profiles with a warning'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/one" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf one" > "$GIT_HOOKS_HOME/lib/checks/test/one.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/one.sh"
      printf "%s\n" "test/one" > "$GIT_HOOKS_HOME/profiles/one/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=\"one one\"" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'one'
    The stderr should include 'pre-commit: warn: skip duplicate profile: one'
  End

  It 'rejects unknown profiles from project config'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/common" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      printf "%s\n" "GIT_HOOK_PROFILES=\"common golagn\"" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'pre-commit: error: unknown profile: golagn'
  End

  It 'runs react-vite pre-commit profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/repo/.githooks" "$tmpdir/repo/src" "$tmpdir/repo/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "\$*" >> "$tmpdir/pnpm-log"
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/repo/node_modules/.bin/oxfmt"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/repo/node_modules/.bin/oxlint"
      chmod +x "$tmpdir/repo/node_modules/.bin/oxfmt" "$tmpdir/repo/node_modules/.bin/oxlint"
      export PATH="$tmpdir/bin:$PATH"
      printf "%s\n" "GIT_HOOK_PROFILES=react-vite" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      printf "{}\n" > package.json
      printf "console.log(1)\n" > src/main.ts
      git add package.json src/main.ts
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
      cat "$tmpdir/pnpm-log"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'exec oxfmt --check src'
    The stdout should include 'exec oxlint --type-aware --report-unused-disable-directives --max-warnings 0'
  End

  It 'runs react-vite pre-push profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export PNPM_LOG="$tmpdir/pnpm-log"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/repo/.githooks" "$tmpdir/repo/node_modules/.bin"
      cat > "$tmpdir/bin/pnpm" <<EOF
#!/usr/bin/env sh
printf "%s\n" "\$*" >> "$PNPM_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/pnpm"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/repo/node_modules/.bin/vitest"
      printf "%s\n" "#!/usr/bin/env sh" "exit 0" > "$tmpdir/repo/node_modules/.bin/playwright"
      chmod +x "$tmpdir/repo/node_modules/.bin/vitest" "$tmpdir/repo/node_modules/.bin/playwright"
      export PATH="$tmpdir/bin:$PATH"
      printf "%s\n" "GIT_HOOK_PROFILES=react-vite" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      printf "{}\n" > package.json
      printf "export default {}\n" > playwright.config.ts
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-push
      cat "$PNPM_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'exec vitest run'
    The stdout should include 'exec playwright test --pass-with-no-tests'
  End

  It 'runs golang pre-commit profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export GOIMPORTS_LOG="$tmpdir/goimports-log"
      export GOLANGCI_LOG="$tmpdir/golangci-log"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/repo/.githooks"
      cat > "$tmpdir/bin/goimports" <<EOF
#!/usr/bin/env sh
printf "%s\n" "\$*" >> "$GOIMPORTS_LOG"
exit 0
EOF
      cat > "$tmpdir/bin/golangci-lint" <<EOF
#!/usr/bin/env sh
printf "%s\n" "\$*" >> "$GOLANGCI_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/goimports" "$tmpdir/bin/golangci-lint"
      export PATH="$tmpdir/bin:$PATH"
      printf "%s\n" "GIT_HOOK_PROFILES=golang" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      git add go.mod main.go
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
      cat "$GOIMPORTS_LOG"
      cat "$GOLANGCI_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '-l main.go'
    The stdout should include '--fast-only'
  End

  It 'runs golang pre-push profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export HOOK_LOG="$tmpdir/hook-log"
      unset GOCACHE GOTMPDIR
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/repo/.githooks"
      cat > "$tmpdir/bin/golangci-lint" <<EOF
#!/usr/bin/env sh
printf "golangci-lint:%s\n" "\$1" >> "$HOOK_LOG"
exit 0
EOF
      cat > "$tmpdir/bin/govulncheck" <<EOF
#!/usr/bin/env sh
printf "govulncheck:%s\n" "\$*" >> "$HOOK_LOG"
exit 0
EOF
      cat > "$tmpdir/bin/go" <<EOF
#!/usr/bin/env sh
printf "go:%s\n" "\$*" >> "$HOOK_LOG"
exit 0
EOF
      chmod +x "$tmpdir/bin/golangci-lint" "$tmpdir/bin/govulncheck" "$tmpdir/bin/go"
      export PATH="$tmpdir/bin:$PATH"
      printf "%s\n" "GIT_HOOK_PROFILES=golang" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      printf "module example.com/app\n" > go.mod
      printf "package main\n" > main.go
      git add go.mod main.go
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-push
      expected=$(cat <<'"'"'EOF_EXPECTED'"'"'
go:mod tidy -diff
govulncheck:./...
golangci-lint:run
go:vet ./...
go:test ./...
EOF_EXPECTED
)
      actual=$(cat "$HOOK_LOG")
      [ "$actual" = "$expected" ] || {
        cat "$HOOK_LOG"
        exit 99
      }
      cat "$HOOK_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'go:mod tidy -diff'
    The stdout should include 'govulncheck:./...'
    The stdout should include 'golangci-lint:run'
    The stdout should include 'go:vet ./...'
    The stdout should include 'go:test ./...'
  End

  It 'runs python pre-commit profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export RUFF_LOG="$tmpdir/ruff-log"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/repo/.githooks"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$RUFF_LOG\"" "exit 0" > "$tmpdir/bin/ruff"
      chmod +x "$tmpdir/bin/ruff"
      export PATH="$tmpdir/bin:$PATH"
      printf "%s\n" "GIT_HOOK_PROFILES=python" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      printf "print(1)\n" > app.py
      git add app.py
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
      cat "$RUFF_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'format --check app.py'
    The stdout should include 'check --no-cache --select I app.py'
    The stdout should include 'check --no-cache app.py'
  End

  It 'runs python pre-push profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      export MYPY_LOG="$tmpdir/mypy-log"
      export PYTEST_LOG="$tmpdir/pytest-log"
      mkdir -p "$HOME" "$tmpdir/bin" "$tmpdir/repo/.githooks" "$tmpdir/repo/tests"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$MYPY_LOG\"" "exit 0" > "$tmpdir/bin/mypy"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"%s\\n\" \"\$*\" >> \"\$PYTEST_LOG\"" "exit 0" > "$tmpdir/bin/pytest"
      chmod +x "$tmpdir/bin/mypy" "$tmpdir/bin/pytest"
      export PATH="$tmpdir/bin:$PATH"
      printf "%s\n" "GIT_HOOK_PROFILES=python" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      printf "[project]\nname = \"app\"\n" > pyproject.toml
      printf "def test_ok():\n    assert True\n" > tests/test_app.py
      git add pyproject.toml tests/test_app.py
      git commit -qm init
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-push
      cat "$MYPY_LOG"
      cat "$PYTEST_LOG"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include '.'
  End

  It 'runs pmem commit-msg profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$ROOT"
      mkdir -p "$HOME" "$tmpdir/repo/.githooks" "$tmpdir/repo/.pmem"
      printf "%s\n" "GIT_HOOK_PROFILES=pmem" > "$tmpdir/repo/.githooks/project.conf"
      printf "%s\n" "PMEM_PROJECT_KEY=APP" > "$tmpdir/repo/.pmem/env"
      printf "%s\n\n%s\n" "feat(pmem): add footer" "Ref: SPEC-123" > "$tmpdir/repo/COMMIT_EDITMSG"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" commit-msg COMMIT_EDITMSG
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'runs phase-specific extra checks after profile checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf profile" > "$GIT_HOOKS_HOME/lib/checks/test/profile.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf extra" > "$GIT_HOOKS_HOME/lib/checks/test/extra.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/profile.sh" "$GIT_HOOKS_HOME/lib/checks/test/extra.sh"
      printf "%s\n" "test/profile" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" "GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS=\"test/extra\"" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'profileextra'
  End

  It 'runs direct local extra hooks after builtin extra checks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks/hooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf profile" > "$GIT_HOOKS_HOME/lib/checks/test/profile.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf builtin" > "$GIT_HOOKS_HOME/lib/checks/test/builtin.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf local > \"$tmpdir/local-log\"" > "$tmpdir/repo/.githooks/hooks/yhook.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/profile.sh" "$GIT_HOOKS_HOME/lib/checks/test/builtin.sh"
      chmod +x "$tmpdir/repo/.githooks/hooks/yhook.sh"
      printf "%s\n" "test/profile" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" \
        "GIT_HOOK_PROFILES=test" \
        "GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS=\"test/builtin\"" \
        "GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS=\"yhook\"" \
        > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
      cat "$tmpdir/local-log"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'profilebuiltinlocal'
  End

  It 'runs nested local extra hooks with git hook arguments'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks/hooks/dir"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      printf "%s\n" "#!/usr/bin/env sh" "printf \"nested:%s\" \"\$1\" > \"$tmpdir/nested-log\"" > "$tmpdir/repo/.githooks/hooks/dir/xhook.sh"
      chmod +x "$tmpdir/repo/.githooks/hooks/dir/xhook.sh"
      printf "%s\n" \
        "GIT_HOOK_PROFILES=test" \
        "GIT_HOOK_COMMIT_MSG_EXTRA_LOCAL_HOOKS=\"dir/xhook\"" \
        > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" commit-msg COMMIT_EDITMSG
      cat "$tmpdir/nested-log"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'nested:COMMIT_EDITMSG'
  End

  It 'warns and skips missing local extra hooks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks/hooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf builtin" > "$GIT_HOOKS_HOME/lib/checks/test/builtin.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf later > \"$tmpdir/later-log\"" > "$tmpdir/repo/.githooks/hooks/later.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/builtin.sh" "$tmpdir/repo/.githooks/hooks/later.sh"
      printf "%s\n" \
        "GIT_HOOK_PROFILES=test" \
        "GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS=\"test/builtin\"" \
        "GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS=\"missing later\"" \
        > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
      cat "$tmpdir/later-log"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq 'builtinlater'
    The stderr should include 'pre-commit: warn: missing local hook:'
    The stderr should include '/.githooks/hooks/missing.sh'
    The stderr should not include 'later'
  End

  It 'fails when local extra hooks are not executable'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks/hooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      printf "%s\n" "#!/usr/bin/env sh" "printf no" > "$tmpdir/repo/.githooks/hooks/noexec.sh"
      printf "%s\n" \
        "GIT_HOOK_PROFILES=test" \
        "GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS=\"noexec\"" \
        > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'pre-commit: error: local hook is not executable:'
    The stderr should include '/.githooks/hooks/noexec.sh'
  End

  It 'fails when local extra hook paths are not regular files'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks/hooks/notfile.sh"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      printf "%s\n" \
        "GIT_HOOK_PROFILES=test" \
        "GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS=\"notfile\"" \
        > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'pre-commit: error: local hook is not a regular file:'
    The stderr should include '/.githooks/hooks/notfile.sh'
    The stderr should not include 'missing local hook'
  End

  It 'replays failed local hook output and stops before later local hooks'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks/hooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      printf "%s\n" "#!/usr/bin/env sh" "printf failed-local" "exit 7" > "$tmpdir/repo/.githooks/hooks/fail.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf later" > "$tmpdir/repo/.githooks/hooks/later.sh"
      chmod +x "$tmpdir/repo/.githooks/hooks/fail.sh" "$tmpdir/repo/.githooks/hooks/later.sh"
      printf "%s\n" \
        "GIT_HOOK_PROFILES=test" \
        "GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS=\"fail later\"" \
        > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 7
    The stdout should eq ''
    The stderr should include 'failed-local'
    The stderr should include 'pre-commit: error: local hook failed; id=fail; exit=7'
    The stderr should not include 'later'
  End

  It 'stops on the first failing check'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf fail" "exit 7" > "$GIT_HOOKS_HOME/lib/checks/test/fail.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf later" > "$GIT_HOOKS_HOME/lib/checks/test/later.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/fail.sh" "$GIT_HOOKS_HOME/lib/checks/test/later.sh"
      printf "%s\n" "test/fail" "test/later" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 7
    The stdout should eq 'fail'
    The stdout should not include 'later'
  End

  It 'restores the pre-commit index snapshot when a check fails'
    When run sh -u -c '
      set -e
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$GIT_HOOKS_HOME/lib/checks/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      cat > "$GIT_HOOKS_HOME/lib/checks/test/stage-all-fail.sh" <<EOF
#!/usr/bin/env sh
git add .
exit 7
EOF
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/stage-all-fail.sh"
      printf "%s\n" "test/stage-all-fail" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      git config user.email test@example.com
      git config user.name "Test User"
      printf "%s\n" old > intended.txt
      printf "%s\n" old > other.txt
      git add intended.txt other.txt
      git commit -qm init
      printf "%s\n" changed > intended.txt
      printf "%s\n" changed > other.txt
      git add intended.txt
      git status --short > "$tmpdir/before"
      set +e
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
      hook_status=$?
      set -e
      git status --short > "$tmpdir/after"
      cmp -s "$tmpdir/before" "$tmpdir/after"
      exit "$hook_status"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 7
  End

  It 'restores the pre-commit index snapshot when a check exits with interrupt status'
    When run sh -u -c '
      set -e
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$GIT_HOOKS_HOME/lib/checks/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      cat > "$GIT_HOOKS_HOME/lib/checks/test/stage-all-interrupt.sh" <<EOF
#!/usr/bin/env sh
git add .
exit 130
EOF
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/stage-all-interrupt.sh"
      printf "%s\n" "test/stage-all-interrupt" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      git config user.email test@example.com
      git config user.name "Test User"
      printf "%s\n" old > intended.txt
      printf "%s\n" old > other.txt
      git add intended.txt other.txt
      git commit -qm init
      printf "%s\n" changed > intended.txt
      printf "%s\n" changed > other.txt
      git add intended.txt
      git status --short > "$tmpdir/before"
      set +e
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
      hook_status=$?
      set -e
      git status --short > "$tmpdir/after"
      cmp -s "$tmpdir/before" "$tmpdir/after"
      exit "$hook_status"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 130
  End

  It 'stops immediately when a check exits with interrupt status'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf interrupted" "exit 130" > "$GIT_HOOKS_HOME/lib/checks/test/interrupt.sh"
      printf "%s\n" "#!/usr/bin/env sh" "printf later" > "$GIT_HOOKS_HOME/lib/checks/test/later.sh"
      chmod +x "$GIT_HOOKS_HOME/lib/checks/test/interrupt.sh" "$GIT_HOOKS_HOME/lib/checks/test/later.sh"
      printf "%s\n" "test/interrupt" "test/later" > "$GIT_HOOKS_HOME/profiles/test/pre-push.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-push
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 130
    The stdout should eq 'interrupted'
    The stdout should not include 'later'
  End

  It 'passes when the selected phase list is missing'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-push
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should eq ''
  End

  It 'fails when a check exists but is not executable'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-dispatcher.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      export GIT_HOOKS_HOME="$tmpdir/hooks"
      mkdir -p "$HOME" "$GIT_HOOKS_HOME/lib" "$GIT_HOOKS_HOME/profiles/test" "$tmpdir/repo/.githooks"
      cp -R "$ROOT/lib/common" "$GIT_HOOKS_HOME/lib/common"
      mkdir -p "$GIT_HOOKS_HOME/lib/checks/test"
      printf "%s\n" "#!/usr/bin/env sh" "printf no" > "$GIT_HOOKS_HOME/lib/checks/test/not-executable.sh"
      printf "%s\n" "test/not-executable" > "$GIT_HOOKS_HOME/profiles/test/pre-commit.list"
      printf "%s\n" "GIT_HOOK_PROFILES=test" > "$tmpdir/repo/.githooks/project.conf"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/lib/dispatcher/run-hook.sh" pre-commit
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'check is not executable:'
    The stderr should include 'not-executable.sh'
  End

  It 'rejects unknown phases'
    When run sh -u -c '
      ROOT=$1
      sh "$ROOT/lib/dispatcher/run-hook.sh" nope
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'Usage: run-hook.sh'
  End
End
