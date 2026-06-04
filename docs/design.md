# `git-hooks` Design

## Goal

Keep Git hook behavior consistent across projects without copying large scripts
into every repo. The shared runtime is installed once under
`$XDG_CONFIG_HOME/git-hooks`; each project owns only tiny `.githooks`
entrypoints and policy selection.

## Repository Boundary

`git-hooks` is designed as a standalone source repository. It may be cloned
directly, vendored, or consumed by another repo as a submodule. Runtime behavior
must not depend on a parent repository, personal shell aliases, machine-local
paths, or other untracked setup.

The source repository owns its operational boundary:

- Keep the installer, runtime helpers, checks, profiles, templates, docs, and
  tests together in this repository.
- Keep `install.sh` self-contained so it can install the shared runtime into XDG
  config using portable shell and standard commands.
- Resolve runtime paths from `GIT_HOOKS_HOME`, `XDG_CONFIG_HOME`, and the target
  repository instead of relying on repo-specific globals.
- Treat repo-local `.githooks` files as the only project integration contract.
- Prefer portable `sh` for shared runtime code unless a check explicitly
  documents a stricter shell requirement.

When this repository is consumed as a submodule, the parent repo should treat
the submodule as a pinned dependency. Update by moving the submodule pointer to
a reviewed commit or tag, then run `install.sh --check` and target repo
`setup-repo-hooks.sh --check` where applicable.

The repository is private proprietary tooling unless the owner explicitly
changes the license. Tags are the release boundary after migration; downstream
repos should pin reviewed tags or commits instead of tracking a moving branch.

## Execution Model

- `install.sh` installs or verifies the shared runtime symlink in user XDG
  config.
- `setup-repo-hooks.sh` installs or verifies repo-local Git hook wrappers.
- Repo-local `.githooks/{pre-commit,pre-push,commit-msg}` are tiny wrappers.
- Repos install only the wrappers they need; default install uses `pre-commit`,
  `pre-push`, and `commit-msg` from the `common` profile.
- Git uses repo-local `core.hooksPath=.githooks`.
- Wrappers call `lib/dispatcher/run-hook.sh <phase>`.
- If the shared dispatcher executable is missing, wrappers warn and skip checks
  instead of blocking Git commands. This surfaces missing local runtime setup
  without making cloned repos unusable.
- The dispatcher loads runtime helpers, repo-local env/config, profile lists,
  then runs reusable check entrypoints.
- Profile and extra-check lists use stable check IDs such as `common/gitleaks`,
  which resolve to `lib/checks/common/gitleaks.sh`.
- Phase-specific extra hooks can be builtin or local. Builtin extra hooks use
  `GIT_HOOK_*_EXTRA_CHECKS` and resolve through the shared runtime. Local extra
  hooks use `GIT_HOOK_*_EXTRA_LOCAL_HOOKS` and resolve under
  `.githooks/hooks/<id>.sh`.
- Dispatcher and check scripts treat `SIGHUP`, `SIGINT`, and `SIGTERM` as
  immediate aborts, not ordinary failures to aggregate.
- `hooks.env` is optional and for exported machine-local environment only.
- `project.conf` is optional. Default `common` profile needs no repo-local
  config; non-default profiles or extra checks may use it.

## Environment Priority

Runtime environment is resolved in this order, from lowest to highest priority:

- Built-in defaults, for example `GIT_HOOK_PROFILES=common`.
- Parent process environment, for example variables exported by your shell.
- Repo-local `.githooks/hooks.env`, loaded with export semantics for child
  checks.
- Repo-local `.githooks/project.conf`, loaded after `hooks.env` for hook policy.

If the same variable is set in both your shell and `.githooks/hooks.env`, the
repo-local `.githooks/hooks.env` value wins. Use shell env for temporary
one-command overrides only when the repo does not set the same variable.

AI agent configs should force quiet mode in the agent runtime environment, for
example `GIT_HOOK_VERBOSE=0`, so a developer's interactive shell setting does
not leak into Codex, Claude Code, IDE agents, or sandboxed command execution.
This should be done in the agent runtime config, not inside each Git hook.

Agent quiet-mode examples:

- Codex: use `shell_environment_policy.set` to inject
  `GIT_HOOK_VERBOSE=0` into spawned commands.
- Claude Code: use `settings.json` `env` to apply
  `GIT_HOOK_VERBOSE=0` to sessions.

If a repo intentionally wants verbose hook output even for agents, it can still
set `GIT_HOOK_VERBOSE=1` in `.githooks/hooks.env`, because repo-local hook env
is loaded after the agent process environment.

## Timing Policy

- `pre-commit` must stay performance-sensitive and lightweight.
- `pre-commit` should operate on the staged area whenever the tool supports it.
- `pre-commit` is for staged secret scan, whitespace/EOF checks, staged
  EOL-LF checks, formatting checks, staged lint, import sorting checks,
  and tiny quick tests.
- Unit tests for code affected by the staged change may run in `pre-commit` only
  when they are predictably fast and scoped.
- `pre-push` is for heavier work: full repo tests, package-wide lint, type
  checks, production builds, coverage reports, dependency audits, integration
  checks, full scanner runs, and non-blocking repo hygiene recommendations.
- `commit-msg` should validate commit messages only. Common policy requires
  conventional commits with mandatory scope.
- Hooks must not mutate tracked repo files, dependency locks, or tool config
  unless the hook is explicitly documented as a fix/install action. Documented
  runtime cache directories are allowed for checks that need persistent local
  tool caches.
- Hooks that invoke project-owned tools should clear git-hooks runtime variables
  and Git local repository variables for the child command. The check script
  should use Git state for its own discovery first, then run the project tool
  like a manual command from the project root. Tools that intentionally operate
  on hook Git state, for example staged-diff scanners, should keep the hook Git
  environment.

## Layout Contract

```text
$XDG_CONFIG_HOME/git-hooks/
  install.sh                # shared runtime installer
  setup-repo-hooks.sh      # target repo hook setup
  install-tool-config.sh   # optional repo-local tool config installer
  config/                  # bundled fallback tool config
  lib/common/              # runtime helpers only
  lib/checks/common/       # reusable check entrypoints
  lib/checks/dev/          # opt-in development workflow checks
  lib/checks/frontend/     # opt-in frontend stack checks
  lib/checks/golang/       # opt-in Golang checks
  lib/checks/pmem/         # opt-in Project Memory workflow checks
  lib/checks/python/       # opt-in Python checks
  lib/checks/shell/        # opt-in shell script checks
  lib/dispatcher/          # phase/profile orchestration
  profiles/<profile>/      # declarative phase lists
  templates/               # repo-local bootstrap templates
```

Current profile names:

- `common`
- `react-vite`
- `golang`
- `pmem`
- `python`
- `shell`

Generic catch-all profiles are intentionally excluded until the stack and checks
are concrete enough to maintain.

## Design Rules

- Prefer repo-local `core.hooksPath`; do not rely on a global Git hook path.
- Keep repo-local hook files tiny and boring.
- Fail open only before the shared runtime starts, when the dispatcher
  executable is missing. Once the dispatcher starts, runtime bootstrap errors
  and check failures must still fail closed.
- Keep `lib/common` for helpers only; real checks belong under `lib/checks`.
- Use check IDs in profile lists. Do not store full `lib/checks/...` paths
  there, and do not recursively search by filename because duplicate check names
  should fail by design, not search order.
- Do not duplicate root detection, staged-file discovery, logging, path joining,
  or environment defaults inside check scripts.
- Repo-local custom hooks must live under `.githooks/hooks` and be selected
  through `GIT_HOOK_*_EXTRA_LOCAL_HOOKS`. Their IDs are suffixless paths
  relative to that root, for example `dir/xhook` for
  `.githooks/hooks/dir/xhook.sh`.
- Repo-local custom hooks run through the dispatcher, not through wrapper
  template changes.
- Repo-local custom hooks should follow the same hook contract as shared
  checks: executable script, exit `0` on success, non-zero on failure, preserve
  signal-like statuses where possible, avoid interactive prompts, keep success
  output quiet, and honor `GIT_HOOK_VERBOSE=1` when they print progress.
- Missing repo-local custom hook files warn and skip so a stale local reference
  does not block builtin checks or other configured hooks. Existing non-file or
  non-executable local hook paths fail because the repo policy points at a
  script that cannot run.
- The dispatcher wraps local hook execution, captures local hook output, replays
  bounded output on failure, and prints a consistent failure line with the local
  hook ID and exit status.
- Keep normal successful output quiet; report only actionable failures unless
  `GIT_HOOK_VERBOSE=1`.
- Use `.gitattributes` as the primary checkout policy for line endings and the
  staged `common/eol-lf` hook as the enforcement guard before content enters the
  repo.
- Stop the whole hook chain immediately on `SIGHUP`, `SIGINT`, or `SIGTERM`.
  Cleanup-only traps for those signals are forbidden because they can swallow
  `Ctrl+C` and continue to later checks.
- Signal exits should use conventional statuses: `129` for `SIGHUP`, `130` for
  `SIGINT`, and `143` for `SIGTERM`.
- Long-running checks that iterate over multiple roots or files must stop on
  signal-like child statuses (`>=128`) instead of continuing to the next item.
- If an optional external tool is missing, skip that check with a concise
  warning that includes the check name, missing command, and install hint.
- Hook tools should be widely used by their community, actively maintained, and
  familiar enough that failures are easy to interpret.
- Hooks should be portable across `sh`, `bash`, and `zsh` unless a stricter
  shell requirement is explicitly documented.
- Hooks that depend on a runtime or package manager should resolve it
  dynamically from hook env and repo state, for example Python `uv` runner
  selection.
- Hook-internal environment is control-plane state, not project test input.
  Variables such as `GIT_HOOK_*` and `GIT_HOOKS_HOME` must not leak into
  project-owned test suites unless a hook explicitly documents that contract.
- Checks that run project test suites should make the suite environment match
  manual local execution or CI worker execution. This prevents hook-only
  behavior, recursive hook policy inheritance, and agent/local drift.
- The dispatcher should restore the hook-entry index snapshot when `pre-commit`
  fails or is interrupted. This protects against hook-side staging changes, but
  it does not undo staging Git performed before the hook, such as
  `git commit -a`.
- Stack profiles may declare package-manager policy. The `react-vite` profile
  uses `pnpm` project dependencies and should not fall back to `npm`, `npx`, or
  global Node tools.
- Frontend stack checks should require repo-local `node_modules/.bin/<tool>`
  binaries. Global installs are ignored so hook behavior follows project
  dependencies and stays reproducible across machines and CI.
- React/Vite E2E checks should run in `pre-push`, require repo-local
  Playwright when E2E tests are present, and skip when the repo has no E2E test
  cases.
- Go stack checks use user-level Go tooling from `PATH`. Tools installed with
  the configured Go toolchain, such as `govulncheck` installed through
  `go install ...`, are acceptable.
  External Go-related binaries such as `golangci-lint` should prefer upstream
  binary releases over package managers like Homebrew, because package managers
  may install another Go runtime or shim ahead of the selected `GOROOT`.
  Missing optional Go tools should skip with a concise install hint.
- Go stack checks that invoke the Go toolchain default unset `GOCACHE` to
  `$REPO/.cache/go-build` and unset `GOTMPDIR` to `$REPO/.tmp/go`. Repo-local
  `.githooks/hooks.env` values take priority. Missing directories are created;
  existing non-directory paths fail with a concise error.
- `golangci-lint` checks additionally default unset `GOLANGCI_LINT_CACHE` to
  `$REPO/.cache/golangci-lint`. This default is loaded only by golangci-lint
  checks, not by generic Go checks.
- Golang hooks should keep staged formatting and fast lint checks in
  `pre-commit`, then module hygiene, vulnerability advisory scanning,
  package-wide lint, vet, and test checks in `pre-push`.
- Go fast lint is hook policy, not standard project policy. It should use only
  bundled git-hooks config and `golangci-lint run --fast-only`. In
  `pre-commit`, it should generate a staged patch and pass
  `--new-from-patch=<patch> --whole-files` so lint output stays focused on
  files touched by the commit.
- Python hooks use a runner abstraction because projects may use `uv`, Poetry,
  pip, virtualenv, or another environment manager.
- Python runner `auto` should use `uv run` when `uv.lock` exists and otherwise
  fall back to the active environment or `PATH`.
- Python uv mode should default to `--frozen` so hooks do not update lockfiles.
- Python hooks should keep staged Ruff format, import sorting, and lint checks
  in `pre-commit`, then mypy and pytest in `pre-push`.
- Python coverage and dependency audit checks are explicit extras by default:
  coverage can duplicate test execution, while dependency audit can be slower
  or require advisory/database access.
- Project Memory (`pmem`) hooks are opt-in and should stay in `commit-msg`
  until there is a concrete need for repo-content checks. The profile is
  enforced only when the local `pmem` CLI is available and `pmem info --repo
  --json` reports active repo PMem config; missing CLI or missing repo config
  should warn and skip. Configured repos must require a `Ref: <task-id>` footer,
  resolve the repo `project_id` through `pmem info --repo --json`, and validate
  the work item with `pmem wi get --project-id <project-id> --id <task-id>
  --json`. The hook should fail on PMem CLI/API errors and should reject
  `canceled`, `done`, and `closed` work items because those statuses should not
  accept new changes.
- Shell hooks use explicit extensions only: `.sh`, `.bash`, and `.zsh`.
- Shell `pre-commit` checks should operate on staged shell files wherever those
  files live in the repository.
- Shell formatting and ShellCheck checks should skip `.zsh` files by default
  because zsh support is not reliable enough for this conservative profile.
- Shell executable checks should validate consistency, not force every shell
  file to be executable. Sourced fragments and config snippets may remain
  non-executable.
- ShellSpec checks should run in `pre-push` and discover tracked `.shellspec`
  files anywhere in the repository, running once from each owning directory.
- ShellSpec project suites must run like manual test commands. Clear Git hook
  runtime variables and Git local repository variables before invoking
  `shellspec`, so nested hook tests can create and inspect independent Git repos.
- Tool config belongs outside check scripts. Checks should load repo-local
  standard config first, user XDG config second, and bundled git-hooks fallback
  config last when the tool supports explicit config files.
- If none of those config files exist, checks should use the tool default config
  instead of blocking, unless the hook explicitly documents that bundled config
  is mandatory.
- Bundled fallback config keeps hooks self-maintained. It should be conservative
  enough for general use and easy for a repo to override with standard config
  filenames used by the underlying tool and CI.
- Future checks that execute project tools should use
  `git_hooks_env_run_project_command <tool> [args...]` by default. This prevents
  hook-local Git variables such as `GIT_DIR`, `GIT_WORK_TREE`, `GIT_COMMON_DIR`,
  and `GIT_INDEX_FILE` from leaking into nested project tests or tool commands.
- Do not use `git_hooks_env_run_project_command` for commands that intentionally
  inspect hook Git state, such as staged-file discovery, staged patch creation,
  or scanners that run against `--staged` content. Keep those commands in the
  hook environment and document the reason when it is not obvious.
- Development workflow checks belong under `lib/checks/dev`, not the common
  profile. These checks may maintain local machine state for developer tools,
  but they still must avoid tracked-file edits, prompts, and noisy success
  output.
- Development checks that create local tool state should prefer `.git/info/exclude`
  for generated cache/index directories when the target repository has not
  already ignored them. They must not silently edit tracked ignore files.
- Hook implementation commits should stay reviewable: docs first, then one
  commit per reusable hook, then profile updates.
- Each hook must include ShellSpec coverage and keep its documented test case
  table in sync with implemented behavior.
- Add regression tests for historical bugs or surprising behavior so they do not
  reappear during refactors.

## Output Contract

Git hook checks should be quiet-by-default, failure-oriented, and
bounded-output.

- Exit `0` means the check passed. Do not print normal successful tool output.
- Print skip/progress details only when `GIT_HOOK_VERBOSE=1` or `true`.
- On failure, print the check name, reason, affected path when known, and the
  next action needed to fix it.
- External tools that can emit noisy output should be captured. Replay only the
  useful failure output and cap it to a documented line limit.
- Preserve the external tool exit code when that code is meaningful.
- Do not depend on `rtk` or another wrapper to reduce hook output. Hooks must be
  concise when run directly by Git, an IDE, a terminal, or an agent.
