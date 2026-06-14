#!/usr/bin/env bash
# Stop — end-of-turn reminder. Never blocks.
set -euo pipefail

echo "Reminder: before pushing, run 'pre-commit run --all-files' and 'meson test'. Add a changelog.d/ fragment for user-facing changes." >&2
exit 0
