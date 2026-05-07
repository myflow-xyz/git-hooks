# `lib/checks/shell/_files.sh`

## Scope

Shared shell file discovery helpers for checks under `lib/checks/shell`.

## Behavior

- Discovers staged text shell files by extension only: `.sh`, `.bash`, `.zsh`.
- Provides a narrower `.sh` and `.bash` staged file list for tools that should
  not process zsh syntax.
- Excludes ShellSpec `*_spec.sh` files from the sh/bash static-tool list because
  ShellSpec DSL files are validated by ShellSpec, not by `shfmt` or ShellCheck.
- Reads staged file modes from the Git index.
- Reads first lines from staged blobs, not the working tree.
- Detects shell shebangs for `sh`, `bash`, and `zsh`, including common
  `/usr/bin/env` forms.
- Discovers ShellSpec projects from tracked `.shellspec` files anywhere in the
  repository.

## Failure Modes

- Returns usage errors for helper functions called with invalid arguments.
- ShellSpec project discovery ignores untracked `.shellspec` files.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/shell/files_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | finds staged `.sh`, `.bash`, and `.zsh` text files |
| Existing | `git-hooks` | excludes `.zsh` from sh/bash tool input |
| Existing | `git-hooks` | excludes ShellSpec files from sh/bash tool input |
| Existing | `git-hooks` | skips staged binary shell files |
| Existing | `git-hooks` | detects staged executable file mode |
| Existing | `git-hooks` | detects dialect from shebang or extension |
| Existing | `git-hooks` | discovers tracked ShellSpec directories |
