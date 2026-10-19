#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
#
# scripts/ci/helm-chart-check.sh — verify helm chart schemas, vendor resource
# keys, and strict linting.
#
# Usage:
#   scripts/ci/helm-chart-check.sh [CHART_DIR]

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root
chart_dir="${1:-$repo_root/deploy/helm/project}"
readonly chart_dir

if [[ ! -d "$chart_dir" ]]; then
  printf 'error: chart directory not found: %s\n' "$chart_dir" >&2
  exit 1
fi

HELM="${HELM:-helm}"
if ! command -v "$HELM" >/dev/null 2>&1; then
  printf 'error: helm binary not found: %s\n' "$HELM" >&2
  exit 1
fi

# 1. Render default values: must pass.
if ! "$HELM" template t "$chart_dir" >/dev/null 2>&1; then
  printf 'error: default values failed to render\n' >&2
  exit 1
fi
printf 'PASS default values render\n'

# 2. For vendor in nvidia amd intel: render must pass and output must contain
# expected key and no other vendor key.
readonly -a vendors=("nvidia" "amd" "intel")
readonly -a all_vendor_keys=("nvidia.com/gpu" "amd.com/gpu" "gpu.intel.com/i915")

for v in "${vendors[@]}"; do
  case "$v" in
    nvidia) expected_key="nvidia.com/gpu" ;;
    amd) expected_key="amd.com/gpu" ;;
    intel) expected_key="gpu.intel.com/i915" ;;
    *)
      printf 'error: unhandled vendor: %s\n' "$v" >&2
      exit 1
      ;;
  esac

  set +e
  out="$("$HELM" template t "$chart_dir" --set gpu.enabled=true --set "gpu.vendor=$v" 2>&1)"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    printf 'error: helm template failed for vendor %s (rc %d):\n%s\n' "$v" "$rc" "$out" >&2
    exit 1
  fi

  if [[ "$out" != *"$expected_key"* ]]; then
    printf 'error: output for vendor %s missing expected key %s\n' "$v" "$expected_key" >&2
    exit 1
  fi

  for other_key in "${all_vendor_keys[@]}"; do
    if [[ "$other_key" != "$expected_key" && "$out" == *"$other_key"* ]]; then
      printf 'error: output for vendor %s unexpectedly contained other vendor key %s\n' "$v" "$other_key" >&2
      exit 1
    fi
  done

  printf 'PASS vendor %s renders %s\n' "$v" "$expected_key"
done

# 3. vendor=unknown: helm template must FAIL and stderr contain "gpu/vendor".
set +e
unknown_out="$("$HELM" template t "$chart_dir" --set gpu.enabled=true --set gpu.vendor=unknown 2>&1)"
unknown_rc=$?
set -e

if [[ $unknown_rc -eq 0 ]]; then
  printf 'error: vendor=unknown unexpectedly succeeded\n' >&2
  exit 1
fi

if [[ "$unknown_out" != *"gpu/vendor"* ]]; then
  printf 'error: vendor=unknown failed but output did not contain "gpu/vendor":\n%s\n' "$unknown_out" >&2
  exit 1
fi
printf 'PASS vendor unknown rejected by schema\n'

# 4. helm lint deploy/helm/project --strict must pass.
if ! "$HELM" lint "$chart_dir" --strict >/dev/null 2>&1; then
  printf 'error: helm lint --strict failed\n' >&2
  exit 1
fi
printf 'PASS helm lint --strict\n'
