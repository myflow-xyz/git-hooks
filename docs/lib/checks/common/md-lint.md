# `lib/checks/common/md-lint.sh`

## Scope

Staged Markdown lint check for `pre-commit`.

## Behavior

- Skips silently when no staged `.md` or `.markdown` files exist.
- Skips binary staged Markdown paths before selecting or invoking a linter.
- Runs `markdownlint-cli2` for each staged text Markdown file.
- Passes an explicit config to `markdownlint-cli2` when a config exists.
- Uses `--no-globs` with explicit staged files so config `globs` do not expand
  lint scope to unrelated repository files.
- Uses the first existing config in this priority order:
- `$REPO/.markdownlint-cli2.yaml`
- `$REPO/.markdownlint.yaml`
- `$XDG_CONFIG_HOME/markdownlint/markdownlint.yaml`
- `$GIT_HOOKS_HOME/config/markdownlint/markdownlint.yaml`
- If no config exists, falls back to markdownlint's built-in defaults instead
  of blocking the commit.
- The bundled fallback config sets `MD013` normal and code block line limits to
  999999 characters, keeps headings at 100 characters, excludes code blocks and
  tables from active line length checks, and keeps structural readability rules
  enabled.
- The bundled fallback excludes common generated or dependency paths through
  `globs`, including `.git`, `node_modules`, `vendor`, `dist`, `build`, and
  `coverage`.
- Quiet mode captures `markdownlint-cli2` output, suppresses successful output,
  and exits `0` on clean lint.
- Verbose mode keeps normal information output enabled, including the selected
  config path and native `markdownlint-cli2` output.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE=1` or `true` from the shared
  git-hooks environment, including repo-local `.githooks/hooks.env`.

## Failure Modes

- Skips with an install hint when `markdownlint-cli2` is unavailable and
  Markdown files are staged.
- Returns `1` when any Markdown lint command fails.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/md-lint_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged Markdown files |
| Existing | `git-hooks` | runs `markdownlint-cli2` for staged Markdown files |
| Existing | `git-hooks` | does not expand configured globs for explicit files |
| Existing | `git-hooks` | skips with an install hint when linter is missing |
| Existing | `git-hooks` | skips staged binary Markdown files |
| Existing | `git-hooks` | prefers repo-local `.markdownlint-cli2.yaml` |
| Existing | `git-hooks` | falls back to repo-local `.markdownlint.yaml` |
| Existing | `git-hooks` | falls back to user XDG markdownlint config |
| Existing | `git-hooks` | falls back to bundled git-hooks config |
| Existing | `git-hooks` | uses bundled config that relaxes normal and code block line limits |
| Existing | `git-hooks` | falls back to built-in defaults |
| Existing | `git-hooks` | keeps clean lint success silent in quiet mode |
| Existing | `git-hooks` | honors verbose mode from repo hook env |
| Recommended | `git-hooks` | Cover multi-file lint failure. |
