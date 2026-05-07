# `git-hooks`

Portable Git hook runtime, reusable checks, profiles, and repo bootstrap
templates.

This repository is intentionally self-contained. It owns its installer, repo
bootstrap script, runtime helpers, checks, profiles, templates, docs, bundled
fallback config, and tests. It can be cloned directly, vendored, or consumed as
a submodule by another repository.

This is private proprietary tooling. Authorized collaborators may use it for
approved internal projects; redistribution or publication requires explicit
owner approval. See [License](LICENSE).

General policy lives in [Design](docs/design.md) and
[Repo Setup](docs/setup-repo.md). In short: keep `pre-commit` lightweight and
staged-area focused, put heavier full-repo or advisory checks in `pre-push`,
keep hooks portable, keep output concise, and maintain tests plus per-hook
design docs.

## Install Model

There are two separate setup steps:

- `install.sh` installs this shared runtime to `$XDG_CONFIG_HOME/git-hooks`.
- `setup-repo.sh` bootstraps one target repo with tiny `.githooks` wrappers.
- `install.sh` is intentionally self-contained and owns its small link/check/fix
  behavior directly.

The installed runtime is a symlink to this source checkout. Update the source
checkout through Git, then rerun `install.sh --check` when needed to verify the
XDG target still points to the expected source.

Projects keep repo-local `.githooks` wrappers and configure:

```sh
git config --local core.hooksPath .githooks
```

Those wrappers call the shared dispatcher under `$XDG_CONFIG_HOME/git-hooks`.
Default `common` policy is provided by the shared runtime, so repos do not need
config files for the normal case. Optional project policy can live in
`.githooks/project.conf`; optional local machine overrides can live in
`.githooks/hooks.env`.

## Quickstart

1. From the `git-hooks` source checkout, run `./install.sh` to link the runtime
   into
   `$XDG_CONFIG_HOME/git-hooks`.
2. Verify the shared runtime with `./install.sh --check`.
3. From a target repo, run `$XDG_CONFIG_HOME/git-hooks/setup-repo.sh`.
4. Verify the repo bootstrap with
   `$XDG_CONFIG_HOME/git-hooks/setup-repo.sh --check`.
5. Select built-in profiles when a repo needs language or stack-specific
   checks, for example `--profiles "common golang"`.
6. Add `.githooks/project.conf` or `.githooks/hooks.env` only when the repo
   needs non-default policy, extra checks, or local overrides.

## Setup Examples

Default common hooks:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo.sh
```

Profile example with inferred `pre-push`:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo.sh \
  --profiles "common shell"
```

Verify the same bootstrap:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo.sh --check \
  --profiles "common shell"
```

Custom hook phase selection:

```sh
$XDG_CONFIG_HOME/git-hooks/setup-repo.sh \
  --hooks "pre-commit pre-push" \
  --profiles "common shell"
```

`--hooks` is an explicit override. When omitted, setup infers `pre-push` for
profiles that define `pre-push` checks.

Custom extra checks in `.githooks/project.conf`:

```sh
GIT_HOOK_PROFILES="common"
GIT_HOOK_PRE_COMMIT_EXTRA_CHECKS="frontend/oxfmt frontend/oxlint"
GIT_HOOK_PRE_PUSH_EXTRA_CHECKS="frontend/vitest"
```

`--hooks` selects which Git wrapper phases exist in the repo. `--profiles`
selects built-in check lists. Multiple profiles are merged by running each
profile in declared order, then phase-specific `GIT_HOOK_*_EXTRA_CHECKS` are
appended. Extra checks do not override profile checks, and duplicate check IDs
are not de-duplicated. Unknown profiles are invalid. Duplicate profiles are
invalid for setup/check, but runtime skips repeated profiles with a warning for
existing repo configs. Omit empty variables; missing extra-check variables
default to empty.

## Layout

```text
git-hooks/
  README.md
  CHANGELOG.md
  LICENSE
  install.sh
  setup-repo.sh
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
- [Install](docs/install.md)
- [Repo Setup](docs/setup-repo.md)
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
  - [oxlint](docs/lib/checks/frontend/oxlint.md)
  - [oxfmt](docs/lib/checks/frontend/oxfmt.md)
  - [vitest](docs/lib/checks/frontend/vitest.md)
- Go checks:
  - [goimports](docs/lib/checks/golang/goimports.md)
  - [golangci-lint-fast](docs/lib/checks/golang/golangci-lint-fast.md)
  - [golangci-lint](docs/lib/checks/golang/golangci-lint.md)
  - [go-mod-tidy](docs/lib/checks/golang/go-mod-tidy.md)
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
- Shell checks:
  - [files](docs/lib/checks/shell/files.md)
  - [shfmt](docs/lib/checks/shell/shfmt.md)
  - [shellcheck](docs/lib/checks/shell/shellcheck.md)
  - [executable](docs/lib/checks/shell/executable.md)
  - [shellspec](docs/lib/checks/shell/shellspec.md)
