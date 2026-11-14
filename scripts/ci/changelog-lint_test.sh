#!/usr/bin/env bash
# Planted release-please output keeps changelog lint allowances bounded and required.
#   usage: bash scripts/ci/changelog-lint_test.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
mkdir -p "$REPO_ROOT/.cache"
WORK="$(mktemp -d "$REPO_ROOT/.cache/changelog-lint.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

cat >"$WORK/entry.md" <<'MARKDOWN'
## [9.9.9](https://github.com/OWNER/REPO/compare/v9.9.8...v9.9.9) (2026-01-01)


### Fixed

* **scope:** preserve generated release notes ([#1](https://github.com/OWNER/REPO/issues/1)) ([0000000](https://github.com/OWNER/REPO/commit/0000000000000000000000000000000000000000))
* **scope:** retain complete commit references ([#1](https://github.com/OWNER/REPO/issues/1)) ([0000000](https://github.com/OWNER/REPO/commit/0000000000000000000000000000000000000000))


### Security

* **scope:** preserve generated security notes ([#1](https://github.com/OWNER/REPO/issues/1)) ([0000000](https://github.com/OWNER/REPO/commit/0000000000000000000000000000000000000000))

MARKDOWN

python3 - "$REPO_ROOT/CHANGELOG.md" "$WORK" <<'PY'
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()
work = Path(sys.argv[2])
entry = (work / "entry.md").read_text()
lines = source.splitlines(keepends=True)
for index, line in enumerate(lines):
    if re.match(r"^###? v?[0-9[]", line):
        rendered = "".join(lines[:index]) + entry + "".join(lines[index:])
        break
else:
    raise SystemExit("FAIL render: release-please insertion heading missing")

legacy = rendered.replace("* Initial template scaffold", "- Initial template scaffold")
without_config = "".join(
    line for line in legacy.splitlines(keepends=True)
    if "markdownlint-configure-file" not in line
)
(work / "rendered.md").write_text(rendered)
(work / "without-fix.md").write_text(without_config)
(work / "third-blank.md").write_text(rendered.replace(entry, entry.replace("\n\n\n", "\n\n\n\n", 1), 1))
(work / "dash-bullet.md").write_text(legacy)
PY

lint() {
  if output="$(pre-commit run markdownlint-cli2 --files "$WORK/$1.md" 2>&1)"; then
    lint_rc=0
  else
    lint_rc="$?"
  fi
  if [[ "$output" == *"(no files to check)"* ]]; then
    printf 'FAIL %s: hook skipped rendered file\n%s\n' "$1" "$output" >&2
    exit 1
  fi
}

expect_refusal() {
  local name="$1" index needle
  shift
  local -a needles=("$@")
  lint "$name"
  if [[ "$lint_rc" == 0 ]]; then
    printf 'FAIL %s: accepted\n%s\n' "$name" "$output" >&2
    exit 1
  fi
  for ((index = 0; index < "${#needles[@]}"; index++)); do
    needle="${needles[$index]}"
    if [[ "$output" != *"$needle"* ]]; then
      printf 'FAIL %s: refused without "%s"\n%s\n' "$name" "$needle" "$output" >&2
      exit 1
    fi
  done
  printf 'PASS %s: refused (%s)\n' "$name" "${needles[*]}"
}

lint rendered
if [[ "$lint_rc" != 0 ]]; then
  printf 'FAIL rendered: refused\n%s\n' "$output" >&2
  exit 1
fi
printf 'PASS rendered: accepted\n'

expect_refusal without-fix MD012 MD013 MD004
expect_refusal third-blank MD012
expect_refusal dash-bullet MD004
