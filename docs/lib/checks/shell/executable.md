# `lib/checks/shell/executable.sh`

## Scope

Staged shell executable-bit consistency check for `pre-commit`.

## Behavior

- Intended for the opt-in `shell` profile, not the common baseline.
- Checks staged text `.sh`, `.bash`, and `.zsh` files.
- Does not require every shell file to be executable.
- Allows non-executable sourced fragments and config snippets.
- Fails only when a staged executable shell file lacks a supported shell
  shebang for `sh`, `bash`, or `zsh`.
- Reads staged file modes and contents from the Git index.

## Failure Modes

- Returns `1` when an executable shell file has no supported shell shebang.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/shell/executable_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | skips without staged shell files |
| Existing | `git-hooks` | allows non-executable shell fragments |
| Existing | `git-hooks` | passes executable shell files with shell shebang |
| Existing | `git-hooks` | fails executable shell files without shell shebang |
| Existing | `git-hooks` | checks `.zsh` executable files |
| Existing | `git-hooks` | skips staged binary shell files |
