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

# plant NAME HOOK_KEYS CODACY_BODY [TOP_KEYS]: a tree with one fragment and a
# README; HOOK_KEYS and TOP_KEYS are YAML lines for the hook and the config top.
plant() {
  local dir="$work_dir/$1"
  mkdir -p "$dir/changelog.d/fixed"
  printf -- '- fragment\n' >"$dir/changelog.d/fixed/a.md"
  printf '# readme\n' >"$dir/README.md"
  printf '%brepos:\n  - repo: https://github.com/DavidAnson/markdownlint-cli2\n    rev: v0.22.1\n    hooks:\n      - id: markdownlint-cli2\n%b' \
    "${4:-}" "$2" >"$dir/.pre-commit-config.yaml"
  printf '%b' "$3" >"$dir/.codacy.yml"
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
hook="        exclude: '^subprojects/|^changelog.d/|^docs/adr/_index_fragments/'\n"
no_fragments='---\nengines:\n  markdownlint:\n    exclude_paths:\n      - "subprojects/**"\n      - "docs/adr/_index_fragments/**"\n'

plant matching "$hook" "$matching"
plant global-exclude "$hook" "${no_fragments}exclude_paths:\n  - \"changelog.d/**\"\n"
plant top-level-exclude "        exclude: '^subprojects/|^docs/adr/_index_fragments/'\n" "$matching" "exclude: '^changelog.d/'\n"
plant codacy-lints-fragment "$hook" "$no_fragments"
plant codacy-skips-readme "$hook" "${matching}      - \"*.md\"\n"
plant global-skips-readme "$hook" "${matching}exclude_paths:\n  - \"README.md\"\n"
plant hook-without-exclude "" "$matching"
plant hook-empty-exclude "        exclude: ''\n" "$matching"
plant no-document-start "$hook" "${matching#---\\n}"
plant unsupported-glob "$hook" '---\nengines:\n  markdownlint:\n    exclude_paths:\n      - "{changelog.d,subprojects}/**"\n'
plant codacy-include-paths "$hook" "${matching}include_paths:\n  - \"changelog.d/keep.md\"\n"
plant hook-types-key "${hook}        types_or: [markdown]\n" "$matching"
plant hook-own-globs "${hook}        pass_filenames: false\n" "$matching"
plant hook-files "${hook}        files: '^docs/'\n" "$matching"
plant top-level-files "$hook" "$matching" "files: '^docs/'\n"
plant engine-not-mapping "$hook" '---\nexclude_paths:\n  - "subprojects/**"\n  - "changelog.d/**"\n  - "docs/adr/_index_fragments/**"\nengines:\n  markdownlint: []\n'
plant hook-not-mapping "${hook}      - null\n" "$matching"
plant repo-not-mapping "$hook" "$matching"
printf 'repos:\n  - null\n' >"$work_dir/repo-not-mapping/.pre-commit-config.yaml"

for accepted in matching global-exclude top-level-exclude; do
  python3 "$check" "$work_dir/$accepted"
done
expect_refusal codacy-lints-fragment 1 'changelog.d/fixed/a.md: pre-commit markdownlint skips it, Codacy lints it'
expect_refusal codacy-skips-readme 1 'README.md: Codacy skips it, pre-commit markdownlint lints it'
expect_refusal global-skips-readme 1 'README.md: Codacy skips it, pre-commit markdownlint lints it'
expect_refusal hook-without-exclude 1 'changelog.d/fixed/a.md: Codacy skips it, pre-commit markdownlint lints it'
expect_refusal hook-empty-exclude 1 'README.md: pre-commit markdownlint skips it, Codacy lints it'
expect_refusal no-document-start 2 "must start with a '---' line"
expect_refusal unsupported-glob 2 'unsupported glob'
expect_refusal codacy-include-paths 2 '.codacy.yml: unsupported key include_paths'
expect_refusal hook-types-key 2 'markdownlint-cli2 hook: unsupported key types_or'
expect_refusal hook-own-globs 2 'markdownlint-cli2 hook must pass filenames'
expect_refusal hook-files 1 'README.md: pre-commit markdownlint skips it, Codacy lints it'
expect_refusal top-level-files 1 'README.md: pre-commit markdownlint skips it, Codacy lints it'
expect_refusal engine-not-mapping 2 '.codacy.yml: engines.markdownlint must be a mapping'
expect_refusal hook-not-mapping 2 '.pre-commit-config.yaml: hooks must be a list of mappings'
expect_refusal repo-not-mapping 2 '.pre-commit-config.yaml: repos must be a list of mappings'
printf 'codacy config check: 3 accepted, 15 refused\n'
