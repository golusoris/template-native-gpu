# ffmpeg-patches — agent guide

Patch stack = **generated**, zero hand-edits. `files/` = source of
truth; `*.patch` = artifacts of `generate.sh`.

Rules:

- Edit filter in `files/vf_<name>_vulkan.c`, rerun `./generate.sh`,
  commit BOTH source and regenerated patch in one change.
- Stack = **cumulative**. Validate with full series replay
  (`test/build-and-run.sh`), never per-patch `git apply --check`.
- Each filter links `libproject` via `require_pkg_config` (idiomatic FFmpeg
  pattern). `libproject` must NOT appear in `*_filter_deps` — unknown dep
  silently disables filter. Gate via `enabled <filter> && require_pkg_config`
  line instead.
- New filter source files carry FFmpeg **LGPL-2.1** header (part of FFmpeg
  when applied), not project EUPL-1.2 header.
- Keep GLSL in filter and standalone reference shader (`libproject/shaders/`)
  in lockstep.
