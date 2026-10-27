#!/usr/bin/env bash
# scripts/ci/security-scans_test.sh — negative cases for the security scan scripts.
#
# Each mode plants a defect the gate must refuse and a clean case it must
# accept. gitleaks-scan needs the pinned gitleaks on PATH.
#
# Usage:
#   scripts/ci/security-scans_test.sh semgrep|gitleaks-scan

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root

if (($# != 1)) || [[ ! "$1" =~ ^(semgrep|gitleaks-scan)$ ]]; then
  printf 'usage: %s semgrep|gitleaks-scan\n' "${0##*/}" >&2
  exit 2
fi
mode="$1"
readonly mode

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/project-security-test.XXXXXX")"
readonly work_dir
trap 'rm -rf "$work_dir"' EXIT

expect_failure() {
  local needle="$1"
  shift
  local output status=0
  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    printf 'expected command to fail, but exited 0: %s\noutput:\n%s\n' "$*" "$output" >&2
    exit 1
  fi
  if [[ "$output" != *"$needle"* ]]; then
    printf 'expected error output to contain %q\ngot:\n%s\n' "$needle" "$output" >&2
    exit 1
  fi
}

case "$mode" in
  semgrep)
    test_dir="$work_dir/semgrep-test"
    mkdir -p "$test_dir/planted" "$test_dir/clean"
    cat >"$test_dir/planted/planted.c" <<'EOF'
#include <stdlib.h>
int planted(void) { return rand(); }
EOF
    cat >"$test_dir/clean/clean.c" <<'EOF'
int clean(void) { return 0; }
EOF
    expect_failure 'no-system-rand' "$repo_root/scripts/ci/semgrep-scan.sh" "$test_dir/planted"
    "$repo_root/scripts/ci/semgrep-scan.sh" "$test_dir/clean"
    printf 'semgrep scan policy tests passed\n'
    ;;
  gitleaks-scan)
    mkdir -p "$work_dir/planted" "$work_dir/clean"
    # Assembled at run time so this script does not match the rule itself.
    printf -- '-----BEGIN ENCRYPTED %s PRIVATE KEY-----\n' COSIGN >"$work_dir/planted/key.txt"
    printf 'int clean(void) { return 0; }\n' >"$work_dir/clean/clean.c"
    expect_failure 'no-cosign-private-key' gitleaks dir "$work_dir/planted" \
      -c "$repo_root/.gitleaks.toml" --redact --no-banner --verbose
    gitleaks dir "$work_dir/clean" -c "$repo_root/.gitleaks.toml" --redact --no-banner
    printf 'gitleaks scan policy tests passed\n'
    ;;
esac
