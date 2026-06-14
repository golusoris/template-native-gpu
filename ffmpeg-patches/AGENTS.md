# ffmpeg-patches — agent guide

The patch stack is **generated**, not hand-edited. `files/` is the source of
truth; `*.patch` are artifacts of `generate.sh`.

Rules:

- Edit a filter in `files/vf_<name>_vulkan.c`, then rerun `./generate.sh` and
  commit BOTH the source and the regenerated patch in one change.
- The stack is **cumulative**. Validate with a full series replay
  (`test/build-and-run.sh`), never per-patch `git apply --check`.
- Each filter links `libproject` via `require_pkg_config` (the idiomatic FFmpeg
  pattern). `libproject` must NOT appear in `*_filter_deps` — an unknown dep
  silently disables the filter. Gate it via the `enabled <filter> &&
  require_pkg_config` line instead.
- New filter source files carry FFmpeg's **LGPL-2.1** header (they become part
  of FFmpeg when applied), not the project's BSD-2-Clause-Patent header.
- Keep the GLSL in the filter and the standalone reference shader
  (`libproject/shaders/`) in lockstep.
