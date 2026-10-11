#!/usr/bin/env bash
# scripts/adr/next-free.sh — print the next available ADR number.
#
# Scans docs/adr/ for NNNN-*.md files and prints the next free 4-digit number.
# Reserved: 0000 is the template.
#
# Usage:
#   scripts/adr/next-free.sh              # -> e.g. "0005"
#
# TEMPLATE: this is the simple single-tree version. For parallel-agent /
# multi-branch collision avoidance, extend it to also consult origin branches +
# a .git/adr-claims/ side-file registry (see the upstream vmaf script this is
# adapted from).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ADR_DIR="$(cd "$HERE/../../docs/adr" && pwd)"

max=0
for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  num="${base%%-*}"
  # strip leading zeros for arithmetic, default 0
  n=$((10#$num))
  if [ "$n" -gt "$max" ]; then
    max="$n"
  fi
done

printf '%04d\n' "$((max + 1))"
