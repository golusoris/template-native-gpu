#!/usr/bin/env bash
#
# generate.sh — regenerate the PROJECT FFmpeg patch stack from files/.
#
# Copyright 2026 The PROJECT Authors. BSD-2-Clause-Patent for the patches
# authored here; the linked FFmpeg binary's distribution is governed by FFmpeg's
# LGPL/GPL.
#
# Pattern: check out a pristine FFmpeg base in an isolated git worktree, drop in
# the canonical filter sources from files/, wire each filter's registration
# hunks as its own commit, and `git format-patch` the whole range. The
# cumulative stack is the artifact; files/ is the source of truth.
#
# TEMPLATE: this seed wires ONE filter ("project"). Add filter names to the
# `for filter in ...` loop and a matching `files/vf_<name>_vulkan.c` +
# `.commit-msg-<name>.txt` to grow the stack.
#
# Usage:
#   FFMPEG_REPO=/path/to/ffmpeg BASE_TAG=n8.1.1 ./generate.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FFMPEG_REPO="${FFMPEG_REPO:-$HOME/dev/ffmpeg}"
BASE_TAG="${BASE_TAG:-n8.1.1}"
WORKTREE="${WORKTREE:-/tmp/project-ffmpeg-gen}"
FILES_DIR="$HERE/files"

git -C "$FFMPEG_REPO" worktree remove --force "$WORKTREE" 2>/dev/null || true
git -C "$FFMPEG_REPO" worktree add --detach "$WORKTREE" "$BASE_TAG"

# One commit per filter, in stack order, so format-patch yields 0001, 0002, ...
filters=(project)
for filter in "${filters[@]}"; do
  cp "$FILES_DIR/vf_${filter}_vulkan.c" "$WORKTREE/libavfilter/"
  python3 - "$WORKTREE" "$filter" <<'PY'
import sys, pathlib
root, which = pathlib.Path(sys.argv[1]), sys.argv[2]

def ins_before(path, anchor, line):
    p = root / path; t = p.read_text()
    assert anchor in t, f"anchor missing in {path}: {anchor!r}"
    assert line.strip() not in t, f"already present in {path}: {line!r}"
    p.write_text(t.replace(anchor, line + anchor, 1))

def ins_after(path, anchor, line):
    p = root / path; t = p.read_text()
    assert anchor in t, f"anchor missing in {path}: {anchor!r}"
    assert line.strip() not in t, f"already present in {path}: {line!r}"
    p.write_text(t.replace(anchor, anchor + line, 1))

# libproject wiring: the filter depends only on FFmpeg-KNOWN components (vulkan
# spirv_library) — `libproject` is NOT a known config name, so it must NOT
# appear in _deps (an unknown dep silently disables the filter). The extra lib
# is gated by `enabled <filter> && require_pkg_config libproject ...`, which
# adds its cflags/libs and hard-errors if it is missing.
REQ = ('enabled %s_filter && require_pkg_config libproject '
       '"libproject >= 0.1.0" project/interop.h proj_blob_pack\n')

if which == 'project':
    ins_before("libavfilter/allfilters.c",
               "extern const FFFilter ff_vf_perms;\n",
               "extern const FFFilter ff_vf_project_vulkan;\n")
    ins_before("libavfilter/Makefile",
               "OBJS-$(CONFIG_PERMS_FILTER)                  += f_perms.o\n",
               "OBJS-$(CONFIG_PROJECT_VULKAN_FILTER)         += vf_project_vulkan.o vulkan.o vulkan_filter.o\n")
    ins_after("configure",
              'overlay_vulkan_filter_deps="vulkan spirv_library"\n',
              'project_vulkan_filter_deps="vulkan spirv_library"\n')
    ins_after("configure",
              'project_vulkan_filter_deps="vulkan spirv_library"\n',
              REQ % "project_vulkan")
else:
    sys.exit("unknown filter: " + which)
print(f"registration applied: {which}")
PY
  git -C "$WORKTREE" add -A
  git -C "$WORKTREE" \
    -c user.name="PROJECT bot" -c user.email="bot@example.com" \
    commit -q -F "$HERE/.commit-msg-${filter}.txt"
done

# Clean stale patches, regenerate the whole range.
rm -f "$HERE"/0*.patch
git -C "$WORKTREE" format-patch --zero-commit --start-number=1 \
  -o "$HERE" "$BASE_TAG..HEAD"

# Normalize auto-generated filenames to the series.txt names.
mv "$HERE"/0001-*.patch "$HERE/0001-add-vf_project_vulkan.patch" 2>/dev/null || true

git -C "$FFMPEG_REPO" worktree remove --force "$WORKTREE"
echo "patch(es) regenerated in $HERE:"
ls "$HERE"/0*.patch
