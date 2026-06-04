# `git-hooks`

Portable Git hook runtime, reusable checks, profiles, and repo hook setup
templates.

This repository is intentionally self-contained. It owns its installer, repo
hook setup script, runtime helpers, checks, profiles, templates, docs, bundled
fallback config, and tests. It can be cloned directly, vendored, or consumed as
a submodule by another repository.

This is private proprietary tooling. Authorized collaborators may use it for
approved internal projects; redistribution or publication requires explicit
owner approval. See [License](LICENSE).

General policy lives in [Design](docs/design.md),
[Repo Hook Setup](docs/setup-repo-hooks.md), and
[Tool Config Install](docs/install-tool-config.md). In short: keep `pre-commit`
lightweight and staged-area focused, put heavier full-repo or advisory checks in
`pre-push`, keep hooks portable, keep output concise, and maintain tests plus
per-hook design docs.

## Install Model

There are three separate setup steps:

- `install.sh` installs this shared runtime to `$XDG_CONFIG_HOME/git-hooks`.
- `setup-repo-hooks.sh` bootstraps one target repo with tiny `.githooks` wrappers.
- `install-tool-config.sh` copies supported bundled tool configs into a target repo
  for explicit repo-local overrides.
- `install.sh` is intentionally self-contained and owns its small link/check/fix
  behavior directly.

The installed runtime is a symlink to this source checkout. Update the source
checkout through Git, then rerun `install.sh --check` when needed to verify the
XDG target still points to the expected source.

Git >= 2.9.0 is required for `core.hooksPath`; `install.sh` rejects missing,
unparseable, or older Git before changing the XDG target.

Projects keep repo-local `.githooks` wrappers and configure:

```sh
git config --local core.hooksPath .githooks
```

Those wrappers call the shared dispatcher under `$XDG_CONFIG_HOME/git-hooks`.
If the shared runtime is missing, wrappers warn and skip checks instead of
blocking Git commands; install the runtime before relying on hook enforcement.
Default `common` policy is provided by the shared runtime, so repos do not need
config files for the normal case. Optional project policy can live in
`.githooks/project.conf`; optional local machine overrides can live in
`.githooks/hooks.env`.

## Quickstart

1. From the `git-hooks` source checkout, run `./install.sh` to link the runtime
   into
   `$XDG_CONFIG_HOME/git-hooks`.
2. Verify the shared runtime with `./install.sh --check`.
3. From a target repo, run `$XDG_CONFIG_HOME/git-hooks/setup-repo-hooks.sh`.
4. Verify the repo hook setup with
   `$XDG_CONFIG_HOME/git-hooks/setup-repo-hooks.sh --check`.
5. Select built-in profiles when a repo needs language or stack-specific
   checks, for example `--profiles "common golang"` or
   `--profiles "common pmem"`.
6. Add `.githooks/project.conf` or `.githooks/hooks.env` only when the repo
   needs non-default policy, extra checks, or local overrides.
7. Use `$XDG_CONFIG_HOME/git-hooks/install-tool-config.sh <check-id>` only when
   the repo needs to fork a supported bundled tool config.

## Setup Examples

Default common hooks:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo-hooks.sh
```

Profile example with inferred `pre-push`:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo-hooks.sh \
  --profiles "common shell"
```

Verify the same bootstrap:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo-hooks.sh --check \
  --profiles "common shell"
```

Custom hook phase selection:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo-hooks.sh \
  --hooks "pre-commit pre-push" \
  --profiles "common shell"
```

`--hooks` is an explicit override. When omitted, setup infers `pre-push` for
profiles that define `pre-push` checks.

Custom extra checks in `.githooks/project.conf`:

```sh
GIT_HOOK_PROFILES="common"
GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS="frontend/oxfmt frontend/oxlint"
GIT_HOOK_PRE_PUSH_EXTRA_CHECKS="frontend/vitest frontend/e2e-playwright"
```

Repo-local custom extra hooks in `.githooks/project.conf`:

```sh
GIT_HOOK_PROFILES="common"
GIT_HOOK_PRE_COMMIT_EXTRA_LOCAL_HOOKS="dir/xhook yhook"
```

Local hook IDs are suffixless paths under `.githooks/hooks`, so the example
runs `.githooks/hooks/dir/xhook.sh` and `.githooks/hooks/yhook.sh` after
profile checks and builtin extra checks.

Project Memory (`pmem`) managed repo:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo-hooks.sh \
  --profiles "common pmem"
```

The `pmem` profile is for Project Memory managed repos. It requires
the `pmem` CLI and repo PMem config. When both are present, commits must carry a
`Ref: <task-id>` footer that resolves to an active work item in the repo project.
Missing CLI or missing repo PMem config warns and skips so the opt-in profile
does not block repos that have not finished local PMem setup.

Go profile cache defaults:

```gitignore
.cache/
.tmp/
```

The `golang` profile creates repo-local runtime cache directories by default:
`.cache/go-build`, `.cache/golangci-lint`, and `.tmp/go`. Add the ignore rules
above in Go repos, or override cache locations in `.githooks/hooks.env`.

`--hooks` selects which Git wrapper phases exist in the repo. `--profiles`
selects built-in check lists. Multiple profiles are merged by running each
profile in declared order, then phase-specific builtin
`GIT_HOOK_*_EXTRA_CHECKS` and local `GIT_HOOK_*_EXTRA_LOCAL_HOOKS` are appended.
Extra hooks do not override profile checks, and duplicate IDs are not
de-duplicated. Unknown profiles are invalid. Duplicate profiles are invalid for
setup/check, but runtime skips repeated profiles with a warning for existing
repo configs. Omit empty variables; missing extra-hook variables default to
empty.

Copy bundled tool config for repo-local edits:

```sh
$XDG_CONFIG_HOME/git-hooks/install-tool-config.sh common/md-lint
$XDG_CONFIG_HOME/git-hooks/install-tool-config.sh golang/golangci-lint
```

Only checks that explicitly support repo-local config are accepted. The copied
file overrides bundled defaults, so future bundled config updates must be
tracked manually for that repo-local copy.

## Layout

```text
git-hooks/
  README.md
  CHANGELOG.md
  LICENSE
  install.sh
  install-tool-config.sh
  setup-repo-hooks.sh
  config/
  docs/
  lib/
    common/
    checks/
    dispatcher/
  profiles/
  templates/
```

## Docs

- [Design](docs/design.md)
- [Repo-Local Custom Hooks Spec](docs/local-custom-hooks-spec.md)
- [Install](docs/install.md)
- [Repo Hook Setup](docs/setup-repo-hooks.md)
- [Tool Config Install](docs/install-tool-config.md)
- [Dispatcher](docs/lib/dispatcher/run-hook.md)
- Runtime helpers:
  - [env](docs/lib/common/env.md)
  - [git](docs/lib/common/git.md)
  - [log](docs/lib/common/log.md)
  - [path](docs/lib/common/path.md)
- Common checks:
  - [gitleaks](docs/lib/checks/common/gitleaks.md)
  - [eol-lf](docs/lib/checks/common/eol-lf.md)
  - [whitespace](docs/lib/checks/common/whitespace.md)
  - [eof-newline](docs/lib/checks/common/eof-newline.md)
  - [md-lint](docs/lib/checks/common/md-lint.md)
  - [commit-msg](docs/lib/checks/common/commit-msg.md)
  - [repo-hygiene](docs/lib/checks/common/repo-hygiene.md)
- Frontend checks:
  - [e2e-playwright](docs/lib/checks/frontend/e2e-playwright.md)
  - [oxlint](docs/lib/checks/frontend/oxlint.md)
  - [oxfmt](docs/lib/checks/frontend/oxfmt.md)
  - [vitest](docs/lib/checks/frontend/vitest.md)
- Development checks:
  - [codegraph-build-index](docs/lib/checks/dev/codegraph-build-index.md)
- Go checks:
  - [goimports](docs/lib/checks/golang/goimports.md)
  - [golangci-lint-fast](docs/lib/checks/golang/golangci-lint-fast.md)
  - [golangci-lint](docs/lib/checks/golang/golangci-lint.md)
  - [go-mod-tidy](docs/lib/checks/golang/go-mod-tidy.md)
  - [govulncheck](docs/lib/checks/golang/govulncheck.md)
  - [go-vet](docs/lib/checks/golang/go-vet.md)
  - [go-test](docs/lib/checks/golang/go-test.md)
- Python checks:
  - [env](docs/lib/checks/python/env.md)
  - [ruff-format](docs/lib/checks/python/ruff-format.md)
  - [ruff-imports](docs/lib/checks/python/ruff-imports.md)
  - [ruff-check](docs/lib/checks/python/ruff-check.md)
  - [mypy](docs/lib/checks/python/mypy.md)
  - [pytest](docs/lib/checks/python/pytest.md)
  - [pytest-cov](docs/lib/checks/python/pytest-cov.md)
  - [pip-audit](docs/lib/checks/python/pip-audit.md)
- Project Memory (`pmem`) checks:
  - [ref-footer](docs/lib/checks/pmem/ref-footer.md)
- Shell checks:
  - [files](docs/lib/checks/shell/files.md)
  - [shfmt](docs/lib/checks/shell/shfmt.md)
  - [shellcheck](docs/lib/checks/shell/shellcheck.md)
  - [executable](docs/lib/checks/shell/executable.md)
  - [shellspec](docs/lib/checks/shell/shellspec.md)
