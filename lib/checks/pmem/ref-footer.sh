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
  printf '%s\n' 'Refs: <task-id>; 3 <= id length < 24'
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
  project_id)
    printf '%s\n' .project_id
    ;;
  project_name)
    printf '%s\n' .project_name
    ;;
  project_exists)
    printf '%s\n' .project_exists
    ;;
  status)
    printf '%s\n' .status
    ;;
  task_type)
    printf '%s\n' .type
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

git_hooks_pmem_ref_footer_json_string_optional() {
  if [ "$#" -ne 2 ]; then
    git_hooks_log_error 'Usage: git_hooks_pmem_ref_footer_json_string_optional <json> <field>'
    return 2
  fi

  git_hooks_pmem_ref_footer_path=$(git_hooks_pmem_ref_footer_json_path "$2") || return 2

  if ! command -v jq >/dev/null 2>&1; then
    git_hooks_log_error 'required command not found: jq'
    return 127
  fi

  printf '%s\n' "$1" |
    command jq -r "if ($git_hooks_pmem_ref_footer_path == null) then empty elif ($git_hooks_pmem_ref_footer_path | type) == \"string\" then $git_hooks_pmem_ref_footer_path else empty end" 2>/dev/null
}

git_hooks_pmem_ref_footer_log_value() {
  if [ "$#" -ne 1 ]; then
    git_hooks_log_error 'Usage: git_hooks_pmem_ref_footer_log_value <value>'
    return 2
  fi

  if [ -z "$1" ]; then
    printf '%s\n' '-'
    return 0
  fi

  printf '%s' "$1" | command tr '\r\n' '  '
}

git_hooks_pmem_ref_footer_cli_json_validate() {
  if [ "$#" -ne 2 ]; then
    git_hooks_log_error 'Usage: git_hooks_pmem_ref_footer_cli_json_validate <label> <json>'
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

    function trailer_key(value) {
      if (value !~ /^[[:alnum:]][[:alnum:]-]*:[[:space:]]*[^[:space:]]/) {
        return ""
      }

      sub(/:.*/, "", value)
      return value
    }

    /^[[:space:]]*#/ { next }
    {
      lines[++line_count] = $0

      git_hooks_pmem_ref_footer_key = trailer_key($0)
      if (tolower(git_hooks_pmem_ref_footer_key) == "refs") {
        ref_count++
      }
    }

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

        git_hooks_pmem_ref_footer_key = trailer_key(line)

        if (git_hooks_pmem_ref_footer_key == "") {
          exit 1
        }

        if (tolower(git_hooks_pmem_ref_footer_key) == "refs") {
          found = 1

          if (git_hooks_pmem_ref_footer_key != "Refs") {
            invalid_ref = 1
            continue
          }

          sub(/^Refs:[[:space:]]*/, "", line)
          line = trim(line)

          if (!valid_id(line)) {
            invalid_ref = 1
          } else {
            if (task_id == "") {
              task_id = line
            }
          }
        }
      }

      if (ref_count > 1) {
        exit 4
      }

      if (invalid_ref) {
        exit 3
      }

      if (task_id != "") {
        print task_id
        exit 0
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
  git_hooks_pmem_ref_footer_run_cli "$git_hooks_pmem_ref_footer_bin" info --repo --json --quiet
)
git_hooks_pmem_ref_footer_info_status=$?

if [ "$git_hooks_pmem_ref_footer_info_status" -ne 0 ]; then
  git_hooks_log_error "pmem info failed; exit=$git_hooks_pmem_ref_footer_info_status"
  exit 1
fi

git_hooks_pmem_ref_footer_cli_json_validate 'pmem info' "$git_hooks_pmem_ref_footer_info_json" || exit $?

git_hooks_pmem_ref_footer_project_name=$(
  git_hooks_pmem_ref_footer_json_string_optional "$git_hooks_pmem_ref_footer_info_json" project_name
) || exit $?

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

git_hooks_pmem_ref_footer_task_id=$(git_hooks_pmem_ref_footer_task_id "$git_hooks_pmem_ref_footer_file")
git_hooks_pmem_ref_footer_status=$?

case "$git_hooks_pmem_ref_footer_status" in
0)
  ;;
3)
  git_hooks_log_error 'invalid Refs footer id'
  git_hooks_pmem_ref_footer_info "expected footer: $(git_hooks_pmem_ref_footer_expected_footer)"
  exit 1
  ;;
4)
  git_hooks_log_error 'multiple Refs footers are not allowed'
  git_hooks_pmem_ref_footer_info "expected footer: $(git_hooks_pmem_ref_footer_expected_footer)"
  git_hooks_pmem_ref_footer_info 'reference exactly one PMem ticket per commit; split changes into separate commits when they belong to different tickets'
  exit 1
  ;;
*)
  git_hooks_log_error 'missing Refs footer'
  git_hooks_pmem_ref_footer_info "expected footer: $(git_hooks_pmem_ref_footer_expected_footer)"
  exit 1
  ;;
esac

git_hooks_pmem_ref_footer_wi_json=$(
  git_hooks_pmem_ref_footer_run_cli \
    "$git_hooks_pmem_ref_footer_bin" wi get \
    --project-id "$git_hooks_pmem_ref_footer_project_id" \
    --id "$git_hooks_pmem_ref_footer_task_id" \
    --fields status,type \
    --json \
    --quiet
)
git_hooks_pmem_ref_footer_wi_status=$?

if [ "$git_hooks_pmem_ref_footer_wi_status" -ne 0 ]; then
  git_hooks_log_error "pmem wi get failed; id=$git_hooks_pmem_ref_footer_task_id; exit=$git_hooks_pmem_ref_footer_wi_status"
  exit 1
fi

git_hooks_pmem_ref_footer_cli_json_validate 'pmem wi get' "$git_hooks_pmem_ref_footer_wi_json" || exit $?

git_hooks_pmem_ref_footer_task_type=$(
  git_hooks_pmem_ref_footer_json_string_optional "$git_hooks_pmem_ref_footer_wi_json" task_type
) || exit $?

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

if git_hooks_log_is_verbose; then
  git_hooks_pmem_ref_footer_project_name_log=$(git_hooks_pmem_ref_footer_log_value "$git_hooks_pmem_ref_footer_project_name")
  git_hooks_pmem_ref_footer_project_id_log=$(git_hooks_pmem_ref_footer_log_value "$git_hooks_pmem_ref_footer_project_id")
  git_hooks_pmem_ref_footer_task_id_log=$(git_hooks_pmem_ref_footer_log_value "$git_hooks_pmem_ref_footer_task_id")
  git_hooks_pmem_ref_footer_task_type_log=$(git_hooks_pmem_ref_footer_log_value "$git_hooks_pmem_ref_footer_task_type")
  git_hooks_pmem_ref_footer_task_status_log=$(git_hooks_pmem_ref_footer_log_value "$git_hooks_pmem_ref_footer_task_status")

  if [ -n "$git_hooks_pmem_ref_footer_project_name" ]; then
    git_hooks_pmem_ref_footer_project_log="project=$git_hooks_pmem_ref_footer_project_name_log ($git_hooks_pmem_ref_footer_project_id_log)"
  else
    git_hooks_pmem_ref_footer_project_log="project_id=$git_hooks_pmem_ref_footer_project_id_log"
  fi

  if [ -n "$git_hooks_pmem_ref_footer_task_type" ]; then
    git_hooks_pmem_ref_footer_task_log="task=$git_hooks_pmem_ref_footer_task_id_log; type=$git_hooks_pmem_ref_footer_task_type_log; status=$git_hooks_pmem_ref_footer_task_status_log"
  else
    git_hooks_pmem_ref_footer_task_log="task=$git_hooks_pmem_ref_footer_task_id_log; status=$git_hooks_pmem_ref_footer_task_status_log"
  fi

  git_hooks_pmem_ref_footer_details=$(
    printf '%s\n\t%s\n\t%s' \
      'pmem details:' \
      "$git_hooks_pmem_ref_footer_project_log" \
      "$git_hooks_pmem_ref_footer_task_log"
  )
  git_hooks_log_info "$git_hooks_pmem_ref_footer_details"
fi

if git_hooks_pmem_ref_footer_status_is_closed "$git_hooks_pmem_ref_footer_task_status"; then
  git_hooks_log_error "ticket has been $git_hooks_pmem_ref_footer_task_status and does not accept new changes under this status; check whether using a correct ticket"
  exit 1
fi

exit 0
