# `lib/checks/pmem/ref-footer.sh`

## Scope

Project Memory (`pmem`) reference footer validation for the `commit-msg`
phase.

## Behavior

- Intended for the opt-in Project Memory (`pmem`) profile, not the common
  baseline.
- Requires the target repository to contain `.pmem/env`.
- Reads `PMEM_PROJECT_KEY=<key>` from `.pmem/env`.
- Requires the commit message footer block to contain `Ref: <id>`.
- Accepts project keys matching `[A-Za-z0-9][A-Za-z0-9_-]*`.
- Performs format-only ID validation today: the ref ID must match
  `[A-Za-z0-9][A-Za-z0-9_-]*`.
- Temporarily requires the ref ID to be at least 3 characters and less than 24
  characters. This should follow the PMem ID standard once finalized.
- Ignores commented commit-template lines while parsing the trailing footer
  block.

## Failure Modes

- Returns `2` when the commit message file argument is missing.
- Returns `1` when the commit message file does not exist.
- Returns `1` when `.pmem/env` is missing.
- Returns `1` when `PMEM_PROJECT_KEY` is missing or invalid.
- Returns `1` when the required ref footer is missing.
- Returns `1` when a ref footer exists but its ID is malformed.

## Future Tracking

Real validity requires a Project Memory lookup. Add Project Memory client
integration so the hook can confirm the referenced ticket, spec, task, issue, or
other PMem record exists under `PMEM_PROJECT_KEY` and is acceptable for commit
association. That lookup should eventually be a hard requirement; until then
this check is deliberately limited to local syntax and project-key gate
validation.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/pmem/ref-footer_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | passes when a ref footer includes a standalone ref ID |
| Existing | `git-hooks` | passes when a ref footer uses an exported quoted project key gate |
| Existing | `git-hooks` | fails when pmem env is missing |
| Existing | `git-hooks` | fails when the project key is missing |
| Existing | `git-hooks` | fails when the project key is invalid |
| Existing | `git-hooks` | fails when the ref footer is missing |
| Existing | `git-hooks` | passes when the ref footer ID is independent from the project key |
| Existing | `git-hooks` | fails when the ref ID is shorter than three characters |
| Existing | `git-hooks` | fails when the ref ID has twenty-four characters |
| Existing | `git-hooks` | fails when the ref ID contains unsupported characters |
| Existing | `git-hooks` | rejects a ref ID outside the footer block |
| Existing | `git-hooks` | rejects missing commit message file argument |
