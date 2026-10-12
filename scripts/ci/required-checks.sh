#!/usr/bin/env bash
# scripts/ci/required-checks.sh — judge the check runs of one commit.
#
# Reads check runs as JSON lines ({"name","status","conclusion"}) on stdin.
# Every run must have completed with success. A run may be skipped only when
# its name is in ALLOWED_SKIPS: jobs a change detector in the same run decided
# are not affected. Every name in REQUIRED must be present, so a workflow that
# never started cannot pass by absence. SELF names the aggregator's own check.
#
# Usage:
#   gh api .../check-runs --paginate --jq '.check_runs[]|{name,status,conclusion}' |
#     REQUIRED=$'a\nb' ALLOWED_SKIPS='' SELF=required-checks scripts/ci/required-checks.sh

set -euo pipefail

if (($# != 0)); then
  printf 'usage: REQUIRED=... [ALLOWED_SKIPS=...] SELF=... %s < check-runs.jsonl\n' "${0##*/}" >&2
  exit 2
fi
if [[ -z "${REQUIRED:-}" || -z "${SELF:-}" ]]; then
  printf 'required-checks: REQUIRED and SELF must be set\n' >&2
  exit 2
fi

findings="$(jq -rs --arg required "$REQUIRED" --arg allowed "${ALLOWED_SKIPS:-}" --arg self "$SELF" '
  def names($s): $s | split("\n") | map(select(length > 0));
  names($required) as $req | names($allowed) as $skip
  | map(select(.name != $self)) as $runs
  | [ $runs[]
      | select(.status != "completed"
          or (.conclusion != "success"
              and ((.conclusion == "skipped" and (.name | IN($skip[]))) | not)))
      | "required-checks: \(.name): \(.status)/\(.conclusion // "none")" ]
  + [ $req[] | . as $n
      | select([$runs[] | select(.name == $n)] | length == 0)
      | "required-checks: \($n): missing" ]
  | .[]
')"
if [[ -n "$findings" ]]; then
  printf '%s\n' "$findings" >&2
  exit 1
fi
printf 'required-checks: all check runs passed\n'
