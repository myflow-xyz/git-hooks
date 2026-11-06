# `lib/checks/golang/go-test-race.sh`

## Scope

Independent, opt-in Go race check for `pre-push`.

## Behavior

- Enable with `GIT_HOOK_PRE_PUSH_EXTRA_CHECKS="golang/go-test-race"`.
- Uses the same module selection, environment, cache preparation, output, and short-mode policy as `golang/go-test`.
- Runs `go test -race -count=1 ./...`; adds `-short` when `GIT_HOOK_GO_TEST_SHORT=1`.
- Does not alter the default Go profile or replace its ordinary test pass.
- Requires a Go platform that supports the race detector. Go reports unsupported platforms and missing runtime/compiler prerequisites, including cgo where the selected platform requires it.
- Missing Go warns and skips, consistent with the optional-tool policy.
- Any executed command failure, including an unsupported environment, rejects the push with the original exit status and useful diagnostics.

## Test Cases

- `shellspec test/checks/golang/go-test-race_spec.sh`

| Status | Environment | Scenario |
| --- | --- | --- |
| Existing | `git-hooks` | runs fresh race tests without changing the default profile |
| Existing | `git-hooks` | honors short mode and configured module selection |
| Existing | `git-hooks` | preserves race and unsupported-environment failures |
