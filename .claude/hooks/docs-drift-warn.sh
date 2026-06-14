#!/usr/bin/env bash
# PostToolUse(Edit|Write) — warn (never block) when a change likely needs a
# companion doc/changelog/ABI update. Stderr is shown to the model; exit 0.
set -euo pipefail

f="$(python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"
[ -z "$f" ] && exit 0

warn() { echo "DOCS-DRIFT: $1" >&2; }

case "$f" in
    */libproject/include/project/interop.h)
        warn "interop.h changed — bump PROJ_ABI_MINOR, update _Static_assert size locks + interop_test.c, add a changelog.d/changed/ fragment and an ADR." ;;
    */src/*/dispatch_strategy.*|*/src/*/common.*)
        warn "GPU backend changed — keep the matching stubs.c in -ENOSYS lockstep and note cross-backend parity." ;;
    */meson.build|*/meson_options.txt)
        warn "build wiring changed — re-run a clean meson setup to confirm it still configures with every backend disabled." ;;
esac
exit 0
