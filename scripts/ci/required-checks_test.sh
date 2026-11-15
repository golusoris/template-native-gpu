#!/usr/bin/env bash
# scripts/ci/required-checks_test.sh — negative cases for required-checks.sh.
#
# Each case feeds planted check runs to the judge: defects it must refuse and
# clean sets it must accept.
#
# Usage:
#   scripts/ci/required-checks_test.sh

set -euo pipefail

judge="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/required-checks.sh"
readonly judge
readonly required=$'lint\nbuild'

run() {
  local runs="$1" allowed="$2"
  printf '%s\n' "$runs" | REQUIRED="$required" ALLOWED_SKIPS="$allowed" SELF=agg \
    HEAD_REF="${3:-}" HEAD_REPO="${4:-}" BASE_REPO="${5:-}" RELEASE_HEAD_SKIPS="${6:-}" \
    HEAD_AUTHOR_TYPE="${7:-}" "$judge"
}

expect_pass() {
  local label="$1"
  shift
  if ! run "$@" >/dev/null 2>&1; then
    printf 'FAIL %s: expected pass\n' "$label" >&2
    exit 1
  fi
}

expect_failure() {
  local label="$1" needle="$2" output status=0
  shift 2
  set +e
  output="$(run "$@" 2>&1)"
  status=$?
  set -e
  if [[ $status -eq 0 || "$output" != *"$needle"* ]]; then
    printf 'FAIL %s: expected failure with %q, got status %d:\n%s\n' "$label" "$needle" "$status" "$output" >&2
    exit 1
  fi
}

ok() { printf '{"name":"%s","status":"completed","conclusion":"success"}' "$1"; }
done_as() { printf '{"name":"%s","status":"completed","conclusion":"%s"}' "$1" "$2"; }

clean="$(ok lint)$(ok build)$(ok extra)"

expect_pass clean "$clean" ''
expect_pass 'self still running' "$clean"'{"name":"agg","status":"in_progress","conclusion":null}' ''
expect_pass 'named skip' "$(ok lint)$(ok build)$(done_as gpu skipped)" gpu

expect_failure 'skipped required job' 'lint: completed/skipped' "$(done_as lint skipped)$(ok build)" ''
expect_failure 'skipped unnamed job' 'extra: completed/skipped' "$(ok lint)$(ok build)$(done_as extra skipped)" gpu
expect_failure 'failed job' 'build: completed/failure' "$(ok lint)$(done_as build failure)" ''
expect_failure 'failed job on the skip list' 'gpu: completed/failure' "$clean$(done_as gpu failure)" gpu
expect_failure 'cancelled job' 'extra: completed/cancelled' "$(ok lint)$(ok build)$(done_as extra cancelled)" ''
expect_failure 'neutral job' 'extra: completed/neutral' "$(ok lint)$(ok build)$(done_as extra neutral)" ''
expect_failure 'job still running' 'extra: in_progress/none' "$(ok lint)$(ok build)"'{"name":"extra","status":"in_progress","conclusion":null}' ''
expect_failure 'required job missing' 'build: missing' "$(ok lint)$(ok extra)" ''
expect_failure 'no check runs' 'lint: missing' '' ''

release_ref=release-please--branches--main--components--project
release_skipped="$(ok lint)$(ok build)$(done_as CodeRabbit skipped)"
release_failed="$(ok lint)$(ok build)$(done_as CodeRabbit failure)"

expect_pass 'release head CodeRabbit skip' "$release_skipped" '' "$release_ref" o/r o/r CodeRabbit Bot
expect_pass 'release head combines skip lists' "$release_skipped$(done_as gpu skipped)" gpu "$release_ref" o/r o/r CodeRabbit Bot
expect_failure 'feature head CodeRabbit skip' 'CodeRabbit: completed/skipped' "$release_skipped" '' feat/x o/r o/r CodeRabbit Bot
expect_failure 'push event CodeRabbit skip' 'CodeRabbit: completed/skipped' "$release_skipped" '' '' '' o/r CodeRabbit Bot
expect_failure 'fork release head CodeRabbit skip' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" fork/r o/r CodeRabbit Bot
expect_failure 'prefixed release ref CodeRabbit skip' 'CodeRabbit: completed/skipped' "$release_skipped" '' xrelease-please--main o/r o/r CodeRabbit Bot
expect_failure 'single dash release ref CodeRabbit skip' 'CodeRabbit: completed/skipped' "$release_skipped" '' release-please-main o/r o/r CodeRabbit Bot
expect_failure 'release head CodeRabbit failure' 'CodeRabbit: completed/failure' "$release_failed" '' "$release_ref" o/r o/r CodeRabbit Bot
expect_failure 'feature head CodeRabbit failure' 'CodeRabbit: completed/failure' "$release_failed" '' feat/x o/r o/r CodeRabbit Bot
expect_failure 'release head extra skip' 'extra: completed/skipped' "$release_skipped$(done_as extra skipped)" '' "$release_ref" o/r o/r CodeRabbit Bot
expect_failure 'release head empty skip list' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" o/r o/r '' Bot
expect_failure 'release head empty repos' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" '' '' CodeRabbit Bot
expect_failure 'release head missing base repo' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" o/r '' CodeRabbit Bot
expect_failure 'release head CodeRabbit cancelled' 'CodeRabbit: completed/cancelled' "$(ok lint)$(ok build)$(done_as CodeRabbit cancelled)" '' "$release_ref" o/r o/r CodeRabbit Bot
expect_failure 'release head CodeRabbit neutral' 'CodeRabbit: completed/neutral' "$(ok lint)$(ok build)$(done_as CodeRabbit neutral)" '' "$release_ref" o/r o/r CodeRabbit Bot
expect_failure 'release head CodeRabbit running' 'CodeRabbit: in_progress/none' "$(ok lint)$(ok build)"'{"name":"CodeRabbit","status":"in_progress","conclusion":null}' '' "$release_ref" o/r o/r CodeRabbit Bot
expect_failure 'release head User author' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" o/r o/r CodeRabbit User
expect_failure 'release head empty author' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" o/r o/r CodeRabbit ''
expect_failure 'release head lowercase bot author' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" o/r o/r CodeRabbit bot
expect_failure 'release head Bots author' 'CodeRabbit: completed/skipped' "$release_skipped" '' "$release_ref" o/r o/r CodeRabbit Bots

set +e
printf '%s\n' "$clean" | REQUIRED='' SELF=agg "$judge" >/dev/null 2>&1
empty_status=$?
printf 'not json\n' | REQUIRED="$required" SELF=agg "$judge" >/dev/null 2>&1
json_status=$?
set -e
if [[ $empty_status -ne 2 ]]; then
  printf 'FAIL empty REQUIRED: expected status 2, got %d\n' "$empty_status" >&2
  exit 1
fi
if [[ $json_status -eq 0 ]]; then
  printf 'FAIL malformed input: expected failure\n' >&2
  exit 1
fi

printf 'required-checks policy tests passed\n'
