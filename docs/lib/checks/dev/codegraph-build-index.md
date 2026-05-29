# `lib/checks/dev/codegraph-build-index.sh`

## Scope

Development-only CodeGraph index initialization and rebuild check for
`pre-push`.

## Behavior

- Intended for opt-in development profiles, not the common baseline.
- Uses user-level `codegraph` from `PATH`.
- Runs from the repository root after the shared hook environment has loaded.
- Treats `.codegraph/codegraph.db` as the initialization marker.
- When the repository is not initialized, runs `codegraph init -i .` to create
  `.codegraph/` and build the initial index.
- When the repository is already initialized, runs `codegraph index --force .`
  to rebuild the index from current files.
- Redirects command stdin from `/dev/null` so CodeGraph cannot consume Git
  hook stdin or wait for interactive answers.
- Quiet mode captures CodeGraph output, suppresses clean success output, and
  exits `0`.
- Verbose mode is controlled by `GIT_HOOK_VERBOSE` from the shared git-hooks
  environment. It prints the command and streams native CodeGraph output.

## Failure Modes

- Skips with an install hint when `codegraph` is unavailable:
  `npm install -g @colbymchenry/codegraph`.
- Returns the CodeGraph exit code and capped diagnostics on failure.

## Related Checks

- The `golang` and `react-vite` profiles run this check last in `pre-push` so
  language tests and lint fail before local index maintenance starts.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/dev/codegraph-build-index_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips with an install hint when missing |
| Existing | `git-hooks` | initializes and builds the index when missing |
| Existing | `git-hooks` | rebuilds the index when initialized |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | does not pass pre-push stdin to CodeGraph |
| Existing | `git-hooks` | streams native output in verbose mode |
| Existing | `git-hooks` | reports failure output and tool exit code |
