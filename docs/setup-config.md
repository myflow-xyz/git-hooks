# `setup-config.sh`

## Scope

Copy supported bundled hook tool configs into a target repository for repo-local
overrides.

## Usage

```sh
setup-config.sh [--repo <path>] [--force] <check-id>
```

Allowed check IDs:

| Check ID | Bundled source | Repo-local target |
| --- | --- | --- |
| `common/md-lint` | `config/markdownlint/markdownlint.yaml` | `.markdownlint-cli2.yaml` |
| `golang/golangci-lint` | `config/golangci-lint/config.yaml` | `.golangci.yaml` |

## Behavior

- Resolves the target repository from `--repo` or the current Git repository.
- Accepts only checks whose runtime explicitly prefers repo-local config over
  bundled config.
- Copies the bundled config into the repo root.
- Refuses to overwrite existing repo-local config unless `--force` is passed.
- Warns after copying because the new repo-local config overrides bundled
  defaults and future bundled changes will not apply automatically.
- Does not support `golang/golangci-lint-fast`; that check intentionally uses
  hook-only bundled fast-mode policy.

## Examples

Copy Markdown lint defaults:

```sh
setup-config.sh common/md-lint
```

Copy full Go lint defaults:

```sh
setup-config.sh golang/golangci-lint
```

Replace an existing local copy:

```sh
setup-config.sh --force common/md-lint
```

Run from outside the target repository:

```sh
setup-config.sh --repo /path/to/repo golang/golangci-lint
```

## Output Policy

Output is short and action-oriented:

- Success: `git-hooks: copied; check-id=<check-id>; path=<repo-local-path>`
- Warning: `git-hooks: warn: repo-local config now overrides bundled defaults; track future bundled changes manually`
- Failure: `git-hooks: error: <reason>`
- Actionable hints: `git-hooks: info: <hint>`

## Test Cases

Run only this script's tests:

- `shellspec test/setup-config_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | copies bundled Markdown lint config |
| Existing | `git-hooks` | copies bundled Go lint config with `--repo` |
| Existing | `git-hooks` | refuses to overwrite without `--force` |
| Existing | `git-hooks` | replaces an existing config with `--force` |
| Existing | `git-hooks` | rejects unsupported check IDs |
| Existing | `git-hooks` | rejects a missing check ID |
| Existing | `git-hooks` | rejects use outside a Git repo |
| Existing | `git-hooks` | shows usage and allowed check IDs |
