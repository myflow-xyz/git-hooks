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
  cat >"$gate_tmp/bin/goimports" <<'EOF'
#!/usr/bin/env sh
printf 'format\n' >>"$GATE_LOG"
grep -q 'value = 1' || printf 'needs formatting\n'
exit 0
EOF
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
  cat >"$gate_tmp/bin/golangci-lint" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$PWD" >>"$GATE_LOG"
[ "$PWD" != "$GATE_REPO" ] || exit 81
grep -q 'value = 1' main.go || exit 82
[ ! -e untracked.go ] || exit 83
for arg do
  case "$arg" in
    --new-from-patch=*) patch=${arg#*=} ;;
  esac
done
grep -q '^+++ b/main.go' "$patch" || exit 84
[ "$GATE_MODE" != fail ] || exit 7
[ "$GATE_MODE" != interrupt ] || exit 130
EOF
  chmod +x "$gate_tmp/bin/go" "$gate_tmp/bin/goimports" "$gate_tmp/bin/golangci-lint"
  case "$gate_case" in
  staged_good)
    printf 'package gate\nvar value = 2\n' >main.go
    sh "$gate_root/lib/checks/golang/goimports.sh"
    ;;
  staged_bad)
    printf 'package gate\nvar value = 2\n' >main.go
    git add main.go
    printf 'package gate\nvar value = 1\n' >main.go
    sh "$gate_root/lib/checks/golang/goimports.sh"
    ;;
  alternate_index)
    cp .git/index "$gate_tmp/alternate-index"
    export GIT_INDEX_FILE="$gate_tmp/alternate-index"
    printf 'package gate\nvar value = 2\n' >main.go
    git add main.go
    printf 'package gate\nvar value = 1\n' >main.go
    sh "$gate_root/lib/checks/golang/goimports.sh"
    ;;
  unusual_paths)
    for gate_path in 'white space.go' 'back\slash.go' '-leading.go' '[glob].go' 'café.go' "$(printf 'tab\tname.go')" "$(printf 'line\nname.go')"; do
      printf 'package gate\nvar value = 1\n' >"$gate_path"
      git add -- "$gate_path"
      printf 'package gate\nvar value = 2\n' >"$gate_path"
    done
    rm main.go
    sh "$gate_root/lib/checks/golang/goimports.sh"
    ;;
  discovery_error)
    export GIT_INDEX_FILE="$gate_tmp/invalid-index"
    printf broken >"$GIT_INDEX_FILE"
    sh "$gate_root/lib/checks/golang/goimports.sh"
    ;;
  renamed | copied | deleted | no_go)
    git -c user.name=Test -c user.email=test@example.com commit -qm baseline
    case "$gate_case" in
    renamed) git mv main.go 'renamed file.go' ;;
    copied)
      cp main.go copy.go
      git add copy.go
      ;;
    deleted) git rm -q main.go ;;
    no_go)
      printf 'notes\n' >notes.txt
      git add notes.txt
      ;;
    esac
    sh "$gate_root/lib/checks/golang/goimports.sh" || exit $?
    case "$gate_case" in
    renamed | copied) [ "$(wc -l <"$GATE_LOG" | tr -d ' ')" = 1 ] ;;
    deleted | no_go) [ ! -f "$GATE_LOG" ] ;;
    esac
    ;;
  fast_snapshot | fast_failure | fast_interrupt)
    printf 'package gate\nvar value = 2\n' >main.go
    printf 'package gate\ninvalid source\n' >untracked.go
    [ "$gate_case" != fast_failure ] || export GATE_MODE=fail
    [ "$gate_case" != fast_interrupt ] || export GATE_MODE=interrupt
    sh "$gate_root/lib/checks/golang/golangci-lint-fast.sh" 2>"$gate_tmp/errors"
    gate_status=$?
    IFS= read -r gate_snapshot <"$GATE_LOG" || exit 85
    [ ! -d "$gate_snapshot" ] || exit 86
    grep -q 'value = 2' main.go || exit 87
    git show :main.go | grep -q 'value = 1' || exit 88
    cat "$gate_tmp/errors" >&2
    exit "$gate_status"
    ;;
  fast_modules)
    mkdir -p 'service one' other
    cp go.mod 'service one/go.mod'
    cp main.go 'service one/main.go'
    cp go.mod other/go.mod
    cp main.go other/main.go
    git add .
    git -c user.name=Test -c user.email=test@example.com commit -qm baseline
    printf 'package gate\nvar value = 1\n// staged\n' >'service one/main.go'
    git add 'service one/main.go'
    printf 'package gate\nvar value = 2\n' >'service one/main.go'
    sh "$gate_root/lib/checks/golang/golangci-lint-fast.sh" || exit $?
    [ "$(wc -l <"$GATE_LOG" | tr -d ' ')" = 1 ] || exit 89
    grep -q '/service one$' "$GATE_LOG"
    ;;
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
    grep -q '/service one|test -count=1 ./...' "$GATE_LOG" || exit 91
    if grep -Eq '/(vendor|testdata)/' "$GATE_LOG"; then exit 92; fi
    ;;
  short | race | race_failure | invalid_short)
    gate_check=go-test
    case "$gate_case" in
    short) printf 'GIT_HOOK_GO_TEST_SHORT=1\n' >.githooks/project.conf ;;
    race)
      gate_check=go-test-race
      printf 'GIT_HOOK_GO_TEST_SHORT=1\n' >.githooks/project.conf
      ;;
    race_failure)
      gate_check=go-test-race
      export GATE_MODE=fail
      ;;
    invalid_short) printf 'GIT_HOOK_GO_TEST_SHORT=typo\n' >.githooks/project.conf ;;
    esac
    sh "$gate_root/lib/checks/golang/$gate_check.sh" || exit $?
    case "$gate_case" in
    short) grep -q '|test -short -count=1 ./...' "$GATE_LOG" ;;
    race) grep -q '|test -race -short -count=1 ./...' "$GATE_LOG" ;;
    esac
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
