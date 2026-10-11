#!/usr/bin/env bash
# scripts/ci/semgrep-scan.sh — run semgrep from the pinned container image.
#
# Scans ROOT (default: the repository) with the project rules in .semgrep.yml
# plus the p/c and p/cwe-top-25 packs; any finding fails the scan. Version and
# image digest come from tools/tool-versions.env.
#
# Usage:
#   scripts/ci/semgrep-scan.sh [ROOT]

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root

if (($# > 1)); then
  printf 'usage: %s [ROOT]\n' "${0##*/}" >&2
  exit 2
fi

if (($# == 1)); then
  root="$(cd "$1" && pwd)"
else
  root="$repo_root"
fi
readonly root

# shellcheck source=/dev/null
. "$repo_root/tools/tool-versions.env"

if [[ ! "$SEMGREP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'invalid SEMGREP_VERSION: %s\n' "$SEMGREP_VERSION" >&2
  exit 1
fi

if [[ ! "$SEMGREP_IMAGE_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  printf 'invalid SEMGREP_IMAGE_DIGEST: %s\n' "$SEMGREP_IMAGE_DIGEST" >&2
  exit 1
fi

# Registry default is a pull-through mirror of Docker Hub serving the same digests;
# hosted runners hit the anonymous Docker Hub pull limit.
image="${SCAN_IMAGE_REGISTRY:-mirror.gcr.io}/semgrep/semgrep:${SEMGREP_VERSION}@${SEMGREP_IMAGE_DIGEST}"
exec "${DOCKER_BIN:-docker}" run --rm \
  -v "$root:/src:ro" -v "$repo_root/.semgrep.yml:/rules/semgrep.yml:ro" -w /src \
  "$image" semgrep --error --metrics=off \
  --config /rules/semgrep.yml --config p/c --config p/cwe-top-25 .
