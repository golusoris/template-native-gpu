---
commandExecutionPolicy: auto
description: Reviews Metal backend changes. Use before merging examples/*/core/src/metal/ or the Metal meson custom_targets.
mainAgent: true
model: sonnet
name: metal-reviewer
subagent: true
tools:
  - Read
  - Grep
  - Glob
  - Bash
---

<!-- markdownlint-disable MD013 MD041 -->

Review Metal (Apple Silicon) backend. Review only changed files.

- **Stub lockstep.** `proj_metal_*` in `common.m` (HAVE_METAL) matches `stubs.c`
  (-ENOSYS). Darwin build compiles `common.m`; non-darwin links stub.
- **metallib pipeline.** New `.metal` kernels go through `xcrun metal -c` -> `.air`
  -> `xcrun metallib` -> `default.metallib`, embedded via
  `-Wl,-sectcreate,__TEXT,__metallib,…`. Runtime loads from section, not file path.
- **ARC.** `.m`/`.mm` TUs use `-fobjc-arc`; zero manual retain/release; zero leaks
  across autorelease boundary.
- **Dispatch.** `dispatch_strategy.c` stays pure C; env override intact.
