# `lib/checks/golang/golangci-lint-fast.sh`

## Scope

Fast Go static analysis check for `pre-commit`.

## Behavior

- Intended for the opt-in `golang` profile, not the common baseline.
- Uses user-level `golangci-lint` from `PATH`.
- Skips when no selected Go module exists.
- Skips when there are no staged text `.go` files.
- Prepares Go runtime directories before invoking `golangci-lint`: when neither the environment nor `go env -w` sets them, `GOCACHE` defaults to `$REPO/.cache/go-build` and `GOTMPDIR` defaults to `$REPO/.tmp/go`; unset `GOLANGCI_LINT_CACHE` defaults to `$REPO/.cache/golangci-lint`.
- Requires bundled config at `$GIT_HOOKS_HOME/config/golangci-lint/fast.yaml`.
- Does not load repo-local or user-level config because this is hook fast-mode policy, not standard project or CI policy.
- Builds a temporary patch from staged text `.go` files and runs: `golangci-lint run --config <fast.yaml> --fast-only --new-from-patch=<patch> --whole-files`.
- Runs in the original checkout, once per selected module containing staged Go files. The patch is relative to each module and limits reports to files touched by staged Go changes.
- Before linting, checks that all tracked files match the Git index and that no non-ignored untracked files exist. Partial staging, unstaged edits or deletion, and untracked files cause a visible warning and a successful skip. The guard is repository-wide, so unrelated files can also cause a skip.
- Ignored files do not cause a skip. Ignore generated cache directories such as `.cache/` and `.tmp/`, or configure caches outside the repository.
- Preserves `GOWORK` and native workspace discovery, including relative external members and local replacements. External repositories are dependencies, not additional lint targets or subjects of the Git guard.
- Does not copy the repository or rewrite workspace/module paths. Ignored and external inputs remain part of the native environment; this check does not claim an isolated staged-build guarantee.
- Removes temporary patches/state after success, failure, or interruption. Complete captured failure logs are retained. Staged goimports and full pre-push lint are unaffected by a fast-lint skip.
- The bundled fast config uses a 60s timeout, resolves relative paths from `go.mod`, skips test files, starts from an explicit linter set instead of golangci-lint defaults, and keeps checks focused on fast early signals.
- The bundled fast set prioritizes cheap correctness, naming, API clarity, soft boundary hygiene, and hygiene checks such as `copyloopvar`, `cyclop`, `funlen`, `ineffassign`, `interfacebloat`, `misspell`, `nolintlint`, `predeclared`, `unqueryvet`, and `usestdlibvars`.
- Quiet mode suppresses clean success output and exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks environment.

## Failure Modes

- Skips with an install hint when `golangci-lint` is unavailable.
- The install hint intentionally recommends the upstream binary release instead of Homebrew, because Homebrew may install a separate Go runtime or shim before the configured `GOROOT` toolchain.
- Skips with a hook maintenance hint when bundled fast config is missing.
- Warns and skips for unstaged tracked changes or non-ignored untracked files.
- Fails on Git query errors; they are not treated as an empty or clean tree.
- Returns the `golangci-lint` exit code and capped diagnostics on failure.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/golang/golangci-lint-fast_spec.sh`
- Shared behavior regressions: `shellspec test/checks/golang/quality-gates_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips outside Go modules or workspaces |
| Existing | `git-hooks` | skips without staged Go files |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | skips when bundled fast config is missing |
| Existing | `git-hooks` | creates missing configured Go runtime directories |
| Existing | `git-hooks` | defaults unset Go and golangci-lint runtime directories under the repo root |
| Existing | `git-hooks` | uses patch-scoped bundled fast config |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | reports lint failure output |
| Existing | `git-hooks` | skips staged binary Go files |
| Existing | `git-hooks` | runs in the original checkout when it matches the index |
| Existing | `git-hooks` | visibly skips partial staging and unrelated unstaged files |
| Existing | `git-hooks` | skips untracked files but permits ignored files |
| Existing | `git-hooks` | preserves external workspace members and native GOWORK |
| Existing | `git-hooks` | scopes patches and invocations to affected modules |
| Existing | `git-hooks` | preserves failure and interruption statuses |
