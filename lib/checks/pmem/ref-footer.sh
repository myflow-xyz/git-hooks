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
  printf '%s\n' 'Ref: <id>; 3 <= id length < 24'
}

git_hooks_pmem_ref_footer_project_key() {
  command awk '
    /^[[:space:]]*($|#)/ { next }
    /^[[:space:]]*(export[[:space:]]+)?PMEM_PROJECT_KEY[[:space:]]*=/ {
      value = $0
      sub(/^[[:space:]]*(export[[:space:]]+)?PMEM_PROJECT_KEY[[:space:]]*=[[:space:]]*/, "", value)
      sub(/[[:space:]]+#.*$/, "", value)
      sub(/^[[:space:]]*/, "", value)
      sub(/[[:space:]]*$/, "", value)

      if (value ~ /^".*"$/) {
        value = substr(value, 2, length(value) - 2)
      } else if (value ~ /^\047.*\047$/) {
        value = substr(value, 2, length(value) - 2)
      }

      found = value
    }
    END {
      if (found != "") {
        print found
      }
    }
  ' "$1"
}

git_hooks_pmem_ref_footer_key_is_valid() {
  printf '%s\n' "$1" | command grep -Eq '^[[:alnum:]][[:alnum:]_-]*$'
}

git_hooks_pmem_ref_footer_validate_footer() {
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
            valid = 1
          }
        }
      }

      if (valid) {
        exit 0
      }

      if (found) {
        exit 3
      }

      exit 1
    }
  ' "$1"
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

git_hooks_pmem_ref_footer_env=$GIT_HOOK_REPO_ROOT/.pmem/env

if [ ! -f "$git_hooks_pmem_ref_footer_env" ]; then
  git_hooks_log_error 'missing pmem env: .pmem/env'
  git_hooks_pmem_ref_footer_info 'expected PMEM_PROJECT_KEY=<key> in .pmem/env'
  exit 1
fi

git_hooks_pmem_ref_footer_project_key=$(git_hooks_pmem_ref_footer_project_key "$git_hooks_pmem_ref_footer_env")

if [ -z "$git_hooks_pmem_ref_footer_project_key" ]; then
  git_hooks_log_error 'missing PMEM_PROJECT_KEY in .pmem/env'
  git_hooks_pmem_ref_footer_info 'expected key: [A-Za-z0-9][A-Za-z0-9_-]*'
  exit 1
fi

if ! git_hooks_pmem_ref_footer_key_is_valid "$git_hooks_pmem_ref_footer_project_key"; then
  git_hooks_log_error 'invalid PMEM_PROJECT_KEY in .pmem/env'
  git_hooks_pmem_ref_footer_info 'expected key: [A-Za-z0-9][A-Za-z0-9_-]*'
  exit 1
fi

git_hooks_pmem_ref_footer_validate_footer "$git_hooks_pmem_ref_footer_file"
git_hooks_pmem_ref_footer_status=$?

case "$git_hooks_pmem_ref_footer_status" in
0)
  exit 0
  ;;
3)
  git_hooks_log_error 'invalid ref footer id'
  ;;
*)
  git_hooks_log_error 'missing ref footer'
  ;;
esac

git_hooks_pmem_ref_footer_info "expected footer: $(git_hooks_pmem_ref_footer_expected_footer)"
exit 1
