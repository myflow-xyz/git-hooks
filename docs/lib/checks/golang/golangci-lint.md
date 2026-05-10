# `lib/checks/golang/golangci-lint.sh`

## Scope

Go static analysis check for `pre-push`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `golangci-lint` from `PATH`.
- Skips silently when neither `go.mod` nor `go.work` exists.
- Skips silently when the repo has no tracked or untracked, non-ignored Go
  source files.
- Prepares configured Go runtime directories such as `GOCACHE` and `GOTMPDIR`
  before invoking `golangci-lint`.
- Runs `golangci-lint run` across the repository.
- Uses the first existing config in this priority order:
- `$REPO/.golangci.yml`
- `$REPO/.golangci.yaml`
- `$REPO/.golangci.toml`
- `$REPO/.golangci.json`
- `$XDG_CONFIG_HOME/golangci-lint/config.yaml`
- `$XDG_CONFIG_HOME/golangci-lint/config.yml`
- `$GIT_HOOKS_HOME/config/golangci-lint/config.yaml`
- If no config exists, falls back to `golangci-lint` built-in defaults instead
  of blocking the push.
- The bundled fallback config uses a 5m timeout, resolves relative paths from
  `go.mod`, includes tests, starts from golangci-lint's `standard` linter set,
  removes issue caps, and adds checks optimized for correctness, lifecycle
  safety, API clarity, naming, soft boundary hygiene, and maintainability.
- The bundled fallback intentionally includes resource/lifecycle checks such as
  `bodyclose`, `durationcheck`, `noctx`, `rowserrcheck`, and `sqlclosecheck`;
  API and boundary checks such as `interfacebloat`, `inamedparam`, `errname`,
  and `goprintffuncname`; correctness checks such as `copyloopvar`,
  `makezero`, `nilerr`, `nilnil`, and `unqueryvet`; plus hygiene checks such
  as `asciicheck`, `bidichk`, `dupword`, `misspell`, `nolintlint`,
  `predeclared`, `usestdlibvars`, and `revive`.
- Strict package or import boundary rules, for example `depguard`, are
  project-specific and should live in repo-local `.golangci.*` config.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `golangci-lint` is unavailable.
- The install hint intentionally recommends the upstream binary release instead
  of Homebrew, because Homebrew may install a separate Go runtime or shim before
  the configured `GOROOT` toolchain.
- Returns the `golangci-lint` exit code and capped diagnostics on failure.

## Related Checks

- `golangci-lint-fast.sh` runs patch-scoped
  `golangci-lint run --fast-only --new-from-patch=<patch> --whole-files`
  during `pre-commit` with bundled hook-only config.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/golangci-lint_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips modules with no Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | prefers repo-local config |
| Existing | `git-hooks` | prefers repo `.golangci.yaml` over bundled config |
| Existing | `git-hooks` | falls back to user XDG config |
| Existing | `git-hooks` | falls back to bundled git-hooks config |
| Existing | `git-hooks` | falls back to built-in defaults |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports lint failure output |
