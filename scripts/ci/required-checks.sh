#!/usr/bin/env bash
# scripts/ci/required-checks.sh — judge the check runs of one commit.
#
# Reads check runs as JSON lines ({"name","status","conclusion","app","summary"}) on stdin.
# Every run must have completed with success. A run may be skipped only when
# its name is in ALLOWED_SKIPS: jobs a change detector in the same run decided
# are not affected. Every name in REQUIRED must be present, so a workflow that
# never started cannot pass by absence. SELF names the aggregator's own check.
# RELEASE_HEAD_SKIPS: release-please--*, HEAD_REPO=BASE_REPO (nonempty), Bot author; off on push.
# BUDGET_SKIP_NAME/_APP/_TEXT (all nonempty or off): that run's skip passes only when its summary matches the regex.
#
# Usage:
#   gh api .../check-runs --paginate --jq '.check_runs[]|{name,status,conclusion,app:.app.slug,summary:.output.summary}' |
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

release_head_skips=''
if [[ "${HEAD_REF:-}" == release-please--* && -n "${HEAD_REPO:-}" && "${HEAD_REPO:-}" == "${BASE_REPO:-}" && "${HEAD_AUTHOR_TYPE:-}" == Bot ]]; then
  release_head_skips="${RELEASE_HEAD_SKIPS:-}"
fi

budget_on=''
if [[ -n "${BUDGET_SKIP_NAME:-}" && -n "${BUDGET_SKIP_APP:-}" && -n "${BUDGET_SKIP_TEXT:-}" ]]; then
  budget_on=1
fi

findings="$(jq -rs --arg required "$REQUIRED" --arg allowed "${ALLOWED_SKIPS:-}" \
  --arg release_skips "$release_head_skips" --arg self "$SELF" --arg budget_on "$budget_on" \
  --arg budget_name "${BUDGET_SKIP_NAME:-}" --arg budget_app "${BUDGET_SKIP_APP:-}" \
  --arg budget_text "${BUDGET_SKIP_TEXT:-}" '
  def names($s): $s | split("\n") | map(select(length > 0));
  def budget_skip: $budget_on == "1" and .name == $budget_name and .app == $budget_app
    and ((.summary // "") | test($budget_text));
  names($required) as $req | (names($allowed) + names($release_skips)) as $skip
  | map(select(.name != $self)) as $runs
  | [ $runs[]
      | select(.status != "completed"
          or (.conclusion != "success"
              and ((.conclusion == "skipped" and ((.name | IN($skip[])) or budget_skip)) | not)))
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
