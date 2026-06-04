#!/usr/bin/env sh

set -u

GIT_HOOKS_COMMON_DIR=${GIT_HOOKS_COMMON_DIR:-$(CDPATH='' cd -- "$(dirname "$0")/../../common" && pwd)}
# shellcheck source=lib/common/env.sh
. "$GIT_HOOKS_COMMON_DIR/env.sh" || exit $?

git_hooks_pmem_ref_footer_usage() {
  printf '%s\n' 'Usage: ref-footer.sh <commit-message-file>'
}

git_hooks_pmem_ref_footer_info() {
  printf '%s: info: %s\n' "$(git_hooks_log_prefix)" "$*" >&2
}

git_hooks_pmem_ref_footer_expected_footer() {
  printf '%s\n' 'Ref: <task-id>; 3 <= id length < 24'
}

git_hooks_pmem_ref_footer_bin() {
  if [ -n "${GIT_HOOK_PMEM_BIN:-}" ]; then
    case "$GIT_HOOK_PMEM_BIN" in
    */*)
      if [ -x "$GIT_HOOK_PMEM_BIN" ]; then
        printf '%s\n' "$GIT_HOOK_PMEM_BIN"
        return 0
      fi
      ;;
    *)
      command -v "$GIT_HOOK_PMEM_BIN" 2>/dev/null && return 0
      ;;
    esac

    return 1
  fi

  command -v pmem 2>/dev/null
}

git_hooks_pmem_ref_footer_run_cli() {
  if [ "$#" -lt 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_pmem_ref_footer_run_cli <command> [args...]'
    return 2
  fi

  (
    unset PMEM_PROJECT_ID
    unset PMEM_PROJECT_KEY
    git_hooks_env_run_project_command "$@"
  )
}

git_hooks_pmem_ref_footer_json_path() {
  case "$1" in
  ok)
    printf '%s\n' .ok
    ;;
  project_id)
    printf '%s\n' .data.project_id
    ;;
  project_exists)
    printf '%s\n' .data.project_exists
    ;;
  status)
    printf '%s\n' .data.status
    ;;
  *)
    return 1
    ;;
  esac
}

git_hooks_pmem_ref_footer_json_validate() {
  if ! command -v jq >/dev/null 2>&1; then
    git_hooks_log_error 'required command not found: jq'
    return 127
  fi

  printf '%s\n' "$1" | command jq -e . >/dev/null 2>&1
}

git_hooks_pmem_ref_footer_json_bool() {
  if [ "$#" -ne 2 ]; then
    git_hooks_log_error 'Usage: git_hooks_pmem_ref_footer_json_bool <json> <field>'
    return 2
  fi

  git_hooks_pmem_ref_footer_path=$(git_hooks_pmem_ref_footer_json_path "$2") || return 2

  if ! command -v jq >/dev/null 2>&1; then
    git_hooks_log_error 'required command not found: jq'
    return 127
  fi

  printf '%s\n' "$1" |
    command jq -r "if ($git_hooks_pmem_ref_footer_path == null) then halt_error(1) elif ($git_hooks_pmem_ref_footer_path | type) == \"boolean\" then (if $git_hooks_pmem_ref_footer_path then \"true\" else \"false\" end) else halt_error(2) end" 2>/dev/null
}

git_hooks_pmem_ref_footer_json_string() {
  if [ "$#" -ne 2 ]; then
    git_hooks_log_error 'Usage: git_hooks_pmem_ref_footer_json_string <json> <field>'
    return 2
  fi

  git_hooks_pmem_ref_footer_path=$(git_hooks_pmem_ref_footer_json_path "$2") || return 2

  if ! command -v jq >/dev/null 2>&1; then
    git_hooks_log_error 'required command not found: jq'
    return 127
  fi

  printf '%s\n' "$1" |
    command jq -r "if ($git_hooks_pmem_ref_footer_path == null) then halt_error(1) elif ($git_hooks_pmem_ref_footer_path | type) == \"string\" then $git_hooks_pmem_ref_footer_path else halt_error(2) end" 2>/dev/null
}

git_hooks_pmem_ref_footer_envelope_ok() {
  if [ "$#" -ne 2 ]; then
    git_hooks_log_error 'Usage: git_hooks_pmem_ref_footer_envelope_ok <label> <json>'
    return 2
  fi

  git_hooks_pmem_ref_footer_json_validate "$2"
  git_hooks_pmem_ref_footer_json_validate_status=$?

  case "$git_hooks_pmem_ref_footer_json_validate_status" in
  0)
    ;;
  127)
    return 127
    ;;
  *)
    git_hooks_log_error "$1 returned malformed JSON"
    return 1
    ;;
  esac

  git_hooks_pmem_ref_footer_ok=$(git_hooks_pmem_ref_footer_json_bool "$2" ok)
  git_hooks_pmem_ref_footer_ok_status=$?

  case "$git_hooks_pmem_ref_footer_ok_status" in
  0)
    ;;
  1)
    git_hooks_log_error "$1 response missing ok field"
    return 1
    ;;
  *)
    git_hooks_log_error "$1 response has invalid ok field"
    return 1
    ;;
  esac

  if [ "$git_hooks_pmem_ref_footer_ok" != true ]; then
    git_hooks_log_error "$1 returned ok=false"
    return 1
  fi
}

git_hooks_pmem_ref_footer_task_id() {
  command awk '
    function trim(value) {
      sub(/^[[:space:]]*/, "", value)
      sub(/[[:space:]]*$/, "", value)
      return value
    }

    function valid_id(value) {
      return length(value) >= 3 && length(value) < 24 && value ~ /^[[:alnum:]][[:alnum:]_-]*$/
    }

    /^[[:space:]]*#/ { next }
    { lines[++line_count] = $0 }

    END {
      while (line_count > 0 && lines[line_count] ~ /^[[:space:]]*$/) {
        line_count--
      }

      end = line_count

      while (line_count > 0 && lines[line_count] !~ /^[[:space:]]*$/) {
        line_count--
      }

      if (line_count < 2) {
        exit 1
      }

      for (i = line_count + 1; i <= end; i++) {
        line = lines[i]

        if (line !~ /^[[:alnum:]][[:alnum:]-]*:[[:space:]]*[^[:space:]]/) {
          exit 1
        }

        if (line ~ /^Ref:[[:space:]]*/) {
          found = 1
          sub(/^Ref:[[:space:]]*/, "", line)
          line = trim(line)

          if (valid_id(line)) {
            print line
            exit 0
          }
        }
      }

      if (found) {
        exit 3
      }

      exit 1
    }
  ' "$1"
}

git_hooks_pmem_ref_footer_status_is_closed() {
  git_hooks_pmem_ref_footer_normalized_status=$(printf '%s\n' "$1" | command tr '[:upper:]' '[:lower:]')

  case "$git_hooks_pmem_ref_footer_normalized_status" in
  canceled | done | closed)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

if [ "$#" -lt 1 ]; then
  git_hooks_pmem_ref_footer_usage >&2
  exit 2
fi

git_hooks_pmem_ref_footer_file=$1

if [ ! -f "$git_hooks_pmem_ref_footer_file" ]; then
  git_hooks_log_error "commit message file not found: $git_hooks_pmem_ref_footer_file"
  exit 1
fi

git_hooks_env_bootstrap_check || exit $?

git_hooks_pmem_ref_footer_bin=$(git_hooks_pmem_ref_footer_bin) || {
  git_hooks_log_warn 'pmem check enabled but no cli client found; skip'
  exit 0
}

git_hooks_pmem_ref_footer_info_json=$(
  git_hooks_pmem_ref_footer_run_cli "$git_hooks_pmem_ref_footer_bin" info --repo --json
)
git_hooks_pmem_ref_footer_info_status=$?

if [ "$git_hooks_pmem_ref_footer_info_status" -ne 0 ]; then
  git_hooks_log_error "pmem info failed; exit=$git_hooks_pmem_ref_footer_info_status"
  exit 1
fi

git_hooks_pmem_ref_footer_envelope_ok 'pmem info' "$git_hooks_pmem_ref_footer_info_json" || exit $?

git_hooks_pmem_ref_footer_project_id=$(
  git_hooks_pmem_ref_footer_json_string "$git_hooks_pmem_ref_footer_info_json" project_id
)
git_hooks_pmem_ref_footer_project_id_status=$?

case "$git_hooks_pmem_ref_footer_project_id_status" in
0)
  ;;
1)
  git_hooks_pmem_ref_footer_project_exists=$(
    git_hooks_pmem_ref_footer_json_bool "$git_hooks_pmem_ref_footer_info_json" project_exists
  )
  git_hooks_pmem_ref_footer_project_exists_status=$?

  case "$git_hooks_pmem_ref_footer_project_exists_status" in
  0)
    ;;
  1)
    git_hooks_log_error 'pmem info response missing project_id'
    exit 1
    ;;
  127)
    exit 127
    ;;
  *)
    git_hooks_log_error 'pmem info response has invalid project_exists'
    exit 1
    ;;
  esac

  if [ "$git_hooks_pmem_ref_footer_project_exists" = true ]; then
    git_hooks_log_error 'pmem repo config missing project_id'
    exit 1
  fi

  git_hooks_log_warn 'no pmem config but pmem check hook enabled; skip'
  exit 0
  ;;
127)
  exit 127
  ;;
*)
  git_hooks_log_error 'pmem info response has invalid project_id'
  exit 1
  ;;
esac

git_hooks_log_info "pmem project_id: $git_hooks_pmem_ref_footer_project_id"

git_hooks_pmem_ref_footer_task_id=$(git_hooks_pmem_ref_footer_task_id "$git_hooks_pmem_ref_footer_file")
git_hooks_pmem_ref_footer_status=$?

case "$git_hooks_pmem_ref_footer_status" in
0)
  ;;
3)
  git_hooks_log_error 'invalid ref footer id'
  git_hooks_pmem_ref_footer_info "expected footer: $(git_hooks_pmem_ref_footer_expected_footer)"
  exit 1
  ;;
*)
  git_hooks_log_error 'missing ref footer'
  git_hooks_pmem_ref_footer_info "expected footer: $(git_hooks_pmem_ref_footer_expected_footer)"
  exit 1
  ;;
esac

git_hooks_log_info "pmem task_id: $git_hooks_pmem_ref_footer_task_id"

git_hooks_pmem_ref_footer_wi_json=$(
  git_hooks_pmem_ref_footer_run_cli \
    "$git_hooks_pmem_ref_footer_bin" wi get \
    --project-id "$git_hooks_pmem_ref_footer_project_id" \
    --id "$git_hooks_pmem_ref_footer_task_id" \
    --json
)
git_hooks_pmem_ref_footer_wi_status=$?

if [ "$git_hooks_pmem_ref_footer_wi_status" -ne 0 ]; then
  git_hooks_log_error "pmem wi get failed; id=$git_hooks_pmem_ref_footer_task_id; exit=$git_hooks_pmem_ref_footer_wi_status"
  exit 1
fi

git_hooks_pmem_ref_footer_envelope_ok 'pmem wi get' "$git_hooks_pmem_ref_footer_wi_json" || exit $?

git_hooks_pmem_ref_footer_task_status=$(
  git_hooks_pmem_ref_footer_json_string "$git_hooks_pmem_ref_footer_wi_json" status
)
git_hooks_pmem_ref_footer_task_status_status=$?

case "$git_hooks_pmem_ref_footer_task_status_status" in
0)
  ;;
1)
  git_hooks_log_error "pmem wi get response missing task status; id=$git_hooks_pmem_ref_footer_task_id"
  exit 1
  ;;
*)
  git_hooks_log_error "pmem wi get response has invalid task status; id=$git_hooks_pmem_ref_footer_task_id"
  exit 1
  ;;
esac

git_hooks_log_info "pmem task_status: $git_hooks_pmem_ref_footer_task_status"

if git_hooks_pmem_ref_footer_status_is_closed "$git_hooks_pmem_ref_footer_task_status"; then
  git_hooks_log_error "ticket has been $git_hooks_pmem_ref_footer_task_status and does not accept new changes under this status; check whether using a correct ticket"
  exit 1
fi

exit 0
