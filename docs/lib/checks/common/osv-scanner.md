# `lib/checks/common/osv-scanner.sh`

## Scope

Cross-ecosystem dependency vulnerability scan for `pre-push`.

## Behavior

- Reusable common check enabled by the `react-vite`, `golang`, and `python`
  profiles, not by the common baseline.
- Uses a local `osv-scanner` executable from `PATH`.
- Runs
  `osv-scanner scan source --format markdown --verbosity error --recursive .`
  from the repository root. The explicit source subcommand documents intent,
  and `.` keeps reported source paths relative to the repository.
- Clears hook runtime and Git local environment variables before invoking the
  scanner.
- Captures output and keeps successful scans silent.
- When vulnerabilities are found, prints Markdown results to stderr, capped at
  120 lines, and returns exit `1`.
- When `GIT_HOOK_VERBOSE=1`, prints the command and streams native scanner
  output.

## Failure Modes

- Warns and exits `0` when `osv-scanner` is missing or not executable. The
  warning includes both the source install command and project home page:
  `go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest` and
  <https://github.com/google/osv-scanner>.
- Treats exit `1` as detected vulnerabilities.
- Returns every other non-zero scanner status as an operational failure,
  including exit `128` when no packages are found.
- Prints captured non-zero output, capped at 120 lines.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/osv-scanner_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips with install guidance when the scanner is missing |
| Existing | `git-hooks` | skips with install guidance when the scanner is not executable |
| Existing | `git-hooks` | runs a recursive source scan with Markdown output selected |
| Existing | `git-hooks` | keeps clean success silent |
| Existing | `git-hooks` | streams native output in verbose mode |
| Existing | `git-hooks` | prints Markdown results and returns exit `1` for vulnerabilities |
| Existing | `git-hooks` | reports operational failures and preserves the scanner status |
