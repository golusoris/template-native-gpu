#!/usr/bin/env bash
# scripts/ci/trivy-scan.sh — trivy filesystem scan from the pinned container image.
#
# Writes a SARIF report for the code-scanning dashboard. Reporting only: findings
# do not fail the scan. Version and image digest come from
# tools/tool-versions.env.
#
# Usage:
#   scripts/ci/trivy-scan.sh SARIF_OUTPUT

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root

if (($# != 1)) || [[ -z "$1" ]]; then
  printf 'usage: %s SARIF_OUTPUT\n' "${0##*/}" >&2
  exit 2
fi

sarif_output="$1"
out_dir="$(dirname "$sarif_output")"
out_name="$(basename "$sarif_output")"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
readonly out_dir out_name

# shellcheck source=/dev/null
. "$repo_root/tools/tool-versions.env"

if [[ ! "$TRIVY_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'invalid TRIVY_VERSION: %s\n' "$TRIVY_VERSION" >&2
  exit 1
fi

if [[ ! "$TRIVY_IMAGE_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  printf 'invalid TRIVY_IMAGE_DIGEST: %s\n' "$TRIVY_IMAGE_DIGEST" >&2
  exit 1
fi

# Registry default is a pull-through mirror of Docker Hub serving the same digests;
# hosted runners hit the anonymous Docker Hub pull limit.
image="${SCAN_IMAGE_REGISTRY:-mirror.gcr.io}/aquasec/trivy:${TRIVY_VERSION}@${TRIVY_IMAGE_DIGEST}"
"${DOCKER_BIN:-docker}" run --rm \
  -v "$repo_root:/src:ro" -v "$out_dir:/out" -w /src \
  "$image" fs --scanners vuln,secret,misconfig --config-data .config/trivy \
  --format sarif --output "/out/$out_name" --skip-version-check .
