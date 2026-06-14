#!/usr/bin/env bash
# SessionStart — print a short orientation banner. Never blocks.
set -euo pipefail

cat <<'EOF'
PROJECT — native (C/C++) + GPU + FFmpeg-filter template.

Build:   meson setup build && meson compile -C build && meson test -C build
GPU ex:  meson setup build-gpu examples/full-gpu-matrix/core && meson test -C build-gpu
Gate:    pre-commit run --all-files   (format + lint + gitleaks)

Read CLAUDE.md + AGENTS.md. Interop ABI is APPEND-ONLY (libproject/AGENTS.md).
Every GPU backend keeps an -ENOSYS stub in lockstep with its real surface.
EOF
exit 0
