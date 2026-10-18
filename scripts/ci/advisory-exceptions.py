#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
"""Check the advisory exception list (osv-scanner.toml) for expired entries.

Each [[IgnoredVulns]] entry needs id, ignoreUntil and a reason that names its
category ("Category A".."Category D"). The check fails on a missing field, an
unknown category, an expiry in the past, or an expiry further out than the
category interval allows (B 3 days, C 10 days, A and D 120 days).

Usage:
    advisory-exceptions.py [FILE]   # default: osv-scanner.toml at the repo root
"""

from __future__ import annotations

import datetime as dt
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INTERVAL_DAYS = {"A": 120, "B": 3, "C": 10, "D": 120}
CATEGORY = re.compile(r"\bCategory ([A-D])\b")
MAX_ENTRIES = 256


def entry_errors(entry: object, today: dt.date) -> list[str]:
    if not isinstance(entry, dict):
        return ["entry is not a table"]
    vid = entry.get("id")
    until = entry.get("ignoreUntil")
    reason = entry.get("reason")
    if not isinstance(vid, str) or not vid:
        return ["entry without id"]
    if not isinstance(until, (dt.datetime, dt.date)):
        return [f"{vid}: ignoreUntil missing or not a TOML date"]
    if not isinstance(reason, str):
        return [f"{vid}: reason missing"]
    match = CATEGORY.search(reason)
    if match is None:
        return [f"{vid}: reason names no category A..D"]
    day = until.date() if isinstance(until, dt.datetime) else until
    if day <= today:
        return [f"{vid}: expired on {day.isoformat()}"]
    limit = INTERVAL_DAYS[match.group(1)]
    if (day - today).days > limit:
        return [f"{vid}: expiry {day.isoformat()} beyond category {match.group(1)} ({limit} days)"]
    return []


def main(argv: list[str]) -> int:
    if len(argv) > 2:
        print(__doc__, file=sys.stderr)
        return 2
    path = Path(argv[1]) if len(argv) == 2 else ROOT / "osv-scanner.toml"
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError) as err:
        print(f"advisory-exceptions: {path}: {err}", file=sys.stderr)
        return 1
    entries = data.get("IgnoredVulns", [])
    if not isinstance(entries, list) or len(entries) > MAX_ENTRIES:
        print(f"advisory-exceptions: {path}: IgnoredVulns is not a list of at most {MAX_ENTRIES}", file=sys.stderr)
        return 1
    today = dt.datetime.now(dt.timezone.utc).date()
    errors = [err for entry in entries for err in entry_errors(entry, today)]
    for err in errors:
        print(f"advisory-exceptions: {path}: {err}", file=sys.stderr)
    if errors:
        return 1
    print(f"advisory-exceptions: {len(entries)} entries hold")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
