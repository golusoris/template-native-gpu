#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
#
# scripts/ci/helm-chart-check_test.sh — planted cases for the helm chart
# check: each defective chart must be refused, a valid one accepted.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root
check="$repo_root/scripts/ci/helm-chart-check.sh"
readonly check
chart_src="$repo_root/deploy/helm/project"
readonly chart_src

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/project-helm-test.XXXXXX")"
readonly work_dir
trap 'rm -rf "$work_dir"' EXIT

expect_failure() {
  local needle="$1" chart="$2" output status=0
  set +e
  output="$(bash "$check" "$chart" 2>&1)"
  status=$?
  set -e
  if [[ $status -ne 1 ]]; then
    printf 'expected rc 1 for %s, got %d:\n%s\n' "$chart" "$status" "$output" >&2
    exit 1
  fi
  if [[ "$output" != *"$needle"* ]]; then
    printf 'expected output for %s to contain %q, got:\n%s\n' "$chart" "$needle" "$output" >&2
    exit 1
  fi
}

# (a) remove "unknown"-guard by deleting the enum from values.schema.json copy
cp -r "$chart_src" "$work_dir/no-enum"
python3 -c 'import pathlib, sys; p = pathlib.Path(sys.argv[1]); p.write_text(p.read_text(encoding="utf-8").replace(sys.argv[2], sys.argv[3]), encoding="utf-8")' \
  "$work_dir/no-enum/values.schema.json" ', "enum": ["nvidia", "amd", "intel"]' ''
if grep -q 'nvidia' "$work_dir/no-enum/values.schema.json"; then
  printf 'failed to remove vendor enum from test schema\n' >&2
  exit 1
fi
expect_failure 'vendor=unknown' "$work_dir/no-enum"

# (b) break _helpers.tpl amd mapping (amd.com/gpu -> nvidia.com/gpu)
cp -r "$chart_src" "$work_dir/broken-helpers"
python3 -c 'import pathlib, sys; p = pathlib.Path(sys.argv[1]); p.write_text(p.read_text(encoding="utf-8").replace(sys.argv[2], sys.argv[3]), encoding="utf-8")' \
  "$work_dir/broken-helpers/templates/_helpers.tpl" 'amd.com/gpu' 'nvidia.com/gpu'
if grep -q 'amd\.com/gpu' "$work_dir/broken-helpers/templates/_helpers.tpl"; then
  printf 'failed to replace amd.com/gpu in test _helpers.tpl\n' >&2
  exit 1
fi
expect_failure 'amd' "$work_dir/broken-helpers"

# (c) unmodified copy -> must pass
cp -r "$chart_src" "$work_dir/valid"
bash "$check" "$work_dir/valid"

printf 'helm chart check tests passed\n'
