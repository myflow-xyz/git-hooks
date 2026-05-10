# `install.sh`

## Scope

Install this Git hooks runtime into user XDG config.

This script is self-contained and owns its small link/check/fix behavior
directly.

## Usage

```sh
install.sh [--check|--fix-links]
```

## Behavior

- Requires Git >= 2.9.0 because repo setup uses `core.hooksPath`.
- Resolves the source runtime from the checkout directory containing
  `install.sh`.
- Resolves the source runtime through physical paths, so running
  `$XDG_CONFIG_HOME/git-hooks/install.sh --check` or `--fix-links` does not
  compare the installed symlink against itself.
- Fails with a clear dependency error if `readlink` is not available while
  inspecting an existing symlink.
- Uses `${XDG_CONFIG_HOME:-$HOME/.config}/git-hooks` as the target.
- Default mode creates the target symlink when it is missing.
- Default mode fails fast when the target exists but points elsewhere.
- `--check` verifies the target symlink and does not modify files.
- `--fix-links` explicitly repairs wrong symlinks.
- `--fix-links` backs up conflicting real files or directories to
  `<target>.<YYYYmmddHHMMSS>.bak` before relinking.

## Output Policy

Output is short and machine-readable enough for humans or LLM agents:

- Success: `git-hooks: installed; target=<path>; source=<path>`
- Check success: `git-hooks: check ok; target=<path>; source=<path>`
- Failure: `git-hooks: error: <reason>`

## Test Cases

Run only this script's tests:

- `shellspec test/install_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | installs the runtime into XDG config home |
| Existing | `git-hooks` | rejects install when `git` is missing |
| Existing | `git-hooks` | rejects install when Git version cannot be detected |
| Existing | `git-hooks` | rejects install when Git is too old for `core.hooksPath` |
| Existing | `git-hooks` | checks an existing XDG runtime symlink |
| Existing | `git-hooks` | checks successfully when invoked through the installed XDG symlink |
| Existing | `git-hooks` | does not rewrite the runtime link when fix is invoked through the installed XDG symlink |
| Existing | `git-hooks` | fails default install when target points elsewhere |
| Existing | `git-hooks` | suggests fix-links when default install finds a real target |
| Existing | `git-hooks` | fixes a wrong XDG runtime symlink explicitly |
| Existing | `git-hooks` | backs up a real target before fixing |
