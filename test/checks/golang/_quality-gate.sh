#!/usr/bin/env sh

quality_gate() (
  gate_root=$SHELLSPEC_PROJECT_ROOT
  gate_case=$1
  gate_tmp=$(mktemp -d "${TMPDIR:-/tmp}/git-hooks-quality.XXXXXX") || exit 2
  trap 'rm -rf "$gate_tmp"' EXIT HUP INT TERM
  export GIT_HOOKS_HOME="$gate_root"
  export GIT_HOOKS_COMMON_DIR="$gate_root/lib/common"
  . "$GIT_HOOKS_COMMON_DIR/env.sh"
  git_hooks_env_unset_git_local_vars
  unset GIT_HOOK_GO_MODULES GIT_HOOK_GO_TEST_SHORT GIT_HOOK_REPO_ROOT GIT_HOOKS_GOLANG_DIR
  export GIT_HOOK_VERBOSE=0
  export TMPDIR="$gate_tmp/tmp" GOCACHE="$gate_tmp/cache" GOTMPDIR="$gate_tmp/go-tmp"
  export GOLANGCI_LINT_CACHE="$gate_tmp/lint-cache"
  export GATE_LOG="$gate_tmp/tool.log" GATE_REPO="$gate_tmp/repo" GATE_MODE=success
  mkdir -p "$TMPDIR" "$gate_tmp/bin" "$GATE_REPO/.githooks"
  export PATH="$gate_tmp/bin:$PATH"
  cd "$GATE_REPO" || exit 2
  GATE_REPO=$(pwd -P)
  export GATE_REPO
  git init -q
  git config core.hooksPath /dev/null
  printf 'module example.com/gate\n\ngo 1.23\n' >go.mod
  printf 'package gate\nvar value = 1\n' >main.go
  git add go.mod main.go
  cat >"$gate_tmp/bin/go" <<'EOF'
#!/usr/bin/env sh
[ "$1" != env ] || exit 0
[ -z "${GIT_HOOK_GO_CHECK+x}" ] || exit 91
[ -z "${GIT_HOOK_GO_TEST_SHORT+x}" ] || exit 92
[ -z "${GIT_HOOK_GO_MODULES+x}" ] || exit 93
printf '%s|%s\n' "$PWD" "$*" >>"$GATE_LOG"
case "$GATE_MODE" in
  fail) printf 'selected module failed\n' >&2; exit 7 ;;
  interrupt) exit 130 ;;
  long) i=0; while [ "$i" -lt 150 ]; do printf 'diagnostic %s\n' "$i"; i=$((i + 1)); done; printf 'FINAL ASSERTION\n'; exit 6 ;;
esac
EOF
  chmod +x "$gate_tmp/bin/go"
  case "$gate_case" in
  modules | explicit_modules | workspace | empty_root | duplicate_modules | module_failure | module_interrupt | missing_module | traversal)
    for gate_dir in 'service one' other vendor/dep testdata/fixture; do
      mkdir -p "$gate_dir"
      cp go.mod "$gate_dir/go.mod"
      cp main.go "$gate_dir/main.go"
    done
    case "$gate_case" in
    explicit_modules)
      printf 'GIT_HOOK_GO_MODULES="service one"\n' >.githooks/project.conf
      ;;
    duplicate_modules)
      printf 'GIT_HOOK_GO_MODULES="service one\n./service one"\n' >.githooks/project.conf
      ;;
    empty_root) git rm -qf main.go ;;
    workspace)
      git rm -qf go.mod main.go
      printf 'go 1.23\nuse (\n "./service one"\n ./other\n)\n' >go.work
      ;;
    module_failure) export GATE_MODE=fail ;;
    module_interrupt) export GATE_MODE=interrupt ;;
    missing_module) printf 'GIT_HOOK_GO_MODULES=missing\n' >.githooks/project.conf ;;
    traversal) printf 'GIT_HOOK_GO_MODULES=../repo\n' >.githooks/project.conf ;;
    esac
    sh "$gate_root/lib/checks/golang/go-test.sh" 2>"$gate_tmp/errors"
    gate_status=$?
    cat "$gate_tmp/errors" >&2
    if [ "$gate_status" -ne 0 ]; then
      case "$gate_case" in
      module_failure | module_interrupt)
        [ "$(wc -l <"$GATE_LOG" | tr -d ' ')" = 1 ] || exit 97
        ;;
      esac
      exit "$gate_status"
    fi
    case "$gate_case" in
    modules) gate_expected=3 ;;
    workspace | empty_root) gate_expected=2 ;;
    explicit_modules | duplicate_modules) gate_expected=1 ;;
    esac
    [ "$(wc -l <"$GATE_LOG" | tr -d ' ')" = "$gate_expected" ] || exit 90
    grep -q '/service one|test ./...' "$GATE_LOG" || exit 91
    if grep -Eq '/(vendor|testdata)/' "$GATE_LOG"; then exit 92; fi
    ;;
  short | invalid_short)
    if [ "$gate_case" = short ]; then
      printf 'GIT_HOOK_GO_TEST_SHORT=1\n' >.githooks/project.conf
    else
      printf 'GIT_HOOK_GO_TEST_SHORT=typo\n' >.githooks/project.conf
    fi
    sh "$gate_root/lib/checks/golang/go-test.sh" || exit $?
    grep -q '|test -short ./...' "$GATE_LOG"
    ;;
  long_output)
    export GATE_MODE=long
    sh "$gate_root/lib/checks/golang/go-test.sh" 2>"$gate_tmp/errors"
    [ "$?" -eq 6 ] || exit 94
    gate_log=$(sed -n 's/^.*complete failure log: //p' "$gate_tmp/errors")
    grep -q 'FINAL ASSERTION' "$gate_log" || exit 95
    if grep -q 'FINAL ASSERTION' "$gate_tmp/errors"; then exit 96; fi
    ;;
  esac
)
