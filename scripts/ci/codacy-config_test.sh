#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
#
# scripts/ci/codacy-config_test.sh — planted cases for the Codacy markdownlint
# parity check: each drifted or unreadable configuration must be refused, a
# matching one accepted.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root
check="$repo_root/scripts/ci/codacy-config.py"
readonly check

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/project-codacy-test.XXXXXX")"
readonly work_dir
trap 'rm -rf "$work_dir"' EXIT

# plant NAME HOOK_EXCLUDE CODACY_BODY: a repository with one tracked fragment and a README.
plant() {
  local dir="$work_dir/$1"
  mkdir -p "$dir/changelog.d/fixed"
  printf -- '- fragment\n' >"$dir/changelog.d/fixed/a.md"
  printf '# readme\n' >"$dir/README.md"
  printf 'repos:\n  - repo: https://github.com/DavidAnson/markdownlint-cli2\n    rev: v0.22.1\n    hooks:\n      - id: markdownlint-cli2\n        exclude: %s\n' \
    "$2" >"$dir/.pre-commit-config.yaml"
  printf '%b' "$3" >"$dir/.codacy.yml"
  git -C "$dir" init -q
  git -C "$dir" add .
}

expect_refusal() {
  local name="$1" status="$2" needle="$3" output rc=0
  set +e
  output="$(python3 "$check" "$work_dir/$name" 2>&1)"
  rc=$?
  set -e
  if [[ $rc -ne $status ]]; then
    printf 'expected rc %d for %s, got %d:\n%s\n' "$status" "$name" "$rc" "$output" >&2
    exit 1
  fi
  if [[ "$output" != *"$needle"* ]]; then
    printf 'expected output for %s to contain %q, got:\n%s\n' "$name" "$needle" "$output" >&2
    exit 1
  fi
}

matching='---\nengines:\n  markdownlint:\n    exclude_paths:\n      - "subprojects/**"\n      - "changelog.d/**"\n      - "docs/adr/_index_fragments/**"\n'
hook="'^subprojects/|^changelog.d/|^docs/adr/_index_fragments/'"

plant matching "$hook" "$matching"
plant codacy-lints-fragment "$hook" '---\nengines:\n  markdownlint:\n    exclude_paths:\n      - "subprojects/**"\n      - "docs/adr/_index_fragments/**"\n'
plant codacy-skips-readme "$hook" "${matching}      - \"*.md\"\n"
plant no-document-start "$hook" "${matching#---\\n}"
plant unsupported-glob "$hook" '---\nengines:\n  markdownlint:\n    exclude_paths:\n      - "{changelog.d,subprojects}/**"\n'

python3 "$check" "$work_dir/matching"
expect_refusal codacy-lints-fragment 1 'changelog.d/fixed/a.md: pre-commit markdownlint skips it, Codacy lints it'
expect_refusal codacy-skips-readme 1 'README.md: Codacy skips it, pre-commit markdownlint lints it'
expect_refusal no-document-start 2 "must start with a '---' line"
expect_refusal unsupported-glob 2 'unsupported glob'
printf 'codacy config check: 1 accepted, 4 refused\n'
