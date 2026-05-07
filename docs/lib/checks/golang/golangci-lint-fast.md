# `lib/checks/golang/golangci-lint-fast.sh`

## Scope

Fast Go static analysis check for `pre-commit`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `golangci-lint` from `PATH`.
- Skips silently when neither `go.mod` nor `go.work` exists.
- Skips when there are no staged text `.go` files.
- Prepares configured Go runtime directories such as `GOCACHE` and `GOTMPDIR`
  before invoking `golangci-lint`.
- Requires bundled config at
  `$GIT_HOOKS_HOME/config/golangci-lint/fast.yaml`.
- Does not load repo-local or user-level config because this is hook fast-mode
  policy, not standard project or CI policy.
- Builds a temporary patch from staged text `.go` files and runs:
  `golangci-lint run --config <fast.yaml> --fast-only --new-from-patch=<patch> --whole-files`.
- The bundled fast config uses a 60s timeout, resolves relative paths from
  `go.mod`, skips test files, starts from an explicit linter set instead of
  golangci-lint defaults, and keeps checks focused on fast early signals.
- The bundled fast set prioritizes cheap correctness, naming, API clarity, soft
  boundary hygiene, and hygiene checks such as `copyloopvar`, `cyclop`,
  `funlen`, `ineffassign`, `interfacebloat`, `misspell`, `nolintlint`,
  `predeclared`, `unqueryvet`, and `usestdlibvars`.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment.

## Failure Modes

- Skips with an install hint when `golangci-lint` is unavailable.
- The install hint intentionally recommends the upstream binary release instead
  of Homebrew, because Homebrew may install a separate Go runtime or shim before
  the configured `GOROOT` toolchain.
- Skips with a hook maintenance hint when bundled fast config is missing.
- Returns the `golangci-lint` exit code and capped diagnostics on failure.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/golangci-lint-fast_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips without staged Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | skips when bundled fast config is missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | uses patch-scoped bundled fast config |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports lint failure output |
| Existing | `git-hooks` | skips staged binary Go files |
