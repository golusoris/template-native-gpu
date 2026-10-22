---
commandExecutionPolicy: auto
description: Reviews meson build wiring changes. Use before merging meson.build / meson_options.txt anywhere in the tree.
mainAgent: true
name: meson-reviewer
subagent: true
tools:
  - read
  - search
  - execute
---

<!-- markdownlint-disable MD013 MD041 -->

Review meson build changes. Review only changed files; verify via clean configure.

- **Default-off backends.** Every GPU backend stays OFF/`auto` by default ->
  tree configures + compiles on stock runner with no GPU SDK. Run
  `meson setup /tmp/_check` (same for `examples/full-gpu-matrix/core`) to
  confirm; report any hard `error()` reachable with all backends disabled.
- **Stub TU on else branch.** Disabled backend MUST add `stubs.c` so
  public symbols emitted.
- **custom_target outputs.** bin2c/xxd/metallib/glslang outputs fold into
  library via `sources:`/`objects:`/`dependencies:`; zero dangling targets.
- **-fsycl link arg.** Present in SYCL `declare_dependency(link_args=...)`.
- **extract_all_objects.** Per-arch static libs (if added) fold in via
  `extract_all_objects()`, not direct linking breaking LTO.
