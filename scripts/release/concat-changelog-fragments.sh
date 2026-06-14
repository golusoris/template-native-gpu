#!/usr/bin/env bash
# Concatenate per-PR changelog fragments under changelog.d/<section>/*.md into a
# rendered Keep-a-Changelog "Unreleased" body (printed to stdout).
#
# Sections are emitted in Keep-a-Changelog order:
#   Added -> Changed -> Deprecated -> Removed -> Fixed -> Security
# Each fragment is a stand-alone Markdown bullet.
#
# release-please owns the real CHANGELOG.md at release time; this script is for
# previewing the pending notes and (with --check) gating that fragments exist.
#
# Usage:
#   scripts/release/concat-changelog-fragments.sh           # print preview
#   scripts/release/concat-changelog-fragments.sh --check   # exit 1 if no fragments
#
# Copyright 2026 The PROJECT Authors
# SPDX-License-Identifier: BSD-2-Clause-Patent
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
FRAG_ROOT="$REPO_ROOT/changelog.d"

SECTIONS=(added changed deprecated removed fixed security)
declare -A TITLES=(
    [added]=Added [changed]=Changed [deprecated]=Deprecated
    [removed]=Removed [fixed]=Fixed [security]=Security
)

mode="${1:-print}"

render() {
    local any=0
    printf '## [Unreleased]\n\n'
    for sec in "${SECTIONS[@]}"; do
        local dir="$FRAG_ROOT/$sec"
        [ -d "$dir" ] || continue
        local frags=()
        for f in "$dir"/*.md; do
            [ -e "$f" ] || continue
            case "$(basename "$f")" in README.md) continue ;; esac
            frags+=("$f")
        done
        [ "${#frags[@]}" -eq 0 ] && continue
        any=1
        printf '### %s\n\n' "${TITLES[$sec]}"
        for f in "${frags[@]}"; do
            cat "$f"
            printf '\n'
        done
        printf '\n'
    done
    return $((any == 1 ? 0 : 1))
}

if [ "$mode" = "--check" ]; then
    if render >/dev/null; then
        echo "changelog: fragments present" >&2
        exit 0
    else
        echo "changelog: no fragments under changelog.d/<section>/ — add one for user-facing changes" >&2
        exit 1
    fi
fi

render || echo "_(no pending fragments)_"
