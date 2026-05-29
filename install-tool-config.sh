#!/usr/bin/env sh

set -u

git_hooks_config_usage() {
  cat <<'EOF'
Usage: install-tool-config.sh [--repo <path>] [--force] <check-id>

Copy a bundled hook tool config into the target repo root for local overrides.

Allowed check IDs:
  common/md-lint
    config/markdownlint/markdownlint.yaml -> .markdownlint-cli2.yaml
  golang/golangci-lint
    config/golangci-lint/config.yaml -> .golangci.yaml

Options:
  --repo <path>  target repository; defaults to current Git repo
  --force        replace an existing repo-local config
  -h, --help     show this help
EOF
}

git_hooks_config_error() {
  printf 'git-hooks: error: %s\n' "$*" >&2
}

git_hooks_config_hint() {
  printf 'git-hooks: info: %s\n' "$*" >&2
}

git_hooks_config_info() {
  printf 'git-hooks: %s\n' "$*"
}

git_hooks_config_warn() {
  printf 'git-hooks: warn: %s\n' "$*" >&2
}

git_hooks_config_supported_ids() {
  printf '%s\n' 'common/md-lint golang/golangci-lint'
}

git_hooks_config_lookup() {
  git_hooks_config_check_id=$1

  case "$git_hooks_config_check_id" in
  common/md-lint)
    git_hooks_config_source_rel=config/markdownlint/markdownlint.yaml
    git_hooks_config_dest_rel=.markdownlint-cli2.yaml
    ;;
  golang/golangci-lint)
    git_hooks_config_source_rel=config/golangci-lint/config.yaml
    git_hooks_config_dest_rel=.golangci.yaml
    ;;
  *)
    return 1
    ;;
  esac

  return 0
}

git_hooks_config_repo_root() {
  if [ -n "${git_hooks_config_repo:-}" ]; then
    (cd "$git_hooks_config_repo" 2>/dev/null && command git rev-parse --show-toplevel 2>/dev/null)
    return $?
  fi

  command git rev-parse --show-toplevel 2>/dev/null
}

git_hooks_config_check_id=
git_hooks_config_force=0
git_hooks_config_repo=

while [ "$#" -gt 0 ]; do
  case "$1" in
  --force)
    git_hooks_config_force=1
    shift
    ;;
  --repo)
    if [ "$#" -lt 2 ]; then
      git_hooks_config_usage >&2
      exit 2
    fi
    git_hooks_config_repo=$2
    shift 2
    ;;
  -h | --help)
    git_hooks_config_usage
    exit 0
    ;;
  --*)
    git_hooks_config_usage >&2
    exit 2
    ;;
  *)
    if [ -n "$git_hooks_config_check_id" ]; then
      git_hooks_config_error 'only one check ID may be provided'
      git_hooks_config_hint "allowed check IDs: $(git_hooks_config_supported_ids)"
      exit 2
    fi
    git_hooks_config_check_id=$1
    shift
    ;;
  esac
done

if [ -z "$git_hooks_config_check_id" ]; then
  git_hooks_config_error 'check ID is required'
  git_hooks_config_hint "allowed check IDs: $(git_hooks_config_supported_ids)"
  exit 2
fi

if ! git_hooks_config_lookup "$git_hooks_config_check_id"; then
  git_hooks_config_error "unsupported check ID: $git_hooks_config_check_id"
  git_hooks_config_hint "allowed check IDs: $(git_hooks_config_supported_ids)"
  exit 2
fi

git_hooks_config_home=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
git_hooks_config_source=$git_hooks_config_home/$git_hooks_config_source_rel

if [ ! -f "$git_hooks_config_source" ]; then
  git_hooks_config_error "missing bundled config: $git_hooks_config_source_rel"
  git_hooks_config_hint 'reinstall or update git-hooks runtime'
  exit 1
fi

git_hooks_config_root=$(git_hooks_config_repo_root) || {
  git_hooks_config_error 'not inside a git repository; pass --repo <path>'
  exit 1
}

git_hooks_config_dest=$git_hooks_config_root/$git_hooks_config_dest_rel

if [ -e "$git_hooks_config_dest" ] && [ "$git_hooks_config_force" -eq 0 ]; then
  git_hooks_config_error "config already exists: $git_hooks_config_dest_rel"
  git_hooks_config_hint 'pass --force to replace it'
  exit 1
fi

command mkdir -p "$(command dirname "$git_hooks_config_dest")" || exit $?
command cp "$git_hooks_config_source" "$git_hooks_config_dest" || exit $?

git_hooks_config_info "copied; check-id=$git_hooks_config_check_id; path=$git_hooks_config_dest_rel"
git_hooks_config_warn 'repo-local config now overrides bundled defaults; track future bundled changes manually'
