# `lib/checks/pmem/ref-footer.sh`

## Scope

Project Memory (`pmem`) reference footer validation for the `commit-msg`
phase.

## Behavior

- Intended for the opt-in Project Memory (`pmem`) profile, not the common
  baseline.
- Resolves the PMem CLI from `GIT_HOOK_PMEM_BIN` when set, otherwise from
  `pmem` on `PATH`.
- If no PMem CLI is available, warns that the pmem check is enabled but no CLI
  client was found, then skips.
- Uses `pmem info --repo --json --quiet` to read repo PMem config.
- If repo PMem config is absent, warns that no pmem config exists while the
  hook is enabled, then skips.
- Clears ambient `PMEM_PROJECT_ID` and `PMEM_PROJECT_KEY` before PMem CLI calls
  so repo config must come from the repository settings resolved by the CLI.
- Uses `project_id` from `pmem info --repo --json`; PMem project selector
  environment variables are not a repo-config source for this hook.
- Does not inspect `project_key`; resolving project keys to canonical
  project IDs is PMem CLI behavior, not hook behavior.
- Parses PMem JSON with `jq`. The hook does not trust raw substring matches
  from PMem output.
- Requires the commit message footer block to contain exactly one
  `Refs: <task-id>`.
- Validates every line in the trailing footer block before accepting the
  `Refs` footer.
- Validates task ID syntax locally: the ID must match
  `[A-Za-z0-9][A-Za-z0-9_-]*`.
- Temporarily requires the task ID to be at least 3 characters and less than 24
  characters. This should follow the PMem ID standard once finalized.
- Uses `pmem wi get --project-id <project-id> --id <task-id> --fields
  status,type --json --quiet` to fetch only the referenced work item fields the
  hook consumes.
- Rejects commits that reference work items with status `canceled`, `done`, or
  `closed`.
- Treats malformed PMem JSON, failed PMem commands, and missing or invalid
  required response fields as hook failures.
- Keeps passing output silent by default, including PMem advisory warnings.
- In verbose mode, emits a concise three-line PMem summary with project name,
  project ID, task ID, task type, and task status. It does not print raw PMem
  JSON responses.
- Ignores commented commit-template lines while parsing the trailing footer
  block.

## Failure Modes

- Returns `2` when the commit message file argument is missing.
- Returns `1` when the commit message file does not exist.
- Returns `0` when the PMem CLI is missing, after a warning.
- Returns `0` when repo PMem config is absent, after a warning.
- Returns `1` when `pmem info --repo --json` fails, reports active repo config
  without `project_id`, returns an invalid `project_id`, or returns malformed
  JSON.
- Returns `127` when PMem JSON must be parsed but `jq` is unavailable.
- Returns `1` when the required `Refs` footer is missing.
- Returns `1` when a `Refs` footer exists but its ID is malformed.
- Returns `1` when more than one `Refs` footer exists.
- Returns `1` when `pmem wi get --project-id <project-id> --id <task-id>
  --fields status,type --json` fails, omits `status`, returns an invalid
  `status`, or returns malformed JSON.
- Returns `1` when the referenced work item status is `canceled`, `done`, or
  `closed`.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/pmem/ref-footer_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips when the pmem CLI is missing |
| Existing | `git-hooks` | skips when repo PMem config is absent |
| Existing | `git-hooks` | ignores ambient pmem project selectors when probing repo config |
| Existing | `git-hooks` | passes when the `Refs` footer references an open task |
| Existing | `git-hooks` | rejects the old singular `Ref` footer |
| Existing | `git-hooks` | rejects non-trailer text after a valid `Refs` footer |
| Existing | `git-hooks` | rejects duplicate `Refs` footers before checking a single work item |
| Existing | `git-hooks` | suppresses pmem warnings on successful checks |
| Existing | `git-hooks` | uses the test pmem client when an ambient binary override exists |
| Existing | `git-hooks` | passes when `GIT_HOOK_PMEM_BIN` points at a local pmem client |
| Existing | `git-hooks` | reports a concise PMem summary without raw JSON in verbose mode |
| Existing | `git-hooks` | fails when `pmem info --repo --json` exits non-zero |
| Existing | `git-hooks` | fails when `pmem info --repo --json` returns an invalid project ID |
| Existing | `git-hooks` | fails when `pmem info --repo --json` returns malformed JSON containing an expected field |
| Existing | `git-hooks` | fails when repo PMem config is active but project ID is missing |
| Existing | `git-hooks` | fails when the task footer is missing |
| Existing | `git-hooks` | fails when the task ID is shorter than three characters |
| Existing | `git-hooks` | fails when the task ID has twenty-four characters |
| Existing | `git-hooks` | fails when the task ID contains unsupported characters |
| Existing | `git-hooks` | rejects a task ID outside the footer block |
| Existing | `git-hooks` | fails when `pmem wi get` exits non-zero |
| Existing | `git-hooks` | fails when `pmem wi get` returns an invalid task status |
| Existing | `git-hooks` | fails when `pmem wi get` omits task status |
| Existing | `git-hooks` | fails when `pmem wi get` returns malformed JSON containing an expected field |
| Existing | `git-hooks` | fails when the task status is `canceled` |
| Existing | `git-hooks` | fails when the task status is `done` |
| Existing | `git-hooks` | fails when the task status is `closed` |
| Existing | `git-hooks` | rejects missing commit message file argument |
