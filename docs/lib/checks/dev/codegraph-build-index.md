# `lib/checks/dev/codegraph-build-index.sh`

## Scope

Development-only CodeGraph index initialization and rebuild check for
`pre-push`.

## Behavior

- Intended for opt-in development profiles, not the common baseline.
- Uses user-level `codegraph` from `PATH`.
- Runs from the repository root after the shared hook environment has loaded.
- Treats `.codegraph/codegraph.db` as the initialization marker.
- When the repository is not initialized and `.codegraph/` does not exist,
  ensures `.codegraph/` is ignored before running `codegraph init -i .`.
- The ignore step does not edit tracked `.gitignore`. If Git does not already
  ignore `.codegraph/`, the hook appends `.codegraph/` to `.git/info/exclude`.
- When `.codegraph/` already exists, the hook keeps ignore rules as-is.
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
- Fails before initialization if `.codegraph/` is not already ignored and the
  hook cannot update `.git/info/exclude`.
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
| Existing | `git-hooks` | adds `.codegraph/` to local exclude before init |
| Existing | `git-hooks` | keeps existing `.codegraph/` ignore policy |
| Existing | `git-hooks` | fails before init when local exclude cannot update |
| Existing | `git-hooks` | initializes and builds the index when missing |
| Existing | `git-hooks` | rebuilds the index when initialized |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | does not pass pre-push stdin to CodeGraph |
| Existing | `git-hooks` | streams native output in verbose mode |
| Existing | `git-hooks` | reports failure output and tool exit code |
