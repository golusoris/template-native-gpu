#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
#
# scripts/ci/advisory-exceptions_test.sh — planted cases for the advisory
# exception check: each defective list must be refused, a valid one accepted.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root
check="$repo_root/scripts/ci/advisory-exceptions.py"
readonly check

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/project-advisory-test.XXXXXX")"
readonly work_dir
trap 'rm -rf "$work_dir"' EXIT

# Dates relative to today, computed portably (BSD date has no -d).
day() {
  python3 -c 'import datetime as d,sys; print((d.datetime.now(d.timezone.utc).date()+d.timedelta(days=int(sys.argv[1]))).isoformat())' "$1"
}

write() {
  local name="$1" until="$2" reason="$3"
  printf '[[IgnoredVulns]]\nid = "CVE-0000-0001"\nignoreUntil = %s\nreason = "%s"\n' \
    "$until" "$reason" >"$work_dir/$name.toml"
}

expect_failure() {
  local needle="$1" file="$2" output status=0
  set +e
  output="$(python3 "$check" "$file" 2>&1)"
  status=$?
  set -e
  if [[ $status -ne 1 ]]; then
    printf 'expected rc 1 for %s, got %d:\n%s\n' "$file" "$status" "$output" >&2
    exit 1
  fi
  if [[ "$output" != *"$needle"* ]]; then
    printf 'expected output for %s to contain %q, got:\n%s\n' "$file" "$needle" "$output" >&2
    exit 1
  fi
}

write expired "$(day -1)" 'Category C (10 days).'
write today "$(day 0)" 'Category C (10 days).'
write beyond "$(day 11)" 'Category C (10 days).'
write nocategory "$(day 5)" 'unreachable path'
printf '[[IgnoredVulns]]\nid = "CVE-0000-0001"\nreason = "Category C"\n' >"$work_dir/nountil.toml"
write valid "$(day 10)" 'Category C (10 days).'

expect_failure 'expired on' "$work_dir/expired.toml"
expect_failure 'expired on' "$work_dir/today.toml"
expect_failure 'beyond category C' "$work_dir/beyond.toml"
expect_failure 'names no category' "$work_dir/nocategory.toml"
expect_failure 'ignoreUntil missing' "$work_dir/nountil.toml"
python3 "$check" "$work_dir/valid.toml"
printf 'advisory exception check tests passed\n'
