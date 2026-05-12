Describe 'setup-config.sh'
  It 'copies bundled markdownlint config into the repo root'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-config.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-config.sh" common/md-lint
      cmp -s "$ROOT/config/markdownlint/markdownlint.yaml" .markdownlint-cli2.yaml
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'copied; check-id=common/md-lint; path=.markdownlint-cli2.yaml'
    The stderr should include 'warn: repo-local config now overrides bundled defaults'
  End

  It 'copies bundled golangci-lint config using --repo outside the target repo'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-config.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo" "$tmpdir/outside"
      cd "$tmpdir/repo"
      git init -q
      cd "$tmpdir/outside"
      sh "$ROOT/setup-config.sh" --repo "$tmpdir/repo" golang/golangci-lint
      cmp -s "$ROOT/config/golangci-lint/config.yaml" "$tmpdir/repo/.golangci.yaml"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'copied; check-id=golang/golangci-lint; path=.golangci.yaml'
    The stderr should include 'warn: repo-local config now overrides bundled defaults'
  End

  It 'refuses to overwrite an existing config without --force'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-config.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "local" > .markdownlint-cli2.yaml
      status=0
      sh "$ROOT/setup-config.sh" common/md-lint || status=$?
      grep -Fx "local" .markdownlint-cli2.yaml >/dev/null
      exit "$status"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'error: config already exists: .markdownlint-cli2.yaml'
    The stderr should include 'info: pass --force to replace it'
  End

  It 'replaces an existing config with --force'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-config.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      printf "%s\n" "local" > .markdownlint-cli2.yaml
      sh "$ROOT/setup-config.sh" --force common/md-lint
      cmp -s "$ROOT/config/markdownlint/markdownlint.yaml" .markdownlint-cli2.yaml
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
    The stdout should include 'copied; check-id=common/md-lint; path=.markdownlint-cli2.yaml'
    The stderr should include 'warn: repo-local config now overrides bundled defaults'
  End

  It 'rejects unsupported check IDs and lists allowed IDs'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-config.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/repo"
      cd "$tmpdir/repo"
      git init -q
      sh "$ROOT/setup-config.sh" golang/golangci-lint-fast
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'error: unsupported check ID: golang/golangci-lint-fast'
    The stderr should include 'info: allowed check IDs: common/md-lint golang/golangci-lint'
  End

  It 'rejects a missing check ID and lists allowed IDs'
    When run sh -u -c '
      ROOT=$1
      sh "$ROOT/setup-config.sh"
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 2
    The stderr should include 'error: check ID is required'
    The stderr should include 'info: allowed check IDs: common/md-lint golang/golangci-lint'
  End

  It 'rejects use outside a git repo'
    When run sh -u -c '
      ROOT=$1
      tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-config.XXXXXX")
      trap '"'"'rm -rf "$tmpdir"'"'"' EXIT HUP INT TERM
      export HOME="$tmpdir/home"
      mkdir -p "$HOME" "$tmpdir/not-repo"
      cd "$tmpdir/not-repo"
      sh "$ROOT/setup-config.sh" common/md-lint
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 1
    The stderr should include 'error: not inside a git repository; pass --repo <path>'
  End

  It 'shows usage and allowed check IDs in help output'
    When run sh "$SHELLSPEC_PROJECT_ROOT/setup-config.sh" --help
    The status should eq 0
    The stdout should include 'Usage: setup-config.sh [--repo <path>] [--force] <check-id>'
    The stdout should include 'Allowed check IDs:'
    The stdout should include 'common/md-lint'
    The stdout should include 'golang/golangci-lint'
  End
End
