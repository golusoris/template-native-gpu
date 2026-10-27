#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
#
# scripts/ci/install-helm.sh — install the pinned helm release binary.
#
# The binary is installed only after its archive matches the SHA-256 recorded
# in tools/tool-versions.env.
#
# Usage:
#   scripts/ci/install-helm.sh <install-dir>

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root
readonly release_origin='https://get.helm.sh'
readonly max_archive_bytes=$((64 << 20))
readonly download_timeout_seconds=120

if (($# != 1)) || [[ -z "$1" ]]; then
  printf 'usage: %s <install-dir>\n' "${0##*/}" >&2
  exit 2
fi
install_dir="$1"
readonly install_dir

# shellcheck source=/dev/null
. "$repo_root/tools/tool-versions.env"

# Sourced from plurano/horistes actions/verified-download; the workflow step passes its path.
# shellcheck source=/dev/null
. "${VERIFIED_DOWNLOAD_LIB:?set VERIFIED_DOWNLOAD_LIB from plurano/horistes actions/verified-download}"

if [[ ! "$HELM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'invalid HELM_VERSION: %s\n' "$HELM_VERSION" >&2
  exit 1
fi
platform="$(uname -s)/$(uname -m)"
case "$platform" in
  Linux/x86_64)
    asset="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
    expected_digest="$HELM_LINUX_X64_SHA256"
    ;;
  *)
    # CI installs helm on hosted Linux x64 only.
    printf 'no pinned helm archive digest for %s\n' "$platform" >&2
    exit 1
    ;;
esac
if [[ ! "$expected_digest" =~ ^[0-9a-f]{64}$ ]]; then
  printf 'invalid pinned helm digest: %s\n' "$expected_digest" >&2
  exit 1
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/project-helm.XXXXXX")"
readonly work_dir
trap 'rm -rf "$work_dir"' EXIT

archive="$work_dir/$asset"
fetch_verified "$release_origin/$asset" "$expected_digest" \
  "$max_archive_bytes" "$download_timeout_seconds" "$archive"

tar -xzf "$archive" -C "$work_dir" --no-same-owner linux-amd64/helm
if [[ -L "$work_dir/linux-amd64/helm" || ! -f "$work_dir/linux-amd64/helm" ]]; then
  printf 'helm archive does not contain a regular helm binary\n' >&2
  exit 1
fi
installed_version="$("$work_dir/linux-amd64/helm" version --template='{{.Version}}')"
if [[ "$installed_version" != "v$HELM_VERSION" && "$installed_version" != "$HELM_VERSION" ]]; then
  printf 'helm reports version %s, want %s\n' "$installed_version" "$HELM_VERSION" >&2
  exit 1
fi

install -d "$install_dir"
install -m 0755 "$work_dir/linux-amd64/helm" "$install_dir/helm"
printf 'installed verified helm %s: %s\n' "$HELM_VERSION" "$install_dir/helm"
