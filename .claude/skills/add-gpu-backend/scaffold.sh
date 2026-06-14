#!/usr/bin/env bash
# scaffold.sh — generate a new GPU backend skeleton under
# examples/full-gpu-matrix/core/src/<name>/ from the templates next to this file.
#
# Usage: scaffold.sh <name> <kernel-ext>
#   <name>        lowercase backend id (e.g. oneapi)   -> NAME=ONEAPI, Cap=Oneapi
#   <kernel-ext>  kernel source extension (cu|hip|cpp|metal|comp)
set -euo pipefail

name="${1:?usage: scaffold.sh <name> <kernel-ext>}"
ext="${2:?usage: scaffold.sh <name> <kernel-ext>}"

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
DEST="$ROOT/examples/full-gpu-matrix/core/src/$name"
TPL="$HERE/templates"

NAME_UC="$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')"
NAME_CAP="$(printf '%s' "${name:0:1}" | tr '[:lower:]' '[:upper:]')${name:1}"

mkdir -p "$DEST"

render() {
    sed -e "s/{{name}}/$name/g" \
        -e "s/{{NAME}}/$NAME_UC/g" \
        -e "s/{{Name}}/$NAME_CAP/g" \
        "$1"
}

render "$TPL/common.h.template"          > "$DEST/common.h"
render "$TPL/common.c.template"          > "$DEST/common.c"
render "$TPL/stubs.c.template"           > "$DEST/stubs.c"
render "$TPL/dispatch_strategy.h.template" > "$DEST/dispatch_strategy.h"
render "$TPL/dispatch_strategy.c.template" > "$DEST/dispatch_strategy.c"
render "$TPL/AGENTS.md.template"         > "$DEST/AGENTS.md"

cat > "$DEST/scale_kernel.$ext" <<EOF
/* scale_kernel.$ext — trivial illustrative $name kernel. Replace with real compute. */
EOF

echo "scaffolded: $DEST"
echo "next: wire enable_$name into core/meson_options.txt + core/meson.build (see SKILL.md)."
