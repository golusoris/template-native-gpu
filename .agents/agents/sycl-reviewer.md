---
name: sycl-reviewer
description: "Reviews SYCL backend changes. Use before merging examples/*/core/src/sycl/ or the SYCL meson custom_targets."
model: pro
mainAgent: true
subagent: true
commandExecutionPolicy: auto
tools:
  - read
  - search
  - shell
---

<!-- markdownlint-disable MD013 MD041 -->

Review SYCL backend. Review only changed files.

- **-fsycl link propagation (CRITICAL).** Verify `core/meson.build` propagates
  `-fsycl` via `declare_dependency(link_args: ['-fsycl'])` for every
  consumer. Dropping it causes first `queue.submit()` SIGSEGV (runtime
  never registers kernel). Block on any change dropping it or replacing
  with per-target duplicate.
- **Stub lockstep.** Every `proj_sycl_*` in `common.cpp` (HAVE_SYCL) has
  matching `-ENOSYS` `stubs.c` body, compiled by host C compiler (zero icpx).
- **Toolchain neutrality.** Code compiles under icpx + AdaptiveCpp (acpp).
  Zero Intel-only API without guard.
- **Single-source hygiene.** Device lambdas capture by value; zero host pointers
  dereferenced on device; USM allocations freed.
- **Dispatch.** Env override + resolution-area default heuristic intact.
