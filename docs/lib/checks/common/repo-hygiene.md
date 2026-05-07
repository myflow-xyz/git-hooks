# `lib/checks/common/repo-hygiene.sh`

## Scope

Verbose-only repository hygiene recommendation check for `pre-push`.

## Behavior

- Always exits successfully; this check is advisory, not policy enforcement.
- Produces no output unless `GIT_HOOK_VERBOSE=1` or `true`.
- Recommends `.gitattributes` when missing.
- Recommends an active `.gitattributes` LF policy when no non-comment line
  contains `eol=lf`.
- Recommends `.gitignore` when missing.
- Recommends `.editorconfig` when missing.
- Uses repository-root files only.

Recommended baseline:

```gitattributes
* text=auto eol=lf
```

Recommended editor baseline:

```editorconfig
[*]
end_of_line = lf
insert_final_newline = true
```

## Failure Modes

- None for missing recommended files or settings.
- Returns `1` only when the check cannot enter the Git repository root.

## Test Cases

Run only this script's tests:

- `shellspec test/checks/common/repo-hygiene_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | stays silent in quiet mode |
| Existing | `git-hooks` | recommends missing repo hygiene files in verbose mode |
| Existing | `git-hooks` | recommends LF policy when `.gitattributes` lacks active `eol=lf` |
| Existing | `git-hooks` | treats commented `eol=lf` as inactive |
| Existing | `git-hooks` | reports recommended files present in verbose mode |
| Existing | `git-hooks` | checks repo-root files when run from a subdirectory |
